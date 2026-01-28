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

// ============================================================================
// Core Request Types - 核心请求结构
// ============================================================================

import { messageInput } from "../../interfaces/inputMessage";

/**
 * 标准化的内部核心请求结构，用于所有AI Provider的统一处理
 * 这是应用层参数转换后的标准格式，不包含回调函数和控制逻辑
 */
export interface CompletionsParams {

  model: string;

  // 基础对话数据
  messages: Array<messageInput>; // 联合类型方便判断是否为空

  stream: boolean;
  // assistant: Assistant // 助手为基本单位

  onResponse?: (text: string, isComplete: boolean) => void

  // 错误相关
  onError?: (error: Error) => void

  // 生成参数
  temperature?: number
  topP?: number
  maxTokens?: number

  // 功能开关
  enableWebSearch?: boolean
  enableReasoning?: boolean
  includeImage?: boolean

  // 上下文控制
  contextCount?: number

}
