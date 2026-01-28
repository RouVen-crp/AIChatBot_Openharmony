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

import { ProviderSetting, ProviderType } from "../../interfaces";
import { BaseApiClient } from "./baseApiClient";
import { OllamaApiClient } from "./ollama/ollamaApiClient";
import { OpenAiApiClient } from "./openAI/openAiApiClient";
import { SiliconFlowApiClient } from "./siliconflow/siliconflowApiClient";

// ================= API客户端工厂 =================
export class ApiClientFactory {
  static create(provider: ProviderType, config: ProviderSetting): BaseApiClient {
    switch (provider) {
      case 'openai':
        return new OpenAiApiClient(config.baseURL, config.apiKey);
      case 'ollama':
        return new OllamaApiClient(config.baseURL);
      case 'siliconflow':
        return new SiliconFlowApiClient(config.baseURL, config.apiKey);
      // case 'llamacpp':
      //   return new LlamaCppApiClient(config.baseURL);
      default:
        throw new Error(`Unsupported provider: ${provider}`);
    }
  }
}