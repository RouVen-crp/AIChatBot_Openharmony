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

@ObservedV2
export class SiliconflowStorage {
  @Trace apiKey: string = '';
  @Trace chatModelUrl: string = 'https://api.siliconflow.cn/v1/models?type=text&sub_type=chat';
  @Trace baseUrl: string = 'https://api.siliconflow.cn/v1';
  @Trace chatRequestUrl: string = 'https://api.siliconflow.cn/v1/chat/completions';
  @Trace selectedArray: Array<SelectOption> = [];
  @Trace selectedNumber: number = 0;
  @Trace modelName: string = "";
  @Trace isConnect: boolean = false;
  @Trace isToggleOn: boolean = false;
}