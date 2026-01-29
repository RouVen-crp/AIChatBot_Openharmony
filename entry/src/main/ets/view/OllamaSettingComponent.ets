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

import { AppStorageV2, promptAction, router, SelectOptions } from "@kit.ArkUI"
import PreferenceModel from "../preference/PreferenceModel"
import { OllamaStorage } from "../model/setting/OllamaStorage"
import { AvoidArea } from "../model/layout/AvoidData"
import { NormalTitle } from "../component/NormalTitle"
import Logger from "../utils/Logger";
import { Provider, ProviderSetting } from "../interfaces";
import { ProviderStorage } from "../model/setting/ProviderStorage";
import { TransportType } from "../transport/ITransport";

const regex: RegExp = new RegExp('^((2[0-4]\\d|25[0-5]|[01]?\\d\\d?)\\.){3}(2[0-4]\\d|25[0-5]|[01]?\\d\\d?)$')
const portRegex: RegExp =
  new RegExp('^(?:[1-9][0-9]{0,3}|[1-5][0-9]{4}|6[0-4][0-9]{3}|65[0-4][0-9]{2}|655[0-2][0-9]|6553[0-5])$')

const TAG = '[ollama_setting_component]'

// 传输类型选项
const TRANSPORT_OPTIONS: SelectOption[] = [
  { value: 'HTTP' },
  { value: '软总线' }
];

@Builder
export function ollamaSettingBuilder(name: string, param: Object) {
  OllamaSettingComponent()
}

@Entry
@ComponentV2
struct OllamaSettingComponent {
  portController: TextInputController = new TextInputController();
  @Local modelArray: string[] = [];
  @Local avoidArea: AvoidArea = AppStorageV2.connect(AvoidArea, 'AvoidArea', () => new AvoidArea())!;
  @Local ollamaStorage: OllamaStorage = AppStorageV2.connect(OllamaStorage, 'OllamaStorage', () => new OllamaStorage())!;
  @Local providerStorage: ProviderStorage = AppStorageV2.connect(ProviderStorage, 'ProviderStorage', () => new ProviderStorage())!;
  @Local transportSelectedIndex: number = 0;

  aboutToAppear(): void {
    // 初始化传输类型选择索引
    this.transportSelectedIndex = this.ollamaStorage.transportType === 'softbus' ? 1 : 0;
  }

  regText(testStr: string): boolean {
    return regex.test(testStr);
  }

  portText(testStr: string): boolean {
    return portRegex.test(testStr);
  }

  onTransportTypeChange(index: number): void {
    const newType: TransportType = index === 1 ? 'softbus' : 'http';
    this.ollamaStorage.transportType = newType;
    PreferenceModel.writeData(newType, 'ollama_setting', 'transportType');
    Logger.info(TAG, `Transport type changed to: ${newType}`);
  }


  build() {
    Column() {
      NormalTitle();
      Column({ space: 10 }) {
        Column() {
          Row({ space: 12 }) {
            Text($r('app.string.title_setting_ollama'))
              .fontColor($r('app.color.list_item_text_primary'))
              .fontWeight(FontWeight.Bold)
            Blank()
            Toggle({type: ToggleType.Switch, isOn: this.providerStorage.currentProvider === '0' ? true : false})
              .onChange((isOn: boolean) =>{
                this.ollamaStorage.isToggleOn = isOn;
                if(this.ollamaStorage.isToggleOn ){
                  this.providerStorage.currentProvider = '0';
                  PreferenceModel.writeData('0', 'provider_setting', 'providerSelected');
                }else{
                  PreferenceModel.writeData('-1', 'provider_setting', 'providerSelected');
                }
              })
          }
          .padding({ left: 8, right: 8 })
          .width('100%')
          .height(56)

          Divider();

          // 传输模式选择
          Row({ space: 12 }) {
            Text($r('app.string.transport_mode_select'))
              .fontColor($r('app.color.list_item_text_primary'))
            Blank()
            Select(TRANSPORT_OPTIONS)
              .selected(this.transportSelectedIndex)
              .value(this.transportSelectedIndex === 0 ? 'HTTP' : '软总线')
              .backgroundColor(Color.Transparent)
              .onSelect((index: number) => {
                this.transportSelectedIndex = index;
                this.onTransportTypeChange(index);
              })
          }
          .padding({ left: 8, right: 8 })
          .width('100%')
          .height(56)

          Divider();

          // HTTP模式配置
          if (this.ollamaStorage.transportType === 'http') {
            Button({ type: ButtonType.Normal }) {
              Row() {
                Text($r('app.string.title_ollama_url'))
                  .fontColor($r('app.color.list_item_text_primary'))
                Blank()
                if (this.ollamaStorage.ipConfig !== '' && this.ollamaStorage.portConfig !== '') {
                  Text(this.ollamaStorage.ipConfig + ':' + this.ollamaStorage.portConfig)
                }
                Image($r('app.media.ic_public_arrow_right'))
                  .size({ width: 12, height: 24 })
                  .fillColor($r('app.color.list_item_icon'))
              }.width('100%')
            }
            .padding({ left: 8, right: 8 })
            .borderRadius(16)
            .width('100%')
            .height(56)
            .backgroundColor($r('app.color.item_button_background'))
            .onClick(() => {
              router.pushUrl({ url: 'view/OllamaUrlInput' })
            })
          }

          // 软总线模式配置
          if (this.ollamaStorage.transportType === 'softbus') {
            Button({ type: ButtonType.Normal }) {
              Row() {
                Text($r('app.string.softbus_device_discovery'))
                  .fontColor($r('app.color.list_item_text_primary'))
                Blank()
                if (this.ollamaStorage.isSoftBusConnected && this.ollamaStorage.selectedDeviceName) {
                  Text(this.ollamaStorage.selectedDeviceName)
                    .fontColor($r('sys.color.ohos_id_color_primary'))
                } else {
                  Text('未连接')
                    .fontColor($r('app.color.list_item_text_secondary'))
                }
                Image($r('app.media.ic_public_arrow_right'))
                  .size({ width: 12, height: 24 })
                  .fillColor($r('app.color.list_item_icon'))
              }.width('100%')
            }
            .padding({ left: 8, right: 8 })
            .borderRadius(16)
            .width('100%')
            .height(56)
            .backgroundColor($r('app.color.item_button_background'))
            .onClick(() => {
              router.pushUrl({ url: 'view/SoftBusDeviceSelector' })
            })

            // 软总线说明
            Text('注意：软总线功能需要在真机上运行，模拟器不支持。\n请确保两台设备登录同一华为账号且处于同一局域网。')
              .fontSize(12)
              .fontColor($r('app.color.list_item_text_secondary'))
              .width('100%')
              .padding({ left: 8, right: 8, top: 8 })
              .lineHeight(18)
          }
        }

        Row({ space: 12 }) {
          Text($r('app.string.model_select'))
            .fontColor($r('app.color.list_item_text_primary'))
          Blank()
          Select(this.ollamaStorage.selectedArray)
            .selected($$this.ollamaStorage.selectedNumber)
            .value($$this.ollamaStorage.modelName)
            .backgroundColor(Color.Transparent)
            .onSelect((index: number, text?: string | undefined) => {
              Logger.info(TAG, 'Select: ' + index + 'model name ' + text)
              this.ollamaStorage.selectedNumber = index;
              if (text) {
                this.ollamaStorage.modelName = text;
                PreferenceModel.writeData(this.ollamaStorage.modelName, 'ollama_setting', 'modelSelected');
              }
            })
        }
        .backgroundColor($r('app.color.item_button_background'))
        .padding({ left: 8, right: 8 })
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
