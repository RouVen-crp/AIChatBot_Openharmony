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

export interface settingInfo {
  title: ResourceStr;
  image: ResourceStr;
  url?: string;
}

export interface settingRouterGroup {
  type: string,
  routerArray: Array<settingInfo>
}

export const SettingRouterArray: Array<settingRouterGroup> = [
  {
    type: 'normal',
    routerArray: [
    {
      title: $r('app.string.title_setting_normal'),
      image: $r("app.media.ic_setting_normal"),
      url:'view/NormalSettingComponent'
    },
      {
        title: $r('app.string.supplier_setting'),
        image: $r('app.media.ic_model'),
        url: 'view/ProviderSettingComponent'
      }
    ]
  },
  {
    type: 'other',
    routerArray: [
      {
        title: $r('app.string.title_setting_about'),
        image: $r('app.media.ic_public_check_update'),
        url: 'view/AboutSettingComponent'
      }
    ]
  }
]

export const SupplierSettingArray: Array<settingRouterGroup> = [
  {
    type: 'normal',
    routerArray: [
      {
        title: $r('app.string.title_setting_ollama'),
        image: $r('app.media.ic_setting_ollama'),
        url: 'view/OllamaSettingComponent'
      },
      {
        title: $r('app.string.title_setting_siliconflow'),
        image: $r('app.media.ic_setting_ollama'),
        url: 'view/SiliconflowSettingComponent'
      }
    ]
  }
]