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

import { Metrics, Model, Usage, WebSearchResponse } from "."

export enum MessageBlockType {
  UNKNOWN = 'unknown', // 未知类型，用于返回之前
  MAIN_TEXT = 'main_text', // 主要文本内容
  THINKING = 'thinking', // 思考过程（Claude、OpenAI-o系列等）
  TRANSLATION = 'translation', // Re-added
  IMAGE = 'image', // 图片内容
  CODE = 'code', // 代码块
  TOOL = 'tool', // Added unified tool block type
  FILE = 'file', // 文件内容
  ERROR = 'error', // 错误信息
  CITATION = 'citation' // 引用类型 (Now includes web search, grounding, etc.)
}

// 块状态定义
export enum MessageBlockStatus {
  PENDING = 'pending', // 等待处理
  PROCESSING = 'processing', // 正在处理，等待接收
  STREAMING = 'streaming', // 正在流式接收
  SUCCESS = 'success', // 处理成功
  ERROR = 'error', // 处理错误
  PAUSED = 'paused' // 处理暂停
}

// 主文本块 - 核心内容
export interface MainTextMessageBlock extends BaseMessageBlock {
  type: MessageBlockType.MAIN_TEXT
  content: string
  knowledgeBaseIds?: string[]
}

// 思考块 - 模型推理过程
export interface ThinkingMessageBlock extends BaseMessageBlock {
  type: MessageBlockType.THINKING
  content: string
  thinking_millsec?: number
}

// BaseMessageBlock 基础类型 - 更简洁，只包含必要通用属性
export interface BaseMessageBlock {
  id: string // 块ID
  messageId: string // 所属消息ID
  type: MessageBlockType // 块类型
  createdAt: string // 创建时间
  updatedAt?: string // 更新时间
  status: MessageBlockStatus // 块状态
  model?: Model // 使用的模型
  metadata?: Record<string, ESObject> // 通用元数据
  error?: Record<string, ESObject> // Added optional error field to base
}

export type MessageBlock =
    | MainTextMessageBlock
    | ThinkingMessageBlock


// Message 核心类型 - 包含元数据和块集合
export interface Message {
  id: string;
  role: 'user' | 'assistant' | 'system';
  assistantId: string;
  topicId: string;
  createdAt: string;
  updatedAt?: string;
  status: UserMessageStatus | AssistantMessageStatus;
  // 消息元数据
  modelId?: string;
  model?: Model;
  type?: 'clear';
  useful?: boolean;
  askId?: string; // 关联的问题消息ID
  mentions?: Model[];
  usage?: Usage;
  metrics?: Metrics;
  // UI相关
  multiModelMessageStyle?: 'horizontal' | 'vertical' | 'fold' | 'grid';
  foldSelected?: boolean;
  // 块集合
  blocks: MessageBlock[];
}

export enum UserMessageStatus {
  SUCCESS = 'success'
}

export enum AssistantMessageStatus {
  PROCESSING = 'processing',
  PENDING = 'pending',
  SEARCHING = 'searching',
  SUCCESS = 'success',
  PAUSED = 'paused',
  ERROR = 'error'
}

export interface Response {
  text?: string
  reasoning_content?: string
  usage?: Usage
  metrics?: Metrics
  webSearch?: WebSearchResponse
  error?: ResponseError
}

export type ResponseError = Record<string, ESObject>

