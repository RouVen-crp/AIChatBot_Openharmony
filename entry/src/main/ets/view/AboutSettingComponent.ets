/*
 * Copyright (c) 2025 Hunan OpenValley Digital Industry Development Co., Ltd.
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

import Constants from "../common/Constants";
import { AvoidArea } from "../model/layout/AvoidData";
import { AppStorageV2 } from "@kit.ArkUI";
import { NormalTitle } from "../component/NormalTitle";

const TAG = '[Normal_Setting]'

@Builder
export function aboutSettingBuilder(name: string, param: Object) {
  AboutSettingComponent();
}

@Entry
@ComponentV2
struct AboutSettingComponent {
  @Local avoidArea: AvoidArea = AppStorageV2.connect(AvoidArea, 'AvoidArea', () => new AvoidArea())!;

  build() {
    Column() {
      NormalTitle()
      Column({ space: 30 }) {
        Column({ space: 10 }) {
          Image($r('app.media.app_icon'))
            .width(64)
            .height(64)
            .borderRadius(8)
          Text($r('app.string.app_name'))
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
        }

        Column() {
          Row() {
            Column({ space: 2 }) {
              Text($r('app.string.version_information'))
                .fontSize(16)
                .fontColor($r('app.color.list_item_text_primary'))
              Text(Constants.APP_VERSION)
                .fontSize(14)
                .fontColor($r('app.color.list_item_text_secondary'))
            }
            .alignItems(HorizontalAlign.Start)
          }
          .width('100%')
          .padding({
            left: 8,
            right: 8,
            top: 16,
            bottom: 16
          })

        }
        .backgroundColor($r('app.color.item_button_background'))
        .borderRadius(16)
        .width('100%')
      }
      .padding({ left: 16, right: 16, top: 20 })
    }
    .padding({ top: this.avoidArea.topRectHeight + 'px', bottom: this.avoidArea.bottomRectHeight + 'px' })
    .backgroundColor($r('sys.color.ohos_id_color_panel_bg'))
    .width('100%')
    .height('100%')
  }
}