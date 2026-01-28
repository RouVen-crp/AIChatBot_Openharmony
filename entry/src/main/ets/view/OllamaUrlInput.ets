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

import { AppStorageV2, promptAction } from "@kit.ArkUI";
import { http } from "@kit.NetworkKit";
import { BusinessError } from "@kit.BasicServicesKit";
import { Http } from "../utils/HttpRequest";
import { modelArray } from '../model/ModelOption';
import PreferenceModel from "../preference/PreferenceModel";
import { OllamaStorage } from "../model/setting/OllamaStorage";
import { AvoidArea } from "../model/layout/AvoidData";
import { NormalTitle } from "../component/NormalTitle";
import Logger from "../utils/Logger";

const regex: RegExp = new RegExp('^((2[0-4]\\d|25[0-5]|[01]?\\d\\d?)\\.){3}(2[0-4]\\d|25[0-5]|[01]?\\d\\d?)$');
const portRegex: RegExp =
  new RegExp('^(?:[1-9][0-9]{0,3}|[1-5][0-9]{4}|6[0-4][0-9]{3}|65[0-4][0-9]{2}|655[0-2][0-9]|6553[0-5])$');
const TAG = '[ollama_url_input]';

@Builder
export function ollamaUrlBuilder(name: string, param: Object) {
  OllamaUrlInput()
}

@Entry
@ComponentV2
struct OllamaUrlInput {
  @Local ollamaStorage: OllamaStorage = AppStorageV2.connect(OllamaStorage, 'OllamaStorage', () => new OllamaStorage())!;
  @Local avoidArea: AvoidArea = AppStorageV2.connect(AvoidArea, 'AvoidArea', () => new AvoidArea())!;

  regText(testStr: string): boolean {
    return regex.test(testStr)
  }

  portText(testStr: string): boolean {
    return portRegex.test(testStr)
  }

  getTag() {
    let httpRequest = new Http();
    httpRequest.setUrl(`${this.ollamaStorage.ipConfig}:${this.ollamaStorage.portConfig}/api/tags`);
    this.ollamaStorage.isSearchingOllama = true;
    let promise = httpRequest.request(httpRequest.url)
    promptAction.showToast({
      message: $r('app.string.is_searching_ollama')
    })
    promise.then((data: http.HttpResponse) => {
      Logger.info(TAG, `getTag = ${JSON.stringify(data.result)}`);
      if (data.responseCode === 200) {
        this.ollamaStorage.isConnect = true;
        let modelArray = JSON.parse(data.result as string) as modelArray;
        let modelNameArray = modelArray.models.map(model => model.name);
        this.ollamaStorage.selectedArray = modelArray.models.map(model => ({
          value: model.name
        } as SelectOption))
        if (this.ollamaStorage.modelName !== '') {
          this.ollamaStorage.selectedNumber = this.ollamaStorage.selectedArray.findIndex((item) => {
            return this.ollamaStorage.modelName === item.value
          })
        } else {
          this.ollamaStorage.modelName = this.ollamaStorage.selectedArray[this.ollamaStorage.selectedNumber].value as string;
        }
        promptAction.showToast({
          message: $r('app.string.save_success_ollama')
        })
        Logger.info(TAG, `getTagsArray = ${JSON.stringify(modelNameArray)}`);
      } else {
        this.ollamaStorage.isConnect = false;
      }
      PreferenceModel.writeData(this.ollamaStorage.ipConfig, 'ollama_setting', 'ipConfig');
      PreferenceModel.writeData(this.ollamaStorage.portConfig, 'ollama_setting', 'portConfig');
      this.ollamaStorage.isSearchingOllama = false;
      httpRequest.destroy();
    }).catch((err: BusinessError) => {
      Logger.info(TAG, `search err = ${JSON.stringify(err)}`);
      promptAction.showToast({
        message: $r('app.string.connect_server_error')
      })
      this.ollamaStorage.isConnect = false;
      this.ollamaStorage.isSearchingOllama = false;
      httpRequest.destroy();
      return;
    })
  }

  isCompleteLocalIP(ip: string): boolean {
    const fullRegex =
      /^(10(\.\d{1,3}){3}|192\.168(\.\d{1,3}){2}|172\.(1[6-9]|2\d|3[0-1])(\.\d{1,3}){2})$/;
    if (!fullRegex.test(ip)) {
      return false;
    }

    // 每段0-255验证
    return ip.split('.').every(num => {
      const n = Number(num);
      return n >= 0 && n <= 255;
    });
  }

  build() {
    Column() {
      NormalTitle()
      Column({ space: 10 }) {
        TextInput({
          placeholder: $r('app.string.placeholder_ollama_ip'), text: this.ollamaStorage.ipConfig
        })
          .backgroundColor($r('app.color.normal_textinput_background'))
          .borderRadius(16)
          .height(56)
          .type(InputType.Normal)
          .onChange((value: string) => {
            this.ollamaStorage.ipConfig = value;
          })

        TextInput({
          placeholder: $r('app.string.placeholder_ollama_port'), text: this.ollamaStorage.portConfig.toString()
        })
          .backgroundColor($r('app.color.normal_textinput_background'))
          .borderRadius(16)
          .height(56)
          .type(InputType.Number)
          .onChange((value: string) => {
            this.ollamaStorage.portConfig = value;
          })

        Column() {
          Button({ type: ButtonType.Normal }) {
            if (this.ollamaStorage.isSearchingOllama) {
              LoadingProgress()
            } else {
              Text($r('app.string.save_ollama_url'))
            }
          }
          .borderRadius(12)
          .width(80)
          .height(40)
          .borderColor('#666666')
          .borderWidth(1)
          .backgroundColor($r('app.color.normal_button_background'))
          .onClick(() => {
            if (this.ollamaStorage.isSearchingOllama) {
              return;
            }
            this.getTag();
          })
        }.justifyContent(FlexAlign.End)
        .alignItems(HorizontalAlign.End)
        .width("100%")
        .margin({ top: 10, right: 10 })
      }
      .padding({ left: 16, right: 16 })
    }
    .padding({ top: this.avoidArea.topRectHeight + 'px', bottom: this.avoidArea.bottomRectHeight + 'px' })
    .backgroundColor($r('sys.color.ohos_id_color_panel_bg'))
    .width('100%')
    .height('100%')
  }
}