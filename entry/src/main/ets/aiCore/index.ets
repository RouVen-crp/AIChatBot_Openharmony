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

import { BaseApiClient } from "./clients/baseApiClient";
import { http } from "@kit.NetworkKit";
import { CompletionsParams } from "./middleware/schemas";
import { ProviderSetting, ProviderType } from "../interfaces";
import { ApiClientFactory } from "./clients/apiClientFactory";

// ================= 统一的AI提供者类 =================
export default class AiProvider {
  public apiClient: BaseApiClient;

  constructor(provider: ProviderType, config: ProviderSetting) {
    this.apiClient = ApiClientFactory.create(provider, config);
  }

  /**
   * 创建聊天完成
   * @param params 聊天参数
   * @returns 聊天响应
   */
  async createChatCompletion(
    params: CompletionsParams
  ): Promise<number> {
    return this.apiClient.createChatCompletion(params);
  }

  /**
   * 获取模型列表
   * @returns 模型信息数组
   */
  async listModels(): Promise<http.HttpResponse> {
    return this.apiClient.listModels();
  }


}