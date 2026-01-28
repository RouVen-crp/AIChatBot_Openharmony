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

import { CompletionsParams } from "../aiCore/middleware/schemas"
import Constants from "../common/Constants"
import { blockUi } from "../interfaces/blockUi"

export class responseReturn {
  model: string = ""
  created_at: string = ""
  message: messageReturn = new messageReturn()
  done: boolean = false
  done_reason?: string = ""
  total_duration?: number = 0
  load_duration?: number = 0
  prompt_eval_count?: number = 0
  prompt_eval_duration?: number = 0
  eval_count?: number = 0
  eval_duration?: number = 0
}

@ObservedV2
export class messageReturn {
  role: string = ""
  content: string = ""
}

export class MsgOutput {
  content: string = ""
}

@ObservedV2
export class MsgInput {
  model: string = "deepseek-r1:32b"
  messages: Array<messageReturn> = []
  stream: boolean = true
}

@ObservedV2
export class chatInput {
  @Trace isExpanded = true;
  @Trace role: string = ""
  @Trace isReceiveSearch: boolean = true;
  @Trace is_expanded: boolean = false
  @Trace think_time: number = 0
  @Trace content: string = ""
  @Trace thinkingContent: string = ""
  @Trace isThinking: boolean = false

  constructor() {
  }
}

@ObservedV2
export class Conversation {
  id: number = 0;
  is_started_progress = false;
  title: string = Constants.NEW_CONVERSATION_NAME;
  lastMessage: string = '';
  timestamp: Date = new Date();
  @Trace msgArray: Array<blockUi> = [] || undefined;
  completionsParams: CompletionsParams = {
    model: "",
    stream: true,
    messages: []
  }

  constructor() {
  }
}