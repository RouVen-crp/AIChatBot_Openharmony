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

import { AppStorageV2, PersistenceV2, promptAction, router, SelectOptions } from "@kit.ArkUI"
import { http } from "@kit.NetworkKit"
import { BusinessError } from "@kit.BasicServicesKit"
import { Http } from "../utils/HttpRequest"
import { modelArray, siliconflowModel, siliconflowModelResponse } from '../model/ModelOption';
import PreferenceModel from "../preference/PreferenceModel"
import { AvoidArea } from "../model/layout/AvoidData"
import { NormalTitle } from "../component/NormalTitle"
import Logger from "../utils/Logger";
import { SiliconflowStorage } from "../model/setting/SiliconflowStorage";
import { ProviderStorage } from "../model/setting/ProviderStorage";

const regex: RegExp = new RegExp('^((2[0-4]\\d|25[0-5]|[01]?\\d\\d?)\\.){3}(2[0-4]\\d|25[0-5]|[01]?\\d\\d?)$')
const portRegex: RegExp =
  new RegExp('^(?:[1-9][0-9]{0,3}|[1-5][0-9]{4}|6[0-4][0-9]{3}|65[0-4][0-9]{2}|655[0-2][0-9]|6553[0-5])$')

const TAG = '[Siliconflow_setting_component]'

@Builder
export function siliconflowSettingBuilder(name: string, param: Object) {
  SiliconflowSettingComponent()
}


@Entry
@ComponentV2
export struct SiliconflowSettingComponent {
  portController: TextInputController = new TextInputController();
  @Local modelArray: string[] = [];
  @Local siliconflowStorage: SiliconflowStorage =
    AppStorageV2.connect(SiliconflowStorage, 'SiliconflowStorage', () => new SiliconflowStorage())!;
  @Local passwordState: boolean = false;
  @Local providerStorage: ProviderStorage = AppStorageV2.connect(ProviderStorage, 'ProviderStorage', () => new ProviderStorage())!;
  @Local avoidArea: AvoidArea = AppStorageV2.connect(AvoidArea, 'AvoidArea', () => new AvoidArea())!;

  regText(testStr: string): boolean {
    return regex.test(testStr);
  }

  portText(testStr: string): boolean {
    return portRegex.test(testStr);
  }

  @Styles
  rowStyles() {
    .backgroundColor($r('app.color.item_button_background'))
    .padding({ left: 8, right: 8 })
    .borderRadius(16)
    .width('100%')
    .height(56)
  }

  getSiliconflowTag() {
    let httpRequest = new Http();
    httpRequest.setUrl(`${this.siliconflowStorage.chatModelUrl}`);
    Logger.info(TAG, `${httpRequest.url}`);
    let promise = httpRequest.requestSiliconflow(httpRequest.url, this.siliconflowStorage.apiKey);
    promise.then((data: http.HttpResponse) => {
      Logger.info(TAG, `getTag = ${JSON.stringify(data.result)}`);
      if (data.responseCode === 200) {
        this.siliconflowStorage.isConnect = true;
        let responseResult = JSON.parse(data.result as string) as siliconflowModelResponse;
        Logger.info(TAG, `getTag = ${JSON.stringify(responseResult)}`);
        let modelArrayResponse = responseResult.data as Array<siliconflowModel>;
        Logger.info(TAG, `getTag = ${JSON.stringify(modelArrayResponse)}`);
        let modelNameArray = modelArrayResponse.map(item => item.id);
        Logger.info(TAG, `getTag = ${JSON.stringify(modelNameArray)}`);
        this.modelArray = modelNameArray;
        this.siliconflowStorage.selectedArray = this.modelArray.map(model => ({
          value: model
        } as SelectOption))
        this.siliconflowStorage.modelName =
          this.siliconflowStorage.selectedArray[this.siliconflowStorage.selectedNumber].value as string;
        PreferenceModel.writeData(this.siliconflowStorage.apiKey, 'siliconflow_setting', 'apiKey');
      } else {
        this.siliconflowStorage.isConnect = false;
      }
      httpRequest.destroy();
    }).catch((err: BusinessError) => {
      Logger.info(TAG, `search err = ${JSON.stringify(err)}`);
      promptAction.showToast({
        message: $r('app.string.connect_server_error')
      })
      httpRequest.destroy();
      return;
    })
  }

  build() {
    Column() {
      NormalTitle();
      Column({ space: 10 }) {
        Column() {
          Row({ space: 12 }) {
            Text($r('app.string.title_setting_siliconflow'))
              .fontColor($r('app.color.list_item_text_primary'))
              .fontWeight(FontWeight.Bold)
            Blank()
            Toggle({ type: ToggleType.Switch, isOn: this.providerStorage.currentProvider === '1' ? true : false })
              .onChange((isOn: boolean) => {
                this.siliconflowStorage.isToggleOn = isOn;
                if (this.siliconflowStorage.isToggleOn) {
                  this.providerStorage.currentProvider = '1';
                  PreferenceModel.writeData('1', 'provider_setting', 'providerSelected');
                  this.siliconflowStorage.isConnect = true;
                } else {
                  PreferenceModel.writeData('-1', 'provider_setting', 'providerSelected');
                  this.siliconflowStorage.isConnect = false;
                }
              })
          }
          .padding({ left: 8, right: 8 })
          .width('100%')
          .height(56)

          Divider();

          Row({ space: 12 }) {
            TextInput({ text: this.siliconflowStorage.apiKey, placeholder: ' Api key:' })
              .width('85%')
              .height(56)
              .type(InputType.Password)
              .showPasswordIcon(true)
              .showPassword(this.passwordState)
              .onSecurityStateChange(((isShowPassword: boolean) => {
                this.passwordState = isShowPassword;
              }))
              .onChange((value: string) => {
                this.siliconflowStorage.apiKey = value;
                console.info('TAG', this.siliconflowStorage.apiKey);
              })

            // Blank();

            Button({ type: ButtonType.Normal }) {
              Text('获取')
            }
            .borderRadius(12)
            .width(60)
            .height(40)
            .borderColor('#666666')
            .borderWidth(1)
            .backgroundColor($r('app.color.normal_button_background'))
            .onClick(() => {
              this.getSiliconflowTag();
            })
          }.width('100%')
          .height(56)
          .padding({ left: 8, right: 8 })
          .margin({ top: 16 })

        }.width('100%')

        Row({ space: 12 }) {
          Text($r('app.string.model_select'))
            .fontColor($r('app.color.list_item_text_primary'))
            .padding({ left: 8 })
          Blank()
          Select(this.siliconflowStorage.selectedArray)
            .selected($$this.siliconflowStorage.selectedNumber)
            .value($$this.siliconflowStorage.modelName)
            .backgroundColor(Color.Transparent)
            .onSelect((index: number, text?: string | undefined) => {
              Logger.info(TAG, 'Select: ' + index + 'model name ' + text)
              this.siliconflowStorage.selectedNumber = index;
              if (text) {
                this.siliconflowStorage.modelName = text;
                PreferenceModel.writeData(this.siliconflowStorage.modelName, 'siliconflow_setting', 'modelSelected');
              }
            })
        }
        .backgroundColor($r('app.color.item_button_background'))
        .padding({ left: 8, right: 8 })
        .margin({ left: 8 })
        .borderRadius(16)
        .width('100%')
        .height(56)
      }
      .padding({ left: 16, right: 16 })
    }
    .padding({ top: this.avoidArea.topRectHeight + 'px', bottom: this.avoidArea.bottomRectHeight + 'px' })
    .backgroundColor($r('sys.color.ohos_id_color_panel_bg'))
    .width('100%')
    .height('100%')
  }
}
