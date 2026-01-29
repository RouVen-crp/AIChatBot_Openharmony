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
import { ITransport, TransportType, TransportConfig } from "../../../transport/ITransport";
import { TransportFactory } from "../../../transport/TransportFactory";

/**
 * Ollama API客户端
 * 支持HTTP和软总线两种传输方式
 */
export class OllamaApiClient implements BaseApiClient {
  private transport: ITransport;
  private transportType: TransportType;
  private baseURL: string;
  private deviceId?: string;

  /**
   * 构造函数
   * @param baseURL 基础URL（HTTP模式）或设备标识
   * @param transportType 传输类型，默认为HTTP
   * @param deviceId 设备ID（软总线模式）
   */
  constructor(baseURL: string, transportType: TransportType = 'http', deviceId?: string) {
    this.baseURL = baseURL;
    this.transportType = transportType;
    this.deviceId = deviceId;
    this.transport = TransportFactory.create(transportType);

    // 初始化连接
    this.initTransport();
  }

  /**
   * 初始化传输层连接
   */
  private async initTransport(): Promise<void> {
    const config: TransportConfig = {
      type: this.transportType,
      baseURL: this.baseURL,
      deviceId: this.deviceId
    };

    try {
      await this.transport.connect(config);
    } catch (error) {
      console.error('OllamaApiClient: Failed to initialize transport:', error);
    }
  }

  /**
   * 创建聊天完成请求（流式）
   */
  public createChatCompletion(params: CompletionsParams): Promise<number> {
    return this.transport.sendStreamRequest("/v1/chat/completions", {
      method: 'POST',
      headers: {
        "accept": "application/json",
        "Content-Type": "application/json"
      },
      data: params,
      readTimeout: 180000,
      connectTimeout: 180000
    });
  }

  /**
   * 获取模型列表
   */
  public async listModels(): Promise<http.HttpResponse> {
    const response = await this.transport.sendRequest("/api/tags", {
      method: 'GET',
      headers: {
        "Content-Type": "application/json"
      },
      readTimeout: 180000,
      connectTimeout: 180000
    });

    // 转换为http.HttpResponse兼容格式
    return {
      responseCode: response.responseCode,
      result: response.result,
      header: {},
      cookies: '',
      resultType: http.HttpDataType.STRING,
      performanceTiming: {
        dnsTiming: 0,
        tcpTiming: 0,
        tlsTiming: 0,
        firstSendTiming: 0,
        firstReceiveTiming: 0,
        totalFinishTiming: 0,
        redirectTiming: 0,
        responseHeaderTiming: 0,
        responseBodyTiming: 0,
        totalTiming: 0
      }
    } as http.HttpResponse;
  }

  /**
   * 注册数据接收回调
   */
  public onDataReceive(dataCallback: Callback<ArrayBuffer>): void {
    this.transport.onDataReceive(dataCallback);
  }

  /**
   * 取消数据接收回调
   */
  public offDataReceive(): void {
    this.transport.offDataReceive();
  }

  /**
   * 销毁客户端
   */
  public destroy(): void {
    this.transport.destroy();
  }

  /**
   * 获取当前传输类型
   */
  public getTransportType(): TransportType {
    return this.transportType;
  }

  /**
   * 检查是否已连接
   */
  public isConnected(): boolean {
    return this.transport.isConnected();
  }

  /**
   * 切换传输类型
   * @param transportType 新的传输类型
   * @param config 新的配置
   */
  public async switchTransport(transportType: TransportType, config: TransportConfig): Promise<boolean> {
    // 销毁旧的传输层
    this.transport.destroy();

    // 创建新的传输层
    this.transportType = transportType;
    this.transport = TransportFactory.create(transportType);

    // 更新配置
    if (config.baseURL) {
      this.baseURL = config.baseURL;
    }
    if (config.deviceId) {
      this.deviceId = config.deviceId;
    }

    // 连接
    return await this.transport.connect(config);
  }
}