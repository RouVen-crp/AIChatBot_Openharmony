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

import { http } from "@kit.NetworkKit";
import { CompletionsParams } from "../middleware/schemas";


// 基础API客户端接口
export interface BaseApiClient {

  createChatCompletion(params: CompletionsParams): Promise<number>;

  listModels(): Promise<http.HttpResponse>;

  onDataReceive(dataCallback: Callback<ArrayBuffer>): void;

  offDataReceive(): void;

  destroy(): void;
}