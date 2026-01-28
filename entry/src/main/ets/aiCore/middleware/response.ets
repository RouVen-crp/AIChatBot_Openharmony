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

export interface responseOpenAiCompatible {

  id: string;

  object: string;

  created: number;

  model: string;

  choices: Array<responseChoices>;

  system_fingerprint: string;

  usage: responseUsage;

}

export interface responseChoices {

  index: number;

  delta: responseDelta;

  finish_reason: string | null;
}

export interface responseDelta {

  content: string | null;

  reasoning_content: string | null;

}

export interface responseUsage {

  prompt_tokens: number;

  completion_tokens: number;

  total_tokens: number;

}