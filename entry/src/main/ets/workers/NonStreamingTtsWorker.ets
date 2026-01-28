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

import worker, { ThreadWorkerGlobalScope, MessageEvents, ErrorEvent } from '@ohos.worker';
import fs from '@ohos.file.fs';
import { OfflineTtsConfig, OfflineTts, listRawfileDir, TtsInput, TtsOutput } from 'sherpa_onnx';
import buffer from '@ohos.buffer';
import Logger from '../utils/Logger';

const TAG = 'NonStreamingTtsWorker';
const workerPort: ThreadWorkerGlobalScope = worker.workerPort;

let tts: OfflineTts;
let cancelled = false;

function mkdir(context: Context, parts: string[]) {
  const path = parts.join('/');
  if (fs.accessSync(path)) {
    return;
  }

  const sandboxPath: string = context.getApplicationContext().filesDir;
  let d = sandboxPath;
  for (const p of parts) {
    d = d + '/' + p;

    if (fs.accessSync(d)) {
      continue;
    }
    fs.mkdirSync(d);
  }
}

function copyRawFileDirToSandbox(context: Context, srcDir: string) {
  let mgr = context.resourceManager;
  const allFiles: string[] = listRawfileDir(mgr, srcDir);
  for (const src of allFiles) {
    const parts: string[] = src.split('/');
    if (parts.length != 1) {
      mkdir(context, parts.slice(0, -1));
    }

    copyRawFileToSandbox(context, src, src);
  }
}

function copyRawFileToSandbox(context: Context, src: string, dst: string) {
  let uint8Array: ArrayBuffer = context.resourceManager.getRawFileContentSync(src);
  let sanboxPath: string = context.getApplicationContext().filesDir;
  let filepath = sanboxPath + '/' + dst;

  if (fs.accessSync(filepath)) {
    let stat = fs.statSync(filepath);
    if (stat.size == uint8Array.byteLength) {
      return;
    }
  }
  const fp = fs.openSync(filepath, fs.OpenMode.WRITE_ONLY | fs.OpenMode.CREATE | fs.OpenMode.TRUNC);
  if (uint8Array) {
    fs.writeSync(fp.fd, buffer.from(uint8Array).buffer)
  }
  fs.close(fp.fd);
}

function initTts(context: Context): OfflineTts {
  let modelDir = '';
  let modelName = '';
  let acousticModelName = '';
  let vocoder = '';
  let voices = '';
  let ruleFsts = '';
  let ruleFars = '';
  let lexicon = '';
  let dataDir = '';
  let dictDir = '';

  modelDir = 'vits-melo-tts-zh_en';
  modelName = 'model.onnx';
  lexicon = 'lexicon.txt';
  dictDir = 'dict';
  ruleFsts = 'date.fst,phone.fst,number.fst';

  if (modelName == '' && acousticModelName == '' && vocoder == '') {
    throw new Error('You are supported to select a model by changing the code before you run the app');
  }

  if (modelName != '' && acousticModelName != '') {
    throw new Error('Please select either VITS or Matcha, not both');
  }

  if (acousticModelName != '' && vocoder == '') {
    throw new Error('Please provider vocoder for matcha tts models');
  }

  if (modelName != '') {
    modelName = modelDir + '/' + modelName;
  }

  if (acousticModelName != '') {
    acousticModelName = modelDir + '/' + acousticModelName;
  }

  if (voices != '') {
    voices = modelDir + '/' + voices;
  }

  if (ruleFsts != '') {
    let fsts = ruleFsts.split(',');
    let tmp: string[] = [];
    for (const f of fsts) {
      tmp.push(modelDir + '/' + f);
    }
    ruleFsts = tmp.join(',');
  }

  if (ruleFars != '') {
    let fars = ruleFars.split(',');
    let tmp: string[] = [];
    for (const f of fars) {
      tmp.push(modelDir + '/' + f);
    }
    ruleFars = tmp.join(',');
  }

  if (lexicon.includes(',')) {
    let v = lexicon.split(',');
    let tmp: string[] = [];
    for (const f of v) {
      tmp.push(modelDir + '/' + f);
    }
    lexicon = tmp.join(',');
  } else if (lexicon != '') {
    lexicon = modelDir + '/' + lexicon;
  }

  if (dataDir != '') {
    copyRawFileDirToSandbox(context, modelDir + '/' + dataDir);
    let sandboxPath: string = context.getApplicationContext().filesDir;
    dataDir = sandboxPath + '/' + modelDir + '/' + dataDir;
  }

  if (dictDir != '') {
    copyRawFileDirToSandbox(context, modelDir + '/' + dictDir);
    let sandboxPath: string = context.getApplicationContext().filesDir;
    dictDir = sandboxPath + '/' + modelDir + '/' + dictDir;
  }

  const tokens = modelDir + '/tokens.txt';
  const config: OfflineTtsConfig = new OfflineTtsConfig();
  if (voices != '') {
    config.model.vits.model = '';
  } else {
    config.model.vits.model = modelName;
  }

  if (voices == '') {
    config.model.vits.lexicon = lexicon;
    config.model.vits.tokens = tokens;
    config.model.vits.dataDir = dataDir;
    config.model.vits.dictDir = dictDir;

    config.model.matcha.acousticModel = acousticModelName;
    config.model.matcha.vocoder = vocoder;
    config.model.matcha.lexicon = lexicon;
    config.model.matcha.tokens = tokens;
    config.model.matcha.dataDir = dataDir;
    config.model.matcha.dictDir = dictDir;
  }

  if (voices != '') {
    config.model.kokoro.model = modelName;
  } else {
    config.model.kokoro.model = '';
  }

  if (voices != '') {
    config.model.kokoro.voices = voices;
    config.model.kokoro.tokens = tokens;
    config.model.kokoro.dataDir = dataDir;
    config.model.kokoro.dictDir = dictDir;
    config.model.kokoro.lexicon = lexicon;
  }

  config.model.numThreads = 2;
  config.model.debug = true;
  config.ruleFsts = ruleFsts;
  config.ruleFars = ruleFars;

  return new OfflineTts(config, context.resourceManager);
}

interface TtsCallbackData {
  samples: Float32Array;
  progress: number;
}

function callback(data: TtsCallbackData): number {
  workerPort.postMessage({
    'msgType': 'tts-generate-partial', samples: Float32Array.from(data.samples), progress: data.progress,
  })
  return cancelled ? 0 : 1;
}

workerPort.onmessage = (e: MessageEvents) => {
  const msgType = e.data['msgType'] as string;
  Logger.info(TAG, `msg-type: ${msgType}`);
  if (msgType == 'init-tts' && !tts) {
    const context = e.data['context'] as Context;
    tts = initTts(context);
    workerPort.postMessage({
      'msgType': 'init-tts-done',
      sampleRate: tts.sampleRate,
      numSpeakers: tts.numSpeakers,
      numThreads: tts.config.model.numThreads,
    })
  }

  if (msgType == 'tts-generate-cancel') {
    cancelled = true;
  }
  if (msgType == 'tts-generate') {
    const text = e.data['text'] as string;
    Logger.info(TAG, `received text: ${text}`);
    const input: TtsInput = new TtsInput();
    input.text = text;
    input.sid = e.data['sid'] as number;
    input.speed = e.data['speed'] as number;
    input.callback = callback;

    cancelled = false;
    if (true) {
      tts.generateAsync(input).then((ttsOutput: TtsOutput) => {
        // Logger.info(TAG, `sampleRate: ${ttsOutput.sampleRate}`);
        workerPort.postMessage({
          'msgType': 'tts-generate-done', samples: Float32Array.from(ttsOutput.samples),
        });
      });
    } else {
    }
  }
}

workerPort.onmessageerror = (e: MessageEvents) => {
};
workerPort.onerror = (e: ErrorEvent) => {
};

