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
import { ITransport, TransportConfig, RequestOptions, TransportResponse } from "../ITransport";

/**
 * HTTP传输层实现
 * 基于@kit.NetworkKit的http模块实现，迁移自原有OllamaApiClient的HTTP通信逻辑
 */
export class HttpTransport implements ITransport {
  private httpRequest: http.HttpRequest;
  private baseURL: string = '';
  private connected: boolean = false;

  constructor() {
    this.httpRequest = http.createHttp();
  }

  /**
   * 连接到HTTP服务（设置baseURL）
   */
  async connect(config: TransportConfig): Promise<boolean> {
    if (config.baseURL) {
      this.baseURL = config.baseURL;
      this.connected = true;
      console.info(`[HttpTransport] Connected to: ${this.baseURL}`);
      return true;
    }
    console.warn(`[HttpTransport] Failed to connect: baseURL is empty`);
    return false;
  }

  /**
   * 断开连接
   */
  disconnect(): void {
    this.connected = false;
    this.baseURL = '';
  }

  /**
   * 发送流式请求
   */
  async sendStreamRequest(endpoint: string, options: RequestOptions): Promise<number> {
    const url = this.baseURL + endpoint;
    console.info(`[HttpTransport] Sending stream request to: ${url}, endpoint: ${endpoint}, baseURL: ${this.baseURL}`);
    const headers: Record<string, string> = {
      "accept": "application/json",
      "Content-Type": "application/json"
    };
    if (options.headers) {
      const headerKeys = Object.keys(options.headers);
      for (let i = 0; i < headerKeys.length; i++) {
        const key = headerKeys[i];
        headers[key] = options.headers[key];
      }
    }

    const promise = this.httpRequest.requestInStream(url, {
      method: options.method === 'POST' ? http.RequestMethod.POST : http.RequestMethod.GET,
      header: headers,
      extraData: options.data ? JSON.stringify(options.data) : undefined,
      readTimeout: options.readTimeout ?? 180000,
      connectTimeout: options.connectTimeout ?? 180000
    });

    return promise;
  }

  /**
   * 发送普通请求
   */
  async sendRequest(endpoint: string, options: RequestOptions): Promise<TransportResponse> {
    const url = this.baseURL + endpoint;
    const headers: Record<string, string> = {
      "Content-Type": "application/json"
    };
    if (options.headers) {
      const headerKeys = Object.keys(options.headers);
      for (let i = 0; i < headerKeys.length; i++) {
        const key = headerKeys[i];
        headers[key] = options.headers[key];
      }
    }

    const response = await this.httpRequest.request(url, {
      method: options.method === 'POST' ? http.RequestMethod.POST : http.RequestMethod.GET,
      header: headers,
      extraData: options.data ? JSON.stringify(options.data) : undefined,
      readTimeout: options.readTimeout ?? 180000,
      connectTimeout: options.connectTimeout ?? 180000
    });

    return {
      responseCode: response.responseCode,
      result: response.result as string
    };
  }

  /**
   * 注册数据接收回调
   */
  onDataReceive(callback: Callback<ArrayBuffer>): void {
    this.httpRequest.on('dataReceive', (data: ArrayBuffer) => {
      callback(data);
    });
  }

  /**
   * 取消数据接收回调
   */
  offDataReceive(): void {
    this.httpRequest.off('dataReceive');
  }

  /**
   * 获取连接状态
   */
  isConnected(): boolean {
    return this.connected;
  }

  /**
   * 销毁传输层实例
   */
  destroy(): void {
    this.httpRequest.destroy();
    this.connected = false;
  }
}
