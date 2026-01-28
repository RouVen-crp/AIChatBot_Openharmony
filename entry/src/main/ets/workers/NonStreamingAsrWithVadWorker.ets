/*
 * Copyright (c) 2025 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import worker, { ErrorEvent, MessageEvents, ThreadWorkerGlobalScope } from '@ohos.worker';
import {
  OfflineRecognizer,
  OfflineRecognizerConfig,
  OfflineStream,
  OnlineRecognizerResult,
  readWaveFromBinary,
  SileroVadConfig,
  SpeechSegment,
  Vad,
  VadConfig,
} from 'sherpa_onnx';
import fileIo from '@ohos.file.fs';
import { getOfflineModelConfig } from './ModelConfig';
import Logger from '../utils/Logger';

const TAG = 'NonStreamingAsrWorker';
const workerPort: ThreadWorkerGlobalScope = worker.workerPort;

let recognizer: OfflineRecognizer;
let vad: Vad;
let vadMic: Vad;

function initVad(context: Context): Vad {
  let mgr = context.resourceManager;
  const config: VadConfig = new VadConfig(
    new SileroVadConfig(
      'silero_vad.onnx',
      0.5,
      0.25,
      0.5,
      512,
    ),
    16000,
    true,
    1,
  );

  const bufferSizeInSeconds = 60;
  return new Vad(config, bufferSizeInSeconds, mgr);
}

function initNonStreamingAsr(context: Context): OfflineRecognizer {
  let mgr = context.resourceManager;
  const config: OfflineRecognizerConfig = new OfflineRecognizerConfig();
  const type = 23;
  config.modelConfig = getOfflineModelConfig(type);
  config.modelConfig.debug = true;
  config.ruleFsts = '';
  return new OfflineRecognizer(config, mgr);
}

interface Wave {
  samples: Float32Array;
  sampleRate: number;
}

function decodeFile(filename: string): string {
  vad.reset();

  const fp = fileIo.openSync(filename);
  const stat = fileIo.statSync(fp.fd);
  const arrayBuffer = new ArrayBuffer(stat.size);
  fileIo.readSync(fp.fd, arrayBuffer);
  const data: Uint8Array = new Uint8Array(arrayBuffer);

  const wave: Wave = readWaveFromBinary(data);
  if (wave.sampleRate != 16000) {
    return `the sample rate in ${filename} is not 16000Hz. Given: ${wave.sampleRate}Hz.`;
  }

  Logger.info(TAG, `sample rate: ${wave.sampleRate}, sample length: ${wave.samples.length}`);
  const resultList: string[] = [];

  const windowSize: number = vad.config.sileroVad.windowSize;
  for (let i = 0; i < wave.samples.length; i += windowSize) {
    const thisWindow: Float32Array = wave.samples.subarray(i, i + windowSize);
    vad.acceptWaveform(thisWindow);
    if (i + windowSize >= wave.samples.length) {
      vad.flush();
    }

    while (!vad.isEmpty()) {
      const segment: SpeechSegment = vad.front();
      const _startTime: number = (segment.start / wave.sampleRate);
      const _endTime: number = _startTime + segment.samples.length / wave.sampleRate;

      if (_endTime - _startTime < 0.2) {
        vad.pop();
        continue;
      }

      const startTime: string = _startTime.toFixed(2);
      const endTime: string = _endTime.toFixed(2);
      const progress: number = (segment.start + segment.samples.length) / wave.samples.length * 100;

      workerPort.postMessage({ 'msgType': 'non-streaming-asr-vad-decode-progress', progress });

      const stream: OfflineStream = recognizer.createStream();
      stream.acceptWaveform({ samples: segment.samples, sampleRate: wave.sampleRate });
      recognizer.decode(stream);
      const result: OnlineRecognizerResult = recognizer.getResult(stream);

      const text: string = `${startTime} -- ${endTime} ${result.text}`;
      resultList.push(text);
      Logger.info(TAG, `partial result: ${text}`);

      workerPort.postMessage({ 'msgType': 'non-streaming-asr-vad-decode-partial', text });
      vad.pop();
    }
  }

  return resultList.join('\n\n');
}

function decodeMic(samples: Float32Array) {
  const resultList: string[] = [];

  const windowSize: number = vad.config.sileroVad.windowSize;
  for (let i = 0; i < samples.length; i += windowSize) {
    const thisWindow: Float32Array = samples.subarray(i, i + windowSize);
    vad.acceptWaveform(thisWindow);
    if (i + windowSize >= samples.length) {
      vad.flush();
    }
    while (!vad.isEmpty()) {
      const segment: SpeechSegment = vad.front();
      const _startTime: number = (segment.start / 16000);
      const _endTime: number = _startTime + segment.samples.length / 16000;

      if (_endTime - _startTime < 0.2) {
        vad.pop();
        continue;
      }

      const startTime: string = _startTime.toFixed(2);
      const endTime: string = _endTime.toFixed(2);

      const stream: OfflineStream = recognizer.createStream();
      stream.acceptWaveform({ samples: segment.samples, sampleRate: 16000 });
      recognizer.decode(stream);
      const result: OnlineRecognizerResult = recognizer.getResult(stream);

      const text: string = `${result.text}`;
      resultList.push(text);
      Logger.info(TAG, `partial result: ${text}`);

      workerPort.postMessage({ 'msgType': 'non-streaming-asr-vad-mic-partial', text });

      vad.pop();
    }
  }

  return resultList.join('\n\n');
}

workerPort.onmessage = (e: MessageEvents) => {
  const msgType = e.data['msgType'] as string;
  Logger.info(TAG, `msg-type: ${msgType}`);
  if (msgType == 'init-vad' && !vad) {
    const context = e.data['context'] as Context;
    vad = initVad(context);
    Logger.info(TAG, 'init vad done.');
    workerPort.postMessage({ 'msgType': 'init-vad-done' });
  }

  if (msgType == 'init-vad-mic' && !vadMic) {
    const context = e.data['context'] as Context;
    vadMic = initVad(context);
    Logger.info(TAG, 'init vad mic done');
    workerPort.postMessage({ 'msgType': 'init-vad-mic-done' });
  }

  if (msgType == 'init-non-streaming-asr' && !recognizer) {
    const context = e.data['context'] as Context;
    recognizer = initNonStreamingAsr(context);
    Logger.info(TAG, 'init non streaming ASR done');
    workerPort.postMessage({ 'msgType': 'init-non-streaming-asr-done' });
  }

  if (msgType == 'non-streaming-asr-vad-decode') {
    const filename = e.data['filename'] as string;
    Logger.info(TAG, `decode ${filename}`);
    try {
      const text = decodeFile(filename);
      workerPort.postMessage({ msgType: 'non-streaming-asr-vad-decode-done', text });
    } catch (e) {
      workerPort.postMessage({ msgType: 'non-streaming-asr-vad-decode-error', text: `Failed to decode ${filename}` });
    }
    workerPort.postMessage({ msgType: 'non-streaming-asr-vad-decode-progress', progress: 100 });
  }

  if (msgType == 'non-streaming-asr-vad-mic') {
    const samples: Float32Array = e.data['samples'] as Float32Array;
    vadMic.reset();
    try {
      const text = decodeMic(samples);
      workerPort.postMessage({ msgType: 'non-streaming-asr-vad-mic-done', text });
    } catch (e) {
      workerPort.postMessage({ msgType: 'non-streaming-asr-vad-mic-error', text: `Failed to decode` });
    }
  }
}

workerPort.onmessageerror = (e: MessageEvents) => {
}
workerPort.onerror = (e: ErrorEvent) => {
}
