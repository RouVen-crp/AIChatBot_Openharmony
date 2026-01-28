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

export default class Constants {
  static readonly DEFAULT_OLLAMA_URL = "http://10.1.11.226:11434";
  static readonly DEFAULT_RAG_QUESTION_PROMPT =
    "Given the following conversation and a follow up question, rephrase the follow up question to be a standalone question.   Chat History: {chat_history} Follow Up Input: {question} Standalone question:";
  static readonly DEFAUTL_RAG_SYSTEM_PROMPT =
    `You are a helpful AI assistant. Use the following pieces of context to answer the question at the end. If you don't know the answer, just say you don't know. DO NOT try to make up an answer. If the question is not related to the context, politely respond that you are tuned to only answer questions that are related to the context.  {context}  Question: {question} Helpful answer:`;
  static readonly DEFAULT_WEBSEARCH_PROMP = `You are an AI model who is expert at searching the web and answering user's queries.

Generate a response that is informative and relevant to the user's query based on provided search results. the current date and time are {current_date_time}.

\`search-results\` block provides knowledge from the web search results. You can use this information to generate a meaningful response.

<search-results>
 {search_results}
</search-results>
`;
  static readonly DEFAULT_WEBSEARCH_FOLLOWUP_PROMPT = `You will give a follow-up question.  You need to rephrase the follow-up question if needed so it is a standalone question that can be used by the AI model to search the internet.
Example:

Follow-up question: What are the symptoms of a heart attack?

Rephrased question: Symptoms of a heart attack.

Follow-up question: Where is the upcoming Olympics being held?

Rephrased question: Location of the upcoming Olympics.

Follow-up question: Taylor Swift's latest album?

Rephrased question: Name of Taylor Swift's latest album.


Previous Conversation:

{chat_history}

Follow-up question: {question}

Rephrased question:
`;
  static readonly NEW_CONVERSATION_NAME = '新对话';
  static readonly CLICK_ADD_CONVERSATION = '点击开始新对话';
  static readonly INIT_WEB_ENGINE_ERROR = '搜索引擎未初始化';
  static readonly UNDEFINED_WEB_ENGINE_ERROR = '未知的搜索引擎:';
  static readonly APP_VERSION = '1.0.0';
  // 节流持续时间
  static readonly THROTTLE_DURATION: number = 8000;
}

// 输入模式
export enum InputMode {
  // 文本输入
  TEXT_INPUT,
  // 语音输入
  VOICE_INPUT,
}
