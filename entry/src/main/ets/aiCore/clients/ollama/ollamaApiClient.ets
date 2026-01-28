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
import { CompletionsParams } from "../../middleware/schemas";
import { BaseApiClient } from "../baseApiClient";


// OPEN AI API客户端接口
export class OllamaApiClient implements BaseApiClient{
  httpRequest: http.HttpRequest;
  baseURL: string;

  constructor(baseURL: string) {
    this.httpRequest = http.createHttp();
    this.baseURL = baseURL;
  }

  public createChatCompletion(params: CompletionsParams): Promise<number>{
    let promise = this.httpRequest.requestInStream(this.baseURL+"/v1/chat/completions", {
      method: http.RequestMethod.POST,
      header: {
        "accept": "application/json",
        "Content-Type": "application/json"
      },
      extraData: JSON.stringify(params),
      readTimeout: 180000,
      connectTimeout: 180000
    });
    return promise
  }

  public listModels(): Promise<http.HttpResponse> {
    let promise = this.httpRequest.request(this.baseURL+"/api/tags", {
      method: http.RequestMethod.GET,
      header: [{
        "Content-Type": 'application/json'
      }],
      readTimeout: 180000,
      connectTimeout: 180000
    });
    return promise;
  }

  public onDataReceive(dataCallback: Callback<ArrayBuffer>) {
    this.httpRequest.on('dataReceive', (data: ArrayBuffer) => {
      dataCallback(data);
    })
  }

  public offDataReceive() {
    this.httpRequest.off('dataReceive');
  }

  public destroy() {
    this.httpRequest.destroy();
  }
}