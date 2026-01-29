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

/**
 * 传输层类型定义
 */
export type TransportType = 'http' | 'softbus';

/**
 * 传输层配置接口
 */
export interface TransportConfig {
  type: TransportType;
  // HTTP配置
  baseURL?: string;
  // 软总线配置
  deviceId?: string;
  sessionName?: string;
}

/**
 * 请求选项接口
 */
export interface RequestOptions {
  method: 'GET' | 'POST';
  headers?: Record<string, string>;
  data?: object;
  readTimeout?: number;
  connectTimeout?: number;
}

/**
 * 传输层响应接口
 */
export interface TransportResponse {
  responseCode: number;
  result?: string;
}

/**
 * 传输层抽象接口
 * 定义端侧与边侧通信的统一接口，支持HTTP和软总线两种实现
 */
export interface ITransport {
  /**
   * 连接到边侧设备
   * @param config 传输层配置
   * @returns 连接是否成功
   */
  connect(config: TransportConfig): Promise<boolean>;

  /**
   * 断开连接
   */
  disconnect(): void;

  /**
   * 发送请求（支持流式响应）
   * @param endpoint API端点路径
   * @param options 请求选项
   * @returns 响应状态码
   */
  sendStreamRequest(endpoint: string, options: RequestOptions): Promise<number>;

  /**
   * 发送普通请求
   * @param endpoint API端点路径
   * @param options 请求选项
   * @returns 响应数据
   */
  sendRequest(endpoint: string, options: RequestOptions): Promise<TransportResponse>;

  /**
   * 注册数据接收回调（用于流式响应）
   * @param callback 数据接收回调函数
   */
  onDataReceive(callback: Callback<ArrayBuffer>): void;

  /**
   * 取消数据接收回调
   */
  offDataReceive(): void;

  /**
   * 获取连接状态
   * @returns 是否已连接
   */
  isConnected(): boolean;

  /**
   * 销毁传输层实例，释放资源
   */
  destroy(): void;
}
