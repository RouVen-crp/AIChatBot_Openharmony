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

import { Message } from "./newMessage";

export interface Assistant {
  id: string;
  name: string;
  prompt: string;
  topics: Topic[];
  type: string;
  emoji?: string;
  description?: string;
  model?: Model;
  defaultModel?: Model;
  messages?: AssistantMessage[];
  /** enableWebSearch 代表使用模型内置网络搜索功能 */
  enableWebSearch?: boolean;
  enableGenerateImage?: boolean;
  tags?: string[]; // 助手标签
}

export interface AssistantMessage {
  role: 'user' | 'assistant';
  content: string;
}

export interface Topic {
  id: string;
  assistantId: string;
  name: string;
  createdAt: string;
  updatedAt: string;
  messages: Message[];
  pinned?: boolean;
  prompt?: string;
  isNameManuallyEdited?: boolean;
}

export interface Provider {
  id: string;
  type: ProviderType;
  name: string;
  apiKey: string;
  apiHost: string;
  apiVersion?: string;
  models: Model[];
  enabled?: boolean;
  isSystem?: boolean;
  isAuthed?: boolean;
  rateLimit?: number;
  isNotSupportArrayContent?: boolean;
  isVertex?: boolean;
  notes?: string;
}

export type ProviderType =
    | 'openai'
    | 'ollama'
    | 'siliconflow'
    | 'llamacpp'

export interface ProviderSetting {
  baseURL: string;
  apiKey?: string | undefined;
}

export type ModelType = 'text' | 'vision' | 'embedding' | 'reasoning' | 'function_calling' | 'web_search'

export interface Model {
  id: string;
  provider: string;
  name: string;
  group: string;
  owned_by?: string;
  description?: string;
  type?: ModelType[];
  pricing?: ModelPricing;
}

export interface SystemModelsList {
  defaultModel: Model[];
  o3: Model[];
  ollama: Model[];
  lmstudio: Model[];
  silicon: Model[];
  openai: Model[];
  giteeai: Model[];
  deepseek: Model[];
  github: Model[];
  modelscope: Model[];
  copilot: Model[];
  doubao: Model[];
  nvidia: Model[];
}

export interface ModelPricing {
  input_per_million_tokens: number;
  output_per_million_tokens: number;
  currencySymbol?: string;
}

export interface Metrics {
  completion_tokens: number;
  time_completion_millsec: number;
  time_first_token_millsec?: number;
  time_thinking_millsec?: number;
}

export interface FileType {
  id: string
  name: string
  origin_name: string
  path: string
  size: number
  ext: string
  type: FileTypes
  created_at: string
  count: number
  tokens?: number
}

export enum FileTypes {
  IMAGE = 'image',
  VIDEO = 'video',
  AUDIO = 'audio',
  TEXT = 'text',
  DOCUMENT = 'document',
  OTHER = 'other'
}

export interface Usage {
  prompt_tokens: number ;
  completion_tokens: number;
  total_tokens: number ;
}

export interface WebSearchProvider {
  id: string;
  name: string;
  apiKey?: string;
  apiHost?: string;
  engines?: string[];
  url?: string;
  basicAuthUsername?: string;
  basicAuthPassword?: string;
  contentLimit?: number;
  usingBrowser?: boolean;
}

export interface WebSearchProviderResult {
  title: string;
  content: string;
  url: string;
}

export interface WebSearchProviderResponse {
  query?: string;
  results: WebSearchProviderResult[];
}

export type WebSearchResults =
  | WebSearchProviderResponse
    | ESObject[]

export enum WebSearchSource {
  WEBSEARCH = 'websearch'
}

export interface WebSearchResponse {
  results?: WebSearchResults;
  source: WebSearchSource;
}