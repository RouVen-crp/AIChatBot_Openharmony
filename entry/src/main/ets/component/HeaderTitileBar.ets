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
import { promptAction } from "@kit.ArkUI";
import { common } from "@kit.AbilityKit";

@ComponentV2
export default struct HeaderTitleBar {
  @Param chatTitle: string = Constants.NEW_CONVERSATION_NAME
  @Consumer('isShowSideBar') isShowSideBar: boolean = false;
  @Consumer('opacityOverlay') opacityOverlay: number = 0;
  @Param @Require onClickOK?: () => void;

  build() {
    Column() {
      Row() {
        Image($r("app.media.ic_public_sort"))
          .width(30)
          .height(30)
          .margin({ left: 10 })
          .fillColor($r('app.color.header_bar_icon'))
          .onClick(() => {
            animateTo({
              duration: 300,
              curve: Curve.Smooth
            }, () => {
              this.isShowSideBar = true;
              this.opacityOverlay = 0.2;
            })
          })
        Text(this.chatTitle)
          .alignSelf(ItemAlign.Center)
          .fontSize(16)
          .maxLines(1)
          .fontColor($r('app.color.header_bar_text'))
        Image($r("app.media.ic_public_new_chat"))
          .width(30)
          .height(30)
          .margin({ right: 10 })
          .fillColor($r('app.color.header_bar_icon'))
          .onClick(() => {
            const context = getContext(this) as common.UIAbilityContext
            if (this.onClickOK) {
              if(this.chatTitle === context.resourceManager.getStringSync($r('app.string.new_conversation'))){
                promptAction.showToast({
                  message: $r('app.string.already_in_conversation'),
                  bottom: 300
                })
              } else{
                this.onClickOK();
              }
            }
          })
      }
      .width("100%")
      .justifyContent(FlexAlign.SpaceBetween)
      .alignItems(VerticalAlign.Center)
    }.width("100%")
    .backgroundColor($r('sys.color.ohos_id_color_background'))
    .margin({ top: 5, bottom: 10 })
  }
}