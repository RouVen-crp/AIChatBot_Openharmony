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

import { WebSearchManager } from "../web/WebSearchManager";
import { common, ConfigurationConstant } from "@kit.AbilityKit";
import PreferenceModel from "../preference/PreferenceModel";
import { setAutoColorMode, setDarkColorMode, setLightColorMode } from "../utils/ThemeColorChange";
import { AppStorageV2 } from "@kit.ArkUI";
import { AvoidArea } from "../model/layout/AvoidData";
import { NormalTitle } from "../component/NormalTitle";
import { VoiceSettings } from "../model/setting/VoiceSettings";
import Logger from "../utils/Logger";

const TAG = '[Normal_Setting]'

@Builder
export function normalSettingBuilder(name: string, param: Object) {
  NormalSettingComponent();
}

@Entry
@ComponentV2
struct NormalSettingComponent {
  pageInfos: NavPathStack = new NavPathStack();
  webSearchManager: WebSearchManager = WebSearchManager.getInstance();
  themeArray: Array<SelectOption> =
    [{ value: $r('app.string.system_theme') },
      { value: $r('app.string.dark_theme') },
      { value: $r('app.string.light_theme') }]
  @Local selectedNumber: number = -1;
  @Local themeColor: ResourceStr = '';
  private context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
  @Local avoidArea: AvoidArea = AppStorageV2.connect(AvoidArea, 'AvoidArea', () => new AvoidArea())!;
  @Local voiceSettings: VoiceSettings =
    AppStorageV2.connect(VoiceSettings, 'VoiceSettings', () => new VoiceSettings())!;

  aboutToAppear(): void {
    let colormode = Number(PreferenceModel.getData('normal_setting', 'colormode'));
    if (colormode === ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET) {
      this.selectedNumber = 0
      this.themeColor = this.themeArray[0].value
    } else if (colormode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK) {
      this.selectedNumber = 1
      this.themeColor = this.themeArray[1].value
    } else {
      this.selectedNumber = 2
      this.themeColor = this.themeArray[2].value
    }
    Logger.info(TAG, `${JSON.stringify(this.avoidArea)}`);
  }

  @Styles
  rowStyles() {
    .backgroundColor($r('app.color.item_button_background'))
    .padding({ left: 8, right: 8 })
    .borderRadius(16)
    .width('100%')
    .height(56)
  }

  build() {
    Column() {
      NormalTitle()
      Column({ space: 10 }) {
        Row({ space: 12 }) {
          Text($r('app.string.dark_theme_select'))
            .fontColor($r('app.color.list_item_text_primary'))
          Blank()
          Select(this.themeArray)
            .selected($$this.selectedNumber)
            .value($$this.themeColor)
            .backgroundColor(Color.Transparent)
            .onSelect((index: number, text?: string | undefined) => {
              this.selectedNumber = index;
              if (index === 0) {
                setAutoColorMode(this.context);
              } else if (index === 1) {
                setDarkColorMode(this.context);
              } else {
                setLightColorMode(this.context);
              }
              if (text) {
                this.themeColor = text;
              }
            })
        }
        .rowStyles()

        Row({ space: 12 }) {
          Text($r('app.string.speech_speed'))
            .fontColor($r('app.color.list_item_text_primary'))
          // 语速调节
          Slider({
            value: this.voiceSettings.speed,
            min: 0.5,
            max: 1.5,
            step: 0.1
          })
            .layoutWeight(1)
            .showSteps(true)
            .onChange((value: number, mode: SliderChangeMode) => {
              this.voiceSettings.speed = value;
              Logger.info(TAG, 'value:' + value + 'mode:' + mode.toString());
            })
          Text(this.voiceSettings.speed.toFixed(1))
            .fontColor($r('app.color.list_item_text_primary'))
        }
        .rowStyles()
      }
      .padding({ left: 16, right: 16 })
    }
    .padding({ top: this.avoidArea.topRectHeight + 'px', bottom: this.avoidArea.bottomRectHeight + 'px' })
    .backgroundColor($r('sys.color.ohos_id_color_panel_bg'))
    .width('100%')
    .height('100%')
  }
}