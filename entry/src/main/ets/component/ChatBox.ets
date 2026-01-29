/*
 * Copyright (c) 2025 Hunan OpenValley Digital Industry Development Co., Ltd. & Huawei Device Co., Ltd.
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

import { LvMarkdownIn } from '@luvi/lv-markdown-in';
import { CircularBuffer } from 'sherpa_onnx';
import worker, { MessageEvents, ErrorEvent } from '@ohos.worker';
import audio from '@ohos.multimedia.audio';
import { VoiceSettings } from "../model/setting/VoiceSettings";
import { AppStorageV2, promptAction } from "@kit.ArkUI";
import Logger from "../utils/Logger";
import Constants from "../common/Constants";
import { blockUi } from "../interfaces/blockUi";

const TAG = '[chat_box]';

@ComponentV2
export default struct ChatBox {
  @Consumer('chatScroll') scroll: Scroller = new Scroller();
  @Consumer('isBottom') isBottom: boolean = true;
  @Consumer('isScrolling') isScrolling: boolean = false;
  @Consumer('isWebSearch') isWebSearch: boolean = true;
  @Param @Require chatMessageList: Array<blockUi>;
  // 语音合成
  @Local btnStartEnabled: boolean = false;
  @Local sid: string = '0';
  @Local voiceSettings: VoiceSettings =
    AppStorageV2.connect(VoiceSettings, 'VoiceSettings', () => new VoiceSettings())!;
  @Local playState: audio.AudioState = audio.AudioState.STATE_STOPPED;
  @Local isGenerating: boolean = false;
  // 能否播放
  @Local canPlay: boolean = true;
  @Local initTtsDone: boolean = false;
  @Local ttsGeneratedDone: boolean = true;
  @Local numSpeakers: number = 1;
  @Local numThreads: number = 1;
  @Local initAudioDone: boolean = false;
  private cancelled: boolean = false;
  private sampleRate: number = 0;
  private startTime: number = 0;
  private stopTime: number = 0;
  private inputText: string = '';
  private workerInstance?: worker.ThreadWorker;
  private readonly scriptURL: string = 'entry/ets/workers/NonStreamingTtsWorker.ets';
  private sampleBuffer: CircularBuffer = new CircularBuffer(16000 * 5);
  private finalSamples: Float32Array | null = null;
  private audioRenderer: audio.AudioRenderer | null = null;
  private audioPlayCallback = (buffer: ArrayBuffer) => {
    const numSamples = buffer.byteLength / 2;
    if (this.sampleBuffer.size() >= numSamples) {
      const samples: Float32Array = this.sampleBuffer.get(this.sampleBuffer.head(), numSamples);
      const int16Samples = new Int16Array(buffer);
      for (let i = 0; i < numSamples; ++i) {
        let s = samples[i] * 32767;
        s = s > 32767 ? 32767 : s;
        s = s < -32768 ? -32768 : s;
        int16Samples[i] = s;
      }
      this.sampleBuffer.pop(numSamples);
    } else {
      (new Int16Array(buffer)).fill(0);
      if (this.ttsGeneratedDone) {
        this.audioRenderer?.stop();
        this.btnStartEnabled = true;
      }
    }
  };

  initAudioRenderer() {
    if (this.audioRenderer) {
      Logger.info(TAG, 'Audio renderer has already been created. Skip creating');
      return;
    }
    Logger.info(TAG, 'Initializing audio renderer');
    const audioStreamInfo: audio.AudioStreamInfo = {
      samplingRate: this.sampleRate,
      channels: audio.AudioChannel.CHANNEL_1,
      sampleFormat: audio.AudioSampleFormat.SAMPLE_FORMAT_S16LE,
      encodingType: audio.AudioEncodingType.ENCODING_TYPE_RAW
    };

    const audioRendererInfo: audio.AudioRendererInfo = {
      usage: audio.StreamUsage.STREAM_USAGE_MUSIC,
      rendererFlags: 0
    };

    const audioRendererOptions: audio.AudioRendererOptions = {
      streamInfo: audioStreamInfo,
      rendererInfo: audioRendererInfo
    }

    audio.createAudioRenderer(audioRendererOptions, (err, renderer) => {
      if (!err) {
        Logger.info(TAG, 'audio renderer initialized successfully');
        this.initAudioDone = true;
        if (renderer) {
          this.audioRenderer = renderer;
          this.audioRenderer.on('writeData', this.audioPlayCallback);
          if (this.sampleBuffer.size()) {
            this.audioRenderer.start();
          }
          // 监听状态变化
          this.audioRenderer.on('stateChange', (state: audio.AudioState) => {
            if (state == audio.AudioState.STATE_RUNNING) {
              Logger.info(TAG, 'audio renderer state is: STATE_RUNNING');
              this.playState = audio.AudioState.STATE_RUNNING;
            }
            if (state == audio.AudioState.STATE_STOPPED) {
              Logger.info(TAG, 'audio renderer state is: STATE_STOPPED');
              this.playState = audio.AudioState.STATE_STOPPED;
            }
          });
        } else {
          Logger.info(TAG, `returned audio renderer is ${renderer}`);
        }
      } else {
        Logger.error(TAG,
          `Failed to initialize audio renderer. error message: ${err.message}, error code: ${err.code}`);
      }
    });
  }

  // 播放
  private play() {
    let sid = parseInt(this.sid);
    if (sid.toString() != this.sid) {
      Logger.info(TAG, 'Please input a valid speaker ID');
      return;
    }
    if (this.workerInstance && this.initTtsDone) {
      Logger.info(TAG, 'Generating audio');
      this.cancelled = false;
      this.finalSamples = null;
      this.sampleBuffer.reset();
      this.ttsGeneratedDone = false;

      Logger.info(TAG, `send text to worker: ${this.inputText}`);
      this.startTime = Date.now();
      this.workerInstance?.postMessage({
        msgType: 'tts-generate',
        text: this.inputText,
        sid: sid,
        speed: this.voiceSettings.speed
      });
      this.isGenerating = true;
    } else {
      Logger.info(TAG, 'Failed to initialize tts model');
    }
  }

  // 停止
  private stop() {
    this.ttsGeneratedDone = true;
    this.sampleBuffer.reset();
    this.cancelled = true;
    this.isGenerating = false;

    if (this.workerInstance && this.initTtsDone) {
      this.workerInstance.postMessage({ msgType: 'tts-generate-cancel' });
    }
    this.audioRenderer?.stop();
  }

  // 切换播放/停止
  async switchPlayOrStop() {
    if (this.playState === audio.AudioState.STATE_RUNNING) {
      // 停止
      await this.stop();
      Logger.info(TAG, `switchPlayOrStop, stop audio.`);
    } else {
      // 节流
      if (this.canPlay) {
        // 提示
        promptAction.showToast({ message: $r('app.string.speech_start') });
        // 播放
        await this.play();
        Logger.info(TAG, `switchPlayOrStop, play audio.`);
        this.canPlay = false;
        setTimeout(() => {
          this.canPlay = true;
        }, Constants.THROTTLE_DURATION)
      } else {
        // 提示
        promptAction.showToast({ message: $r('app.string.playing') });
        Logger.info(TAG, `switchPlayOrStop, audio is playing.`);
      }
    }
  }

  async aboutToAppear() {
    this.initAudioRenderer();
    // 延迟初始化 TTS Worker，避免启动时加载失败导致崩溃
    try {
      this.workerInstance = new worker.ThreadWorker(this.scriptURL, { name: 'NonStreaming TTS worker' });
      this.workerInstance.onmessage = (e: MessageEvents) => {
        const msgType = e.data['msgType'] as string;
        Logger.info(TAG, `received msg from worker: ${msgType}`);
        // 初始化成功
        if (msgType == 'init-tts-done') {
          this.sampleRate = e.data['sampleRate'] as number;
          this.numSpeakers = e.data['numSpeakers'] as number;
          this.numThreads = e.data['numThreads'] as number;
          this.initTtsDone = true;
          Logger.info(TAG, `model initialized, numThreads = ${this.numThreads}`);
        }
      // 语音合成
      if (msgType == 'tts-generate-partial') {
        if (this.cancelled) {
          Logger.info(TAG, `${TAG}, msgType: ${msgType}, workerInstance is cancelled.`)
          return;
        }
        const samples: Float32Array = e.data['samples'] as Float32Array;
        this.sampleBuffer.push(samples);
        if (!this.initAudioDone) {
          this.initAudioRenderer();
        }
        Logger.info(TAG,
          `initAudioDone: ${this.initAudioDone}, this.audioRenderer: ${this.audioRenderer}, state = ${this.audioRenderer?.state}`);
        if (this.audioRenderer && this.audioRenderer?.state != audio.AudioState.STATE_RUNNING) {
          this.audioRenderer.start();
        }
      }
      // 语音合成完成
      if (msgType == 'tts-generate-done') {
        this.isGenerating = false;
        const samples: Float32Array = e.data['samples'] as Float32Array;
        this.stopTime = Date.now();
        const audioDuration = samples.length / this.sampleRate;
        const elapsedSeconds = (this.stopTime - this.startTime) / 1000;
        const RTF = elapsedSeconds / audioDuration;
        Logger.info(TAG, `Audio duration: ${audioDuration} s, ` +
          `Elapsed: ${elapsedSeconds} s, ` +
          `RTF = ${elapsedSeconds.toFixed(2)}/ ${audioDuration.toFixed(2)} = ${RTF.toFixed(3)}, ` +
          `Number of threads: ${this.numThreads}`);

        this.finalSamples = samples;
        this.ttsGeneratedDone = true;

        if (this.audioRenderer && this.audioRenderer?.state != audio.AudioState.STATE_RUNNING &&
          this.sampleBuffer.size() == 0) {
          this.sampleBuffer.push(samples);
        }

        if (!this.initAudioDone) {
          this.btnStartEnabled = true;
          Logger.info(TAG, 'Audio renderer is not initialized. Unable to play audio.');
        }
      }
      };
      this.workerInstance.onerror = (e: ErrorEvent) => {
        Logger.error(TAG, `TTS Worker error: ${JSON.stringify(e)}`);
        this.initTtsDone = false;
      };
    } catch (error) {
      Logger.error(TAG, `Failed to create TTS worker: ${JSON.stringify(error)}`);
      this.initTtsDone = false;
      return;
    }
    
    // 延迟初始化 TTS 模型，避免启动时加载失败导致崩溃
    setTimeout(() => {
      try {
        Logger.info(TAG, 'Initializing TTS model ...');
        if (this.workerInstance) {
          this.workerInstance.postMessage({ msgType: 'init-tts', context: getContext() });
        }
      } catch (error) {
        Logger.error(TAG, `Failed to init TTS model: ${JSON.stringify(error)}`);
        this.initTtsDone = false;
      }
    }, 1000);
  }

  build() {
    Scroll(this.scroll) {
      Column({ space: 12 }) {
        ForEach(this.chatMessageList, (item: blockUi, index: number) => {
          if (item.role == "user") {
            Row() {
              Text(item.content)
                .padding(15.5)
                .borderRadius(12)
                .backgroundColor($r('app.color.user_message_background'))
                .copyOption(CopyOptions.LocalDevice)
            }
            .margin({ top: index === 0 ? 0 : 12 })
            .width("100%")
            .alignItems(VerticalAlign.Top)
            .justifyContent(FlexAlign.End)
            .borderRadius(16)
            .padding({ left: 10, right: 10 })
            if(item.imageUris){
              Row(){
                ForEach(item.imageUris,  (image: string, index: number) => {
                  Image(image)
                    .width(200)
                    .height(200)
                    .margin(10)
                })
              }
              .width("100%")
              .justifyContent(FlexAlign.End)
            }
          } else if (item.role == "assistant") {
            Column() {
              Row({ space: 8 }) {
                // 图标
                Image($r("app.media.ai_assist"))
                  .objectFit(ImageFit.Fill)
                  .width(50)
                  .height(50)
                  .borderRadius(4)

                if (item.isReceiveStream) {
                  Row() {
                    LoadingProgress()
                      .width(40)
                      .height(40)
                  } .height(50)
                }

                  if (item.thinkingContent && item.thinkingContent.length > 0) {
                    // 深度思考
                    Row() {
                      Image(item.isExpanded ? $r('app.media.ic_public_right') : $r('app.media.ic_public_down'))
                        .width(20)
                        .height(20)
                        .margin({ left: 8 })
                        .animation({ duration: 100 })
                        .objectFit(ImageFit.Contain)
                        .fillColor($r('sys.color.ohos_id_color_primary'))

                      Text(item.isThinking ? $r('app.string.deep_thinking_on') :
                      $r('app.string.deep_thinking_complete'))
                        .fontSize(14)
                        .margin({ left: 8 })
                    }
                    .padding({ top: 8, bottom: 8 })
                    .onClick(() => {
                      item.isExpanded = !item.isExpanded
                    })
                  }


                Blank()
                  .layoutWeight(1)
              }
              .margin({ left: 16, right: 16 })

              if (item.isExpanded) {
                Text(item.thinkingContent)
                  .width("80%")
                  .padding({ left: 15.5 })
                  .fontSize(14)
                  .fontColor($r('app.color.thinking_content_font'))
                  .borderWidth({ left: 2 })
                  .borderColor('#D9D9D9')
              }

              if (!item.isThinking) {
                Column({ space: 6 }) {
                  LvMarkdownIn({ text: item.content })
                    .onAppear(() => {
                      this.inputText = item.content;
                      if (this.inputText.trim() == '') {
                        this.btnStartEnabled = false;
                        return;
                      }
                      this.btnStartEnabled = true;
                      // 语音输入时，自动播放回答
                      if (this.voiceSettings.autoplay && this.initTtsDone) {
                        this.play();
                      }
                    })

                  // 最后一个回答显示播放按钮
                  if (index == this.chatMessageList.length - 1) {
                    // 播放按钮
                    Button({ type: ButtonType.Normal, stateEffect: true }) {
                      Image(this.playState == audio.AudioState.STATE_RUNNING ? $r('app.media.ic_pause') :
                      $r('app.media.ic_play_circle_fill'))
                        .width(24)
                        .height(24)
                    }
                    .width(40)
                    .height(40)
                    .backgroundColor($r('app.color.message_sendbox_button'))
                    .borderRadius(10)
                    .alignSelf(ItemAlign.Start)
                    .enabled(this.btnStartEnabled && this.initTtsDone)
                    .onClick(async () => {
                      this.switchPlayOrStop();
                    });
                  }
                }
                .margin(16)
              }
            }
          }
        }, (item: blockUi) => JSON.stringify(item))
      }.onAreaChange(() => {
        this.isBottom = this.scroll.isAtEnd();
      })
    }
    .padding({ bottom: 5 })
    .edgeEffect(EdgeEffect.Spring)
    .width("100%")
    .onScrollEdge((side: Edge) => {
      if (side === Edge.Bottom) {
        animateTo({
          duration: 100,
          curve: Curve.EaseInOut
        }, () => {
          this.isBottom = true;
        })
      }
    })
    .onWillScroll((xOffset: number, yOffset: number, scrollState: ScrollState) => {
      if (yOffset < 0) {
        this.isScrolling = true;
        this.isBottom = false;
      }
    })
    .onScrollStop(() => {
      this.isScrolling = false;
    })
  }
}