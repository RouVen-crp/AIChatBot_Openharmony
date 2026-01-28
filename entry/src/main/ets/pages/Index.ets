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
import fs from '@ohos.file.fs';
import { MsgInput, MsgOutput, messageReturn, chatInput, responseReturn, Conversation } from '../model/MessageOption';
import { buffer, JSON, util } from '@kit.ArkTS';
import Logger from '../utils/Logger';
import Constants, { InputMode } from '../common/Constants';
import HeaderTitleBar from '../component/HeaderTitileBar';
import ChatBox from '../component/ChatBox';
import PreferenceModel from '../preference/PreferenceModel';
import { isVisionModel, modelArray } from '../model/ModelOption';
import { rdbHelper } from '../db/RdbHelper';
import { AppStorageV2, KeyboardAvoidMode, promptAction, router, window } from '@kit.ArkUI';
import { webSearchResult } from '../web/model/SearchModel';
import { WebSearchManager } from '../web/WebSearchManager';
import { DateTable } from '../model/DateModel';
import { inputMethod } from '@kit.IMEKit';
import { common } from '@kit.AbilityKit';
import { NetJudge } from '../utils/NetJudge';
import { BusinessError } from '@kit.BasicServicesKit';
import { OllamaStorage } from '../model/setting/OllamaStorage';
import { AvoidArea } from '../model/layout/AvoidData';
import worker, { MessageEvents } from '@ohos.worker';
import { Permissions } from '@ohos.abilityAccessCtrl';
import audio from '@ohos.multimedia.audio';
import { VoiceSettings } from '../model/setting/VoiceSettings';
import { allAllowed, requestPermissions } from '../workers/Permission';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { ProviderStorage } from '../model/setting/ProviderStorage';
import { SiliconflowStorage } from '../model/setting/SiliconflowStorage';
import AiProvider from '../aiCore';
import { CompletionsParams } from '../aiCore/middleware/schemas';
import { blockUi } from '../interfaces/blockUi';
import { messageContent, messageInput } from '../interfaces/inputMessage';
import { responseOpenAiCompatible } from '../aiCore/middleware/response';

const TAG = '[home_index]';
const uiAbilityContext = getContext(this) as common.UIAbilityContext;
const statusBarType = window.AvoidAreaType.TYPE_SYSTEM;
const navBarType = window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR;
const CompletionsParamsInitial: CompletionsParams = {
  model: "",
  stream: true,
  messages: []
}

@Entry
@ComponentV2
struct Index {
  @Local currentConversationIndex: number = 0;
  // 文本信息
  @Local textMessage: string = '';
  // 语音信息
  @Local voiceMessage: string = '';
  // 提示消息
  @Local promptMessage1: ResourceStr = $r('app.string.release_to_send');
  @Local promptMessage2: ResourceStr = $r('app.string.press_to_talk');
  @Local msgReturn: messageReturn = new messageReturn();
  @Local MsgResult: MsgOutput = new MsgOutput();
  @Provider('messageInfo') MsgInfo: Conversation = new Conversation();
  @Local isDeepThink: boolean = true;
  @Local isThinking: boolean = false;
  @Provider('chatScroll') scroll: Scroller = new Scroller();
  @Provider('isBottom') isBottom: boolean = true;
  @Provider('isScrolling') isScrolling: boolean = false;
  @Local isPrinting: boolean = false;
  @Local completionsParams: CompletionsParams = { model: '', messages: [], stream: false }
  @Provider('isWebSearch') isWebSearch: boolean = false;
  @Local siliconflowStorage: SiliconflowStorage =
    AppStorageV2.connect(SiliconflowStorage, 'SiliconflowStorage', () => new SiliconflowStorage())!;
  @Local providerStorage: ProviderStorage =
    AppStorageV2.connect(ProviderStorage, 'ProviderStorage', () => new ProviderStorage())!;
  @Local ollamaStorage: OllamaStorage =
    AppStorageV2.connect(OllamaStorage, 'OllamaStorage', () => new OllamaStorage())!;
  @Provider('modelArray') modelArray: string[] = [];
  @Provider('isShowSideBar') isShowSideBar: boolean = false;
  @Local isShow: boolean = false;
  @Local marginLength: number = 16;
  @Local conversations: Array<Conversation> = [];
  @Provider('opacityOverlay') opacityOverlay: number = 0;
  @Local isKeyBoardHidden: boolean = true;
  webSearchManager: WebSearchManager = WebSearchManager.getInstance();
  private windowClass = uiAbilityContext.windowStage.getMainWindowSync();
  @Local avoidArea: AvoidArea = AppStorageV2.connect(AvoidArea, 'AvoidArea', () => new AvoidArea())!;
  @Local scrollHeight: number = 0;
  @Local isNetConnected: boolean = false;
  @Local NetJudge: NetJudge = new NetJudge();
  @Local dateTables: DateTable [] = [
    {
      date: $r('app.string.date_today'),
      conversations: []
    },
    {
      date: $r('app.string.date_yesterday'),
      conversations: []
    },
    {
      date: $r('app.string.date_sevendays'),
      conversations: []
    },
    {
      date: $r('app.string.date_thirtydays'),
      conversations: []
    }
  ]
  // 语音识别
  private workerInstance?: worker.ThreadWorker;
  private readonly scriptURL: string = 'entry/ets/workers/NonStreamingAsrWithVadWorker.ets';
  @Local micInitDone: boolean = false;
  @Local resultForMic: string = '';
  private mic?: audio.AudioCapturer;
  private sampleList: Float32Array[] = [];
  @Local micStarted: boolean = false;
  @Local voiceSettings: VoiceSettings =
    AppStorageV2.connect(VoiceSettings, 'VoiceSettings', () => new VoiceSettings())!;
  // 输入模式
  @Local inputMode: InputMode = InputMode.TEXT_INPUT;
  // 是否发送语音消息
  @Local sendVoiceMessage: boolean = true;
  @Local imageUris: Array<string> = [];
  @Local isImageAdd: boolean = false;
  @Local aiProvider: AiProvider = new AiProvider('ollama', { baseURL: 'http://localhost:11434' });
  @Local modelSelected: string = '';

  flatten(samples: Float32Array[]): Float32Array {
    let n = 0;
    for (let i = 0; i < samples.length; ++i) {
      n += samples[i].length;
    }
    const ans: Float32Array = new Float32Array(n);
    let offset: number = 0;
    for (let i = 0; i < samples.length; ++i) {
      ans.set(samples[i], offset);
      offset += samples[i].length;
    }
    return ans;
  }

  async initMic() {
    const permissions: Permissions[] = ['ohos.permission.MICROPHONE'];
    let allowed: boolean = await allAllowed(permissions);
    if (!allowed) {
      Logger.info(TAG, 'request to access the microphone');
      const status: boolean = await requestPermissions(permissions);

      if (!status) {
        Logger.error(TAG, 'access to microphone is denied');
        this.resultForMic = 'failed to get microphone permission. Please retry.';
        return;
      }

      allowed = await allAllowed(permissions);
      if (!allowed) {
        Logger.error(TAG, 'failed to get microphone permission');
        this.resultForMic = 'failed to get microphone permission. Please retry.';
        return;
      }
    } else {
      Logger.info(TAG, 'allowed to access microphone');
    }

    const audioStreamInfo: audio.AudioStreamInfo = {
      samplingRate: audio.AudioSamplingRate.SAMPLE_RATE_16000,
      channels: audio.AudioChannel.CHANNEL_1,
      sampleFormat: audio.AudioSampleFormat.SAMPLE_FORMAT_S16LE,
      encodingType: audio.AudioEncodingType.ENCODING_TYPE_RAW,
    };

    const audioCapturerInfo: audio.AudioCapturerInfo = {
      source: audio.SourceType.SOURCE_TYPE_MIC,
      capturerFlags: 0
    };

    const audioCapturerOptions: audio.AudioCapturerOptions = {
      streamInfo: audioStreamInfo,
      capturerInfo: audioCapturerInfo
    };

    audio.createAudioCapturer(audioCapturerOptions, (err, data) => {
      if (err) {
        Logger.error(TAG, `error code is ${err.code}, error message is ${err.message}`);
        this.resultForMic = 'Failed to init microphone';
      } else {
        Logger.info(TAG, 'init mic successfully');
        this.mic = data;
        this.mic.on('readData', this.micCallback);

        if (this.workerInstance) {
          this.workerInstance.postMessage({ msgType: 'init-vad-mic', context: getContext() });
        }
      }
    });
  }

  private micCallback = (buffer: ArrayBuffer) => {
    const view: Int16Array = new Int16Array(buffer);
    const samplesFloat: Float32Array = new Float32Array(view.length);
    for (let i = 0; i < view.length; ++i) {
      samplesFloat[i] = view[i] / 32768.0;
    }
    this.sampleList.push(samplesFloat);
  }

  async aboutToAppear() {
    // 初始化语音识别模型
    this.workerInstance = new worker.ThreadWorker(this.scriptURL, { name: 'NonStreaming ASR worker' });

    this.workerInstance.onmessage = (e: MessageEvents) => {
      const msgType = e.data['msgType'] as string;
      Logger.info(TAG, `receive msg from worker: ${msgType}`);

      if (msgType == 'init-vad-mic-done') {
        this.micInitDone = true;
      }
      if (msgType == 'non-streaming-asr-vad-mic-partial') {
        this.resultForMic = e.data['text'] as string;
        // 更新信息
        this.voiceMessage = this.resultForMic;
        // 更新提示
        this.promptMessage2 = this.voiceMessage;
        // 延时提交
        setTimeout(() => {
          // 提交
          this.submitChat(this.voiceMessage);
          Logger.info(TAG, `submitChat: ${this.voiceMessage}`);
          // 还原提示信息
          this.promptMessage2 = $r('app.string.press_to_talk');
        }, 300);
      }
      if (msgType == 'non-streaming-asr-vad-mic-error') {
        this.resultForMic = e.data['text'] as string;
      }
    }

    const context = getContext();
    this.workerInstance.postMessage({ msgType: 'init-vad', context });
    this.workerInstance.postMessage({ msgType: 'init-non-streaming-asr', context });

    await this.initMic();

    this.loadPreference();
    this.getUIContext().setKeyboardAvoidMode(KeyboardAvoidMode.RESIZE);
    this.loadData().then(() => {
      Logger.info('conversations ' + JSON.stringify(this.conversations));
      for (let conversation of this.conversations) {
        this.conversationSort(conversation)
      }
    })
    this.NetJudge.init();
    this.isNetConnected = this.NetJudge.netAvailable;
  }

  setAvoidArea() {
    let statusBarArea = this.windowClass.getWindowAvoidArea(statusBarType);
    let navBarArea = this.windowClass.getWindowAvoidArea(navBarType);
    this.avoidArea.topRectHeight = statusBarArea.topRect.height === 0 ? 40 : statusBarArea.topRect.height;
    this.avoidArea.bottomRectHeight = navBarArea.bottomRect.height === 0 ? 40 : navBarArea.bottomRect.height;
    Logger.info(TAG, `${JSON.stringify(this.avoidArea)}`);
  }

  onAvoidAreaChange = (data: window.AvoidAreaOptions) => {
    if (data.type === window.AvoidAreaType.TYPE_KEYBOARD) {
      if (data.area.bottomRect.height <= 0) {
        this.isKeyBoardHidden = true;
        this.setAvoidArea();
      } else {
        this.isKeyBoardHidden = false;
        let statusBarArea = this.windowClass.getWindowAvoidArea(statusBarType);
        let navBarArea = this.windowClass.getWindowAvoidArea(navBarType);
        this.avoidArea.topRectHeight = statusBarArea.topRect.height;
        this.avoidArea.bottomRectHeight = -navBarArea.bottomRect.height
      }
      this.scroll.scrollEdge(Edge.Bottom)
    } else if (data.type === window.AvoidAreaType.TYPE_SYSTEM ||
      data.type === window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR) {
      this.setAvoidArea();
    }
  }

  async loadPreference() {
    this.providerStorage.currentProvider = PreferenceModel.getData('provider_setting', 'providerSelected');
    switch (this.providerStorage.currentProvider) {
      case "0":
        this.ollamaStorage.ipConfig = PreferenceModel.getData('ollama_setting', 'ipConfig');
        this.ollamaStorage.portConfig = PreferenceModel.getData('ollama_setting', 'portConfig');
        this.ollamaStorage.modelName = PreferenceModel.getData('ollama_setting', 'modelSelected');
        this.aiProvider =
          new AiProvider('ollama', { baseURL: `${this.ollamaStorage.ipConfig}:${this.ollamaStorage.portConfig}` });
        this.modelSelected = this.ollamaStorage.modelName;
        break;
      case "1":
        this.siliconflowStorage.apiKey = PreferenceModel.getData('siliconflow_setting', 'apiKey');
        this.siliconflowStorage.modelName = PreferenceModel.getData('siliconflow_setting', 'modelSelected');
        this.aiProvider = new AiProvider('siliconflow',
          {
            baseURL: `https://api.siliconflow.cn/v1`,
            apiKey: this.siliconflowStorage.apiKey
          });
        this.modelSelected = this.siliconflowStorage.modelName;
        break;
      default:
        break;
    }
  }

  refreshUI() {
    let newConversations: Array<Conversation> = this.conversations.slice();
    this.conversations = newConversations;
  }

  // 根据image uri 转换为 base64
  transitionImageUri2Base64(uri: string): string {
    // 读取图片为buffer
    const file = fs.openSync(uri, fs.OpenMode.READ_ONLY);
    const photoSize = fs.statSync(file.fd).size;
    console.info('Photo Size: ' + photoSize);
    let imageArraybuffer = new ArrayBuffer(photoSize);
    fs.readSync(file.fd, imageArraybuffer);
    fs.closeSync(file);

    let buf: buffer.Buffer = buffer.from(imageArraybuffer);
    // ps: data:image/jpg 要根据实际情况调整.
    const base64 = 'data:image/jpg;base64,' + buf.toString('base64', 0, buf.length);
    console.info(TAG, 'base64: ' + base64);
    return base64;
  }

  // 提交消息
  async submitChat(message: string) {
    let UserBlock: blockUi = new blockUi();
    UserBlock.role = "user";
    UserBlock.content = message;
    if (this.isImageAdd) {
      let newMessageInput: messageInput = {
        role: "user",
        content: []
      };
      UserBlock.imageUris = this.imageUris;
      for (let imageUri of UserBlock.imageUris) {
        let imageBase64 = this.transitionImageUri2Base64(imageUri);
        let imageMessageContent: messageContent = {
          type: "image_url",
          image_url: { url: imageBase64 }
        }
        newMessageInput.content.push(imageMessageContent)
      }
      let textMessageContent: messageContent = {
        type: "text",
        text: message
      }
      newMessageInput.content.push(textMessageContent)
      this.completionsParams.messages.push(newMessageInput);
      this.completionsParams.includeImage = true;
      this.imageUris = [];
      this.conversations[this.currentConversationIndex].msgArray.push(UserBlock);
    } else if (this.isWebSearch) {
      this.conversations[this.currentConversationIndex].msgArray.push(UserBlock);

      let searchResult: webSearchResult[] = [];
      try {
        searchResult = await this.webSearchManager.search(message);
      } catch (err) {
        Logger.info(TAG, `getWebSearch fail ${JSON.stringify(err)}`);
      }
      let search_results = searchResult
        .map((result, idx) =>
        `<result source="${result.url}" id="${idx}">${result.content}</result>`)
        .join("\n");
      let current_date_time = new Date().toLocaleString();
      let webSearchMessageInput: messageInput = {
        role: "system",
        content: [{
          type: "text",
          text: Constants.DEFAULT_WEBSEARCH_PROMP
            .replace("{current_date_time}", current_date_time)
            .replace("{search_results}", search_results)
        }]
      };
      this.completionsParams.messages[0] = webSearchMessageInput;
    } else {
      this.conversations[this.currentConversationIndex].msgArray.push(UserBlock);
      let newMessageInput: messageInput = {
        role: "user",
        content: [{
          type: "text",
          text: message
        }]
      };
      this.completionsParams.messages.push(newMessageInput);
    }

    this.completionsParams.stream = true
    this.completionsParams.model = this.modelSelected;
    try {
      const currentConversation: Conversation = this.conversations[this.currentConversationIndex];
      // 如果是新对话，先更新会话标题并保存
      if (currentConversation.title === Constants.NEW_CONVERSATION_NAME) {
        currentConversation.title = message.length > 20 ? message.substring(0, 20) + "..." : message;
      }
      this.refreshUI()
      // 更新会话信息
      currentConversation.lastMessage = message;
      currentConversation.timestamp = new Date();
      currentConversation.is_started_progress = true;
      if (!this.completionsParams.includeImage) {
        currentConversation.completionsParams = this.completionsParams;
      }
      Logger.info(TAG, `${JSON.stringify(currentConversation.completionsParams)}`)
      // 保存会话更新
      await rdbHelper.saveConversation(currentConversation);
      // 保存用户消息
      await rdbHelper.saveMessage(currentConversation.id, UserBlock);
      this.getUIContext().getFocusController().clearFocus();
      if (this.isDeepThink) {
        this.httpData(currentConversation);
      } else {
        this.httpData(currentConversation);
      }
    } catch (error) {
      Logger.error(TAG, `Error in startRecognize: ${error}`);
      promptAction.showToast({ message: $r('app.string.operation_error'), duration: 2000 });
    }
  }

  public async loadData(index: number = 0): Promise<void> {
    try {
      await rdbHelper.openDatabase(getContext(this));
      const loadedConversations: Array<Conversation> = await rdbHelper.getConversations();

      if (loadedConversations.length > 0) {
        // 为每个会话加载消息
        for (let conversation of loadedConversations) {
          conversation.msgArray = await rdbHelper.getMessages(conversation.id);
        }

        this.conversations = loadedConversations;
        this.currentConversationIndex = index;
        this.completionsParams = this.conversations[index].completionsParams || CompletionsParamsInitial;
      } else {
        // 创建默认会话时使用生成的ID
        const defaultConversation: Conversation = {
          id: this.generateUniqueId(),
          title: "新对话",
          lastMessage: "点击开始新对话",
          timestamp: new Date(),
          msgArray: [],
          completionsParams: CompletionsParamsInitial,
          is_started_progress: false
        };

        const success = await rdbHelper.saveConversation(defaultConversation);
        if (success) {
          this.conversations = [defaultConversation];
          this.conversations[this.currentConversationIndex].msgArray = [];
          this.completionsParams = CompletionsParamsInitial;
          this.currentConversationIndex = 0;

        } else {
          Logger.error(TAG, 'Failed to save default conversation');
          promptAction.showToast({ message: $r('app.string.create_default_session_error') });
        }
      }
    } catch (error) {
      Logger.error(TAG, `Failed to load data: ${error}`);
      promptAction.showToast({ message: $r('app.string.load_data_error') });
      this.conversations = [];
      this.completionsParams = CompletionsParamsInitial;
      this.currentConversationIndex = 0;
    }
  }

  // 创建新对话
  async createNewConversation(): Promise<void> {
    const newConversation: Conversation = {
      id: this.generateUniqueId(),
      title: Constants.NEW_CONVERSATION_NAME,
      lastMessage: Constants.CLICK_ADD_CONVERSATION,
      timestamp: new Date(),
      msgArray: [],
      completionsParams: CompletionsParamsInitial,
      is_started_progress: false
    };

    try {
      const success = await rdbHelper.saveConversation(newConversation);
      if (success) {
        let newConversations = this.conversations.slice();
        newConversations.unshift(newConversation);
        this.conversations = newConversations;
        this.currentConversationIndex = 0;
        this.completionsParams = CompletionsParamsInitial
        Logger.info(TAG, `create new conversation: ` + JSON.stringify(this.conversations));
      } else {
        promptAction.showToast({ message: $r('app.string.create_new_session_error'), duration: 2000 });
      }
    } catch (error) {
      Logger.error(TAG, `Failed to create new conversation: ${error}`);
      promptAction.showToast({ message: $r('app.string.create_new_session_error'), duration: 2000 });
    }
  }

  private async deleteConversation(index: number): Promise<void> {
    try {
      const conversationToDelete = this.conversations[index];
      await rdbHelper.deleteConversation(conversationToDelete.id);
      let newConversations = this.conversations.slice();
      newConversations.splice(index, 1);
      if (index === this.currentConversationIndex) {
        if (newConversations.length > 0) {
          this.currentConversationIndex = 0;
          this.completionsParams = newConversations[0].completionsParams;
        } else {
          // 如果没有其他会话，创建一个新的默认会话
          const defaultConversation: Conversation = {
            id: this.generateUniqueId(),
            title: Constants.NEW_CONVERSATION_NAME,
            lastMessage: Constants.CLICK_ADD_CONVERSATION,
            timestamp: new Date(),
            msgArray: [],
            completionsParams: CompletionsParamsInitial,
            is_started_progress: false
          };
          const success = await rdbHelper.saveConversation(defaultConversation);
          if (success) {
            newConversations = [defaultConversation];
            this.currentConversationIndex = 0;
            this.completionsParams = CompletionsParamsInitial;
          }
        }
      } else if (index < this.currentConversationIndex) {
        this.currentConversationIndex--;
      }
      this.conversations = newConversations;
    } catch (error) {
      Logger.error(TAG, `Failed to delete conversation: ${error}`);
      promptAction.showToast({ message: $r('app.string.delete_conversation_error'), duration: 2000 });
    }
  }

  onPageShow(): void {
    this.windowClass.setWindowLayoutFullScreen(true);
    this.setAvoidArea();
    this.windowClass.on('avoidAreaChange', this.onAvoidAreaChange);
    this.loadPreference();
  }

  private generateUniqueId(): number {
    return Date.now() + Math.floor(Math.random() * 1000);
  }

  httpData(currentConversation: Conversation) {
    let AssistantMsgInput: blockUi = new blockUi();
    AssistantMsgInput.role = "assistant";
    let num = currentConversation.msgArray.length;
    this.refreshUI()
    currentConversation.msgArray.push(AssistantMsgInput);
    currentConversation.msgArray[num].isReceiveStream = true;
    setTimeout(() => {
      this.scroll.scrollEdge(Edge.Bottom);
    }, 500)
    if (this.isImageAdd && !isVisionModel(this.modelSelected)) {
      currentConversation.msgArray[num].content = "该模型不支持图像识别，请更换模型重试";
      currentConversation.is_started_progress = false;
      currentConversation.msgArray[num].isReceiveStream = false;
      this.isImageAdd = false;
    } else {
      let newMessageInput: messageInput = {
        role: "assistant",
        content: [{
          type: "text",
          text: ""
        }]
      };
      this.aiProvider.apiClient.onDataReceive((data: ArrayBuffer) => {
        let decoder = util.TextDecoder.create('utf-8');
        let str = decoder.decodeToString(new Uint8Array(data));
        let lines = str.split('\n')
        for (const line of lines) {
          const trimmedLine = line.trim();
          if (trimmedLine.startsWith('data: ')) {
            let dataOfTrimmedLine = trimmedLine.slice(6);
            if (dataOfTrimmedLine === '[DONE]') {
              break;
            }
            try {
              let responseCompatible: responseOpenAiCompatible =
                JSON.parse(dataOfTrimmedLine) as responseOpenAiCompatible;
              //ollama
              if (responseCompatible.system_fingerprint === "fp_ollama") {
                if (responseCompatible.choices[0].delta.content &&
                  responseCompatible.choices[0].finish_reason === null) {
                  if (responseCompatible.choices[0].delta.content === '<think>') {
                    currentConversation.msgArray[num].isThinking = true;
                    return;
                  } else if (responseCompatible.choices[0].delta.content === '</think>') {
                    currentConversation.msgArray[num].isThinking = false;
                    return;
                  }
                  if (currentConversation.msgArray[num].isThinking) {
                    currentConversation.msgArray[num].thinkingContent += responseCompatible.choices[0].delta.content;
                  } else {
                    currentConversation.msgArray[num].content += responseCompatible.choices[0].delta.content;
                    newMessageInput.content[0].text += responseCompatible.choices[0].delta.content;
                  }
                } else if (responseCompatible.choices[0].finish_reason === "stop") {
                  currentConversation.is_started_progress = false;
                }
              } else {
                //exist reasoning_content
                if (responseCompatible.choices[0].delta.reasoning_content
                  && responseCompatible.choices[0].finish_reason === null) {
                  currentConversation.msgArray[num].isThinking = true;
                  currentConversation.msgArray[num].thinkingContent += responseCompatible.choices[0].delta.reasoning_content;
                } else if (responseCompatible.choices[0].delta.content &&
                  responseCompatible.choices[0].delta.reasoning_content === null) {
                  currentConversation.msgArray[num].isThinking = false;
                  currentConversation.msgArray[num].content += responseCompatible.choices[0].delta.content.toString();
                  newMessageInput.content[0].text += responseCompatible.choices[0].delta.content;
                } else if (responseCompatible.choices[0].finish_reason === "stop") {
                  currentConversation.is_started_progress = false;
                }
              }

              if (this.isBottom === true && this.isScrolling === false) {
                this.scroll.scrollEdge(Edge.Bottom);
              }
            } catch (e) {
              console.error('Failed to parse JSON:', e);
              continue;
            }
          }
        }
      })
      let promise = this.aiProvider.createChatCompletion(this.completionsParams)
      promise.then(async (data: number) => {
        this.isImageAdd = false;
        currentConversation.msgArray[num].isReceiveStream = false;
        if (data === 200) {
          currentConversation.is_started_progress = false;
          this.completionsParams.messages.push(newMessageInput);
          this.refreshUI();
          Logger.info(TAG, 'newInput:' + JSON.stringify(this.completionsParams.messages));
          // 只在完成时保存AI的回复消息
          const lastMessage: blockUi = currentConversation.msgArray[num];
          await rdbHelper.saveMessage(currentConversation.id, lastMessage).then(() => {
            Logger.info(TAG, 'save Message success');
          });
          // 更新会话的最后消息
          currentConversation.lastMessage = lastMessage.content;
          await rdbHelper.saveConversation(currentConversation).then(() => {
            Logger.info(TAG, 'save Conversation success');
          });
          Logger.info(TAG, "requestInStream OK! ResponseCode is " + JSON.stringify(data));
          this.aiProvider.apiClient.offDataReceive()
        } else {
          Logger.info(TAG, 'requestInStream ERROR! ResponseCode is :' + JSON.stringify(data));
        }
      }).catch((err: BusinessError) => {
        Logger.info(TAG, "requestInStream ERROR : err = " + JSON.stringify(err));
        Logger.info(TAG, 'error:' + JSON.stringify(err));
        this.isImageAdd = false;
        currentConversation.is_started_progress = false;
        currentConversation.msgArray[num].isReceiveStream = false;
        currentConversation.msgArray[num].content = "Woooops!出问题啦，请重试";
        this.aiProvider.apiClient.offDataReceive()
        this.aiProvider.apiClient.destroy()
      })
    }
  }

  @Builder
  ConversationItem(conversation: Conversation, index: number) {
    Flex({ direction: FlexDirection.Row, alignItems: ItemAlign.Center }) {
      Text(conversation.title)
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .fontColor($r('app.color.conversation_item_text'))
        .layoutWeight(1)
      Row() {
        if (this.currentConversationIndex === index) {
          Image($r('app.media.ic_public_close'))
            .width(16)
            .height(16)
            .margin({ left: 8 })
            .opacity(0.6)
            .fillColor($r('app.color.conversation_item_icon'))
            .onClick((event: ClickEvent) => {
              this.deleteConversation(index);
            })
        }
      }
    }
    .width('90%')
    .height(60)
    .padding(12)
    .borderRadius(8)
    .backgroundColor(this.currentConversationIndex === index ? $r('app.color.history_item_selected') :
    $r('app.color.history_item_normal'))
    .animation({ duration: 300 }) // 添加动画效果
    .onClick(() => {
      this.currentConversationIndex = index;
      this.completionsParams = this.conversations[index].completionsParams;
      Logger.info('newInput: ' + JSON.stringify(this.completionsParams))
      this.scroll.scrollEdge(Edge.End)
    })
  }

  /**
   *
   * @param date
   * @returns
   */
  formatDate(date: Date): string {
    return date.toLocaleDateString();
  }

  /**
   *
   * @param date
   * @returns
   */
  compareDate(date: Date): ResourceStr {
    const context = getContext(this) as common.UIAbilityContext
    let today: Date = new Date();
    if (date.getFullYear() === today.getFullYear()
      && date.getMonth() === today.getMonth()
      && date.getDate() === today.getDate()) {
      return context.resourceManager.getStringSync($r('app.string.date_today'));
    } else {
      let timeDiff = Math.abs(today.getTime()) - Math.abs(date.getTime());
      let daysDiff = Math.ceil(timeDiff / (1000 * 3600 * 24));
      if (daysDiff === 1) {
        return context.resourceManager.getStringSync($r('app.string.date_yesterday'));
      }
      // 判断是否在7天内
      else if (daysDiff <= 7) {
        return context.resourceManager.getStringSync($r('app.string.date_sevendays'));
      }
      // 判断是否在30天内
      else if (daysDiff <= 30) {
        return context.resourceManager.getStringSync($r('app.string.date_thirtydays'));
      }
      // 判断是否在30天以外
      else {
        return this.formatDate(date);
      }
    }
  }

  /**
   *
   * @param conversation
   */
  conversationSort(conversation: Conversation) {
    let conversationTimestamp = conversation.timestamp
    switch (this.compareDate(conversationTimestamp)) {
      case $r('app.string.date_today'):
        this.dateTables[0].conversations.push(conversation);
        break;
      case $r('app.string.date_yesterday'):
        this.dateTables[1].conversations.push(conversation);
        break;
      case $r('app.string.date_sevendays'):
        this.dateTables[2].conversations.push(conversation);
        break;
      case $r('app.string.date_thirtydays'):
        this.dateTables[3].conversations.push(conversation);
        break;
      default:
        let newDataTable: DateTable = new DateTable();
        newDataTable.date = this.formatDate(conversationTimestamp);
        newDataTable.conversations.push(conversation);
        for (let dataTable of this.dateTables) {
          if (dataTable.date === newDataTable.date) {
            dataTable.conversations.push(conversation)
          } else {
            this.dateTables.push(newDataTable)
          }
        }
    }
  }

  @Builder
  itemHead(dataTable: DateTable) {
    Text(dataTable.date)
      .fontSize(14)
      .fontColor(Color.Grey)
      .margin({ bottom: 8 })
  }

  @Builder
  itemHeadByString(conversation: Conversation, index: number) {
    if (index > 0) {
      if (this.compareDate(conversation.timestamp) !==
      this.compareDate(this.conversations[index-1].timestamp)) {
        Text(this.compareDate(conversation.timestamp))
          .fontSize(14)
          .fontColor(Color.Grey)
          .margin({ bottom: 8, top: 5 })
      }
    } else {
      Text(this.compareDate(conversation.timestamp))
        .fontSize(14)
        .fontColor(Color.Grey)
        .margin({ bottom: 8 })
    }
  }

  @Styles
  imageStyles() {
    .width(24)
    .height(24)
  }

  @Styles
  buttonStyles() {
    .width(40)
    .height(40)
    .backgroundColor($r('app.color.message_sendbox_button'))
    .borderRadius(10)
  }

  build() {
    SideBarContainer(SideBarContainerType.Overlay) {
      Column() {
        Column({ space: 12 }) {
          List({ space: 5 }) {
            ForEach(this.conversations, (conversation: Conversation, index: number) => {
              ListItemGroup({ header: this.itemHeadByString(conversation, index) }) {
                ListItem() {
                  this.ConversationItem(conversation, index)
                }
              }
            })
          }
          .layoutWeight(1)
          .sticky(StickyStyle.Header)
          .scrollBar(BarState.Off)
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
        .width('100%')
        .margin({ top: 20, left: 35, bottom: 20 })

        Button() {
          Image($r('app.media.ic_public_gearshape'))
            .imageStyles()
            .fillColor($r('sys.color.ohos_id_color_primary'))
        }
        .buttonStyles()
        .margin({ bottom: 36 })
        .type(ButtonType.Normal)
        .onClick(() => {
          router.pushUrl({ url: 'pages/Setting' })
        })
      }
      .width('80%')
      .height('100%')
      .padding({ top: this.avoidArea.topRectHeight + 'px', bottom: this.avoidArea.bottomRectHeight + 'px' })
      .justifyContent(FlexAlign.SpaceBetween)
      .backgroundColor($r('sys.color.ohos_id_color_panel_bg'))

      Stack() {
        Column() {
          //标题栏
          HeaderTitleBar({
            onClickOK: (): void => {
              this.createNewConversation();
            },
            chatTitle: this.conversations[this.currentConversationIndex]?.title,
          })
            .zIndex(1)
            .expandSafeArea([SafeAreaType.KEYBOARD])
          Column() {
            if (this.conversations[this.currentConversationIndex]?.msgArray.length > 0) {
              // 对话框
              ChatBox({
                chatMessageList: this.conversations[this.currentConversationIndex].msgArray
              })
                .layoutWeight(1)
              if (!this.isBottom) {
                Button() {
                  Image($r('app.media.ic_public_scroll_bottom'))
                    .width(30)
                    .height(30)
                    .fillColor($r('sys.color.ohos_id_color_primary'))
                }.zIndex(99)
                .backgroundColor(Color.Transparent)
                .position({ x: '50%', y: '90%' })
                .onClick(() => {
                  this.scroll.scrollEdge(Edge.Bottom);
                  this.isBottom = true;
                })
              }
            }
          }
          .backgroundColor($r('sys.color.ohos_id_color_background'))
          .padding({ bottom: 10 })
          .layoutWeight(1)

          if (this.inputMode === InputMode.TEXT_INPUT) {
            Column() {
              if (this.isImageAdd) {
                Row() {
                  ForEach(this.imageUris, (uri: string) => {
                    Image(uri)
                      .height(50)
                      .width(50)
                      .onClick(() => {
                        // 删除图片的逻辑
                        this.imageUris = this.imageUris.filter(u => u !== uri);
                        if (this.imageUris) {
                          this.isImageAdd = false;
                        }
                      })
                      .margin({ right: 5 })
                      .borderWidth(1)
                      .borderColor('red')
                  })
                }
                .backgroundColor(Color.Transparent)
                .width('100%')
                .padding({ left: 8, top: 5 })
              }

              // 输入框
              TextArea({
                placeholder: $r('app.string.placeholder_input_message'), text: this.textMessage
              })
                .backgroundColor(Color.Transparent)
                .onChange((msg: string) => {
                  this.textMessage = msg;
                  // 设置不自动播放
                  if (msg.length > 0) {
                    this.voiceSettings.autoplay = false;
                  }
                })
                .onSubmit(() => {
                  this.submitChat(this.textMessage);
                  // 设置为空字符串
                  this.textMessage = '';
                })
                .constraintSize({ maxHeight: '30%' })
                .margin({
                  top: 10,
                  bottom: 10,
                })

              // 输入框工具栏
              Row({ space: 8 }) {
                Toggle({ type: ToggleType.Button, isOn: $$this.isWebSearch }) {
                  Row({ space: 5 }) {
                    Image($r('app.media.ic_internet'))
                      .width(20)
                      .height(20)
                      .fillColor($r('app.color.sendbox_toogle_icon'))
                    Text($r('app.string.web_search'))
                      .fontColor($r('sys.color.font_primary'))
                      .fontSize(14)
                  }
                  .justifyContent(FlexAlign.Center)
                  .width('100%')

                }.width(100)
                .height('75%')
                .onClick(() => {
                  this.isNetConnected = this.NetJudge.netAvailable
                  if (this.isNetConnected === false) {
                    promptAction.showToast({
                      message: $r('app.string.net_prompt')
                    })
                    this.isWebSearch = false;
                  }
                })
                .onChange((isOn: boolean) => {
                  if (isOn) {
                    this.isWebSearch = true;
                  } else {
                    this.isWebSearch = false;
                  }
                })

                Blank()
                  .layoutWeight(1)

                // 图片导入按钮
                Button({ type: ButtonType.Normal, stateEffect: true }) {
                  Image($r('app.media.picture_2'))
                    .imageStyles()
                }
                .buttonStyles()
                .onClick(() => {
                  let photoSelectOptions = new photoAccessHelper.PhotoSelectOptions();
                  photoSelectOptions.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE; // 过滤选择媒体文件类型为IMAGE。
                  photoSelectOptions.maxSelectNumber = 2; // 选择媒体文件的最大数目。
                  let photoViewPicker = new photoAccessHelper.PhotoViewPicker();
                  photoViewPicker.select(photoSelectOptions)
                    .then((photoSelectResult: photoAccessHelper.PhotoSelectResult) => {
                      this.imageUris = photoSelectResult.photoUris;
                      if (this.imageUris.length !== 0) {
                        this.isImageAdd = true;
                      }
                      console.info('photoViewPicker.select to file succeed and uris are:' + this.imageUris);
                    })
                    .catch((err: BusinessError) => {
                      console.error(`Invoke photoViewPicker.select failed, code is ${err.code}, message is ${err.message}`);
                    })
                })

                // 语音切换按钮
                Button({ type: ButtonType.Normal, stateEffect: true }) {
                  Image($r('app.media.ic_voice_input'))
                    .imageStyles()
                }
                .buttonStyles()
                .enabled(this.micInitDone)
                .onTouch(() => {
                  this.inputMode = InputMode.VOICE_INPUT;
                })

                if (this.conversations[this.currentConversationIndex]?.is_started_progress) {
                  // 暂停按钮
                  Button({ type: ButtonType.Normal, stateEffect: true }) {
                    Image($r("app.media.ic_pause"))
                      .imageStyles()
                  }
                  .buttonStyles()
                  .onClick(() => {
                    this.conversations[this.currentConversationIndex].is_started_progress = false;
                    let newConversations: Array<Conversation> = this.conversations.slice();
                    this.conversations = newConversations;
                  })
                } else {
                  // 提交按钮
                  Button({ type: ButtonType.Normal }) {
                    Image($r("app.media.ic_public_submit"))
                      .imageStyles()
                  }
                  .buttonStyles()
                  .onClick(async () => {
                    this.submitChat(this.textMessage);
                    this.textMessage = '';
                    inputMethod.getController().stopInputSession();
                  })
                  .enabled(this.textMessage !== '')
                }
              }
              .height(50)
              .alignItems(VerticalAlign.Center)
              .padding({ left: 10, right: 10, bottom: 10 })
            }
            .backgroundColor($r('app.color.message_sendbox_background'))
            .margin({ left: 10, right: 10, bottom: this.isKeyBoardHidden ? 20 : 30 })
            .border({ radius: 12 })
          } else {
            // 语音输入
            if (this.micStarted) {
              Text(this.promptMessage1)
                .fontColor(Color.Grey)
                .height(40)
            }
            Column() {
              Row() {
                if (!this.micStarted) {
                  // 文本输入按钮
                  Button({ type: ButtonType.Normal }) {
                    Image($r("app.media.ic_text_input"))
                      .imageStyles()
                  }
                  .buttonStyles()
                  .onClick(() => {
                    this.inputMode = InputMode.TEXT_INPUT;
                  })
                }
                Column() {
                  // 提示
                  Text(this.promptMessage2)
                    .textAlign(TextAlign.Center)
                    .fontSize(16)
                    .fontWeight(FontWeight.Medium)
                    .width('100%')
                    .height(60)
                    .enabled(this.micInitDone)
                    .onTouch((event) => {
                      if (event && this.mic) {
                        if (event.type === TouchType.Down) {
                          Logger.info(TAG, 'TouchType.Down');
                          this.micStarted = true;
                          this.sampleList = [];
                          this.mic.start();
                          this.promptMessage1 = $r('app.string.release_to_send');
                        }

                        if (event.type === TouchType.Up) {
                          Logger.info(TAG, 'TouchType.Up');
                          this.mic.stop();
                          this.micStarted = false;

                          if (!this.sendVoiceMessage) {
                            Logger.info(TAG, `sendVoiceMessage: ${this.sendVoiceMessage}, voice message is cancelled.`);
                            return;
                          }

                          const samples = this.flatten(this.sampleList);
                          let s = 0;
                          for (let i = 0; i < samples.length; ++i) {
                            s += samples[i];
                          }
                          Logger.info(TAG, `samples ${samples.length}, sum: ${s}`);

                          if (this.workerInstance) {
                            Logger.info(TAG, 'decode mic');
                            this.workerInstance.postMessage({
                              msgType: 'non-streaming-asr-vad-mic', samples,
                            })
                            // 设置自动播放
                            this.voiceSettings.autoplay = true;
                          } else {
                            Logger.info(TAG, `this worker instance is undefined ${this.workerInstance}`);
                          }
                        }
                        if (event.type === TouchType.Move) {
                          Logger.info(TAG, 'TouchType.Move');
                          if (event.touches[0].y < -60) {
                            this.promptMessage1 = $r('app.string.release_to_cancel');
                            this.sendVoiceMessage = false;
                          } else {
                            this.promptMessage1 = $r('app.string.release_to_send');
                            this.sendVoiceMessage = true;
                          }
                        }
                      }
                    })

                  if (this.micStarted) {
                    Image($r("app.media.ic_sound_wave"))
                      .height(30)
                      .objectFit(ImageFit.Contain)
                  }
                }
                .layoutWeight(1)
              }
              .padding({ left: 10, right: 10 })
              .layoutWeight(1)
            }
            .width("95%")
            .height(this.micStarted ? 120 : 60)
            .margin({ left: 10, right: 10, bottom: 20 })
            .border({ width: 1, radius: 12 })
            .animation({ duration: 300 })
          }
        }
        .padding({ top: this.avoidArea.topRectHeight + 'px', bottom: this.avoidArea.bottomRectHeight + 'px' })
        .width("100%")
        .layoutWeight(1)
        .backgroundColor($r('sys.color.ohos_id_color_background'))
        .justifyContent(FlexAlign.SpaceBetween)

        if (this.isShowSideBar) {
          Column() {
          }
          .backgroundColor(Color.Black)
          .opacity(this.opacityOverlay)
          .width('100%')
          .height('100%')
          .onClick(() => {
            animateTo({
              duration: 300,
              curve: Curve.Smooth
            }, () => {
              this.isShowSideBar = false;
              this.opacityOverlay = 0;
            })
          })
        }
      }
    }
    .showControlButton(false)
    .autoHide(false)
    .sideBarWidth(300)
    .minSideBarWidth(300)
    .showSideBar($$this.isShowSideBar)
    .controlButton({
      top: 16,
      left: this.marginLength
    })
  }
}

