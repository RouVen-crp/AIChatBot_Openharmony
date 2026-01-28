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

import { settingInfo, settingRouterGroup, SupplierSettingArray } from "../model/SettingRouterModel"
import { AppStorageV2, promptAction, router, TextModifier } from "@kit.ArkUI";
import { AvoidArea } from "../model/layout/AvoidData";
import { NormalTitle } from "../component/NormalTitle";

const TAG = '[provider_setting]'

class MainTitleTextModfier extends TextModifier {
  applyNormalAttribute(instance: TextModifier): void {
    instance.fontColor(Color.Black)
    instance.fontSize(20)
    instance.heightAdaptivePolicy(TextHeightAdaptivePolicy.MIN_FONT_SIZE_FIRST)
    instance.fontWeight(FontWeight.Medium)
  }
}

@Builder
export function providerSettingBuilder(name: string, param: Object) {
  ProviderSetting();
}

@Entry
@ComponentV2
struct ProviderSetting {
  @Local mainTitleModifier: MainTitleTextModfier = new MainTitleTextModfier();
  @Local avoidArea: AvoidArea = AppStorageV2.connect(AvoidArea, 'AvoidArea', () => new AvoidArea())!;

  build() {
    Column() {
      NormalTitle()
      List({ space: 20 }) {
        ForEach(SupplierSettingArray, (item: settingRouterGroup) => {
          ListItemGroup({ style: ListItemGroupStyle.NONE }) {
            ForEach(item.routerArray, (value: settingInfo) => {
              ListItem() {
                Button({ type: ButtonType.Normal }) {
                  Row() {
                    Image(value.image)
                      .size({ height: 24, width: 24 })
                      .fillColor($r('app.color.list_item_icon'))
                    Text(value.title)
                      .fontSize(16)
                      .fontWeight(FontWeight.Medium)
                      .margin({ left: 16 })
                      .fontColor($r('app.color.list_item_text_primary'))

                    Blank()
                      .layoutWeight(1)
                    Button() {
                      Image($r('app.media.ic_public_arrow_right'))
                        .size({ width: 12, height: 24 })
                        .fillColor($r('app.color.list_item_icon'))
                    }
                    .backgroundColor(Color.Transparent)
                    .size({ width: 12, height: 24 })
                    .type(ButtonType.Normal)
                  }
                  .justifyContent(FlexAlign.Start)
                  .alignItems(VerticalAlign.Center)
                  .margin({ left: 4, right: 4 })
                }
                .backgroundColor($r('app.color.item_button_background'))
                .borderRadius(16)
                .height(56)
                .margin({ left: 4, right: 4 })
                .onClick(() => {
                  if (!value.url) {
                    promptAction.showToast({ message: '施工中' });
                    return;
                  }
                  router.pushUrl({url: value.url})
                })
              }
            })
          }
          .backgroundColor($r('app.color.list_itemgroup_background'))
          .padding({ top: 4, bottom: 4 })
          .divider({ strokeWidth: 0.5, startMargin: 64, endMargin: 16 })
          .borderRadius(16)
        })
      }
      .borderRadius(16)
      .padding({
        left: 16,
        right: 16,
        top: 8,
        bottom: 8
      })
    }
    .padding({ top: this.avoidArea.topRectHeight + 'px', bottom: this.avoidArea.bottomRectHeight + 'px' })
    .backgroundColor($r('sys.color.ohos_id_color_panel_bg'))
    .width('100%')
    .height('100%')
  }
}