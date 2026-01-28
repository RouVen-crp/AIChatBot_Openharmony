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

import { http } from '@kit.NetworkKit';
import { MsgInput } from '../model/MessageOption';

const TAG = '[Http_class]';

export class Http {
  url: string;
  httpRequest: http.HttpRequest;
  option: http.HttpRequestOptions;

  constructor() {
    this.url = '';
    this.httpRequest = http.createHttp();
    this.option = {
      method: http.RequestMethod.GET, // 可选，默认为http.RequestMethod.GET。
      // 当使用POST请求时此字段用于传递请求体内容，具体格式与服务端协商确定。
      extraData: 'data to send',
      expectDataType: http.HttpDataType.STRING, // 可选，指定返回数据的类型。
      usingCache: true, // 可选，默认为true。
      priority: 1, // 可选，默认为1。
      // 开发者根据自身业务需要添加header字段。
      header: [{
        'Content-Type': 'application/json'
      }],
      readTimeout: 180000, // 可选，默认为60000ms。
      connectTimeout: 180000, // 可选，默认为60000ms。
      usingProtocol: http.HttpProtocol.HTTP1_1, // 可选，协议类型默认值由系统自动指定。
      usingProxy: false, //可选，默认不使用网络代理，自API 10开始支持该属性。
    };

  };

  setUrl(url: string) {
    this.url = url;
  }

  setOption(option: http.HttpRequestOptions) {
    this.option = option;
  }

  public onDataReceive(dataCallback: Callback<ArrayBuffer>) {
    this.httpRequest.on('dataReceive', (data: ArrayBuffer) => {
      dataCallback(data);
    })
  }

  public offDataReceive() {
    this.httpRequest.off('dataReceive');
  }

  public requestChatApi(input: MsgInput): Promise<number> {
    let promise = this.httpRequest.requestInStream(this.url, {
      method: http.RequestMethod.POST,
      header: [{
        'Content-Type': 'application/json'
      }],
      extraData: JSON.stringify(input),
      readTimeout: 180000,
      connectTimeout: 180000
    });
    return promise
  }

  public requestSiliconflowChatApi(input: MsgInput, token: string): Promise<number> {
    let promise = this.httpRequest.requestInStream(this.url, {
      method: http.RequestMethod.POST,
      header: {
        "accept": "application/json",
        "content-type": "application/json",
        'authorization': `Bearer ${token}`
      },
      extraData: JSON.stringify(input),
      readTimeout: 180000,
      connectTimeout: 180000
    });
    return promise
  }

  public requestSiliconflow(url: string, token: string): Promise<http.HttpResponse> {
    let promise = this.httpRequest.request(url, {
      method: http.RequestMethod.GET,
      header: {
        'Authorization': 'Bearer ' + token,
      },
      readTimeout: 180000,
      connectTimeout: 180000
    });
    return promise;
  }

  public request(url: string): Promise<http.HttpResponse> {
    let promise = this.httpRequest.request(url, {
      method: http.RequestMethod.GET,
      header: [{
        'Content-Type': 'application/json'
      }],
      readTimeout: 180000,
      connectTimeout: 180000
    });
    return promise;
  }

  public destroy() {
    this.httpRequest.destroy();
  }
}

export default new Http();