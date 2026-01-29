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

import { util } from '@kit.ArkTS';

/**
 * 软总线消息类型枚举
 */
export enum SoftBusMessageType {
  // 请求类型
  REQUEST = 'request',
  // 响应类型
  RESPONSE = 'response',
  // 流式数据块
  STREAM_CHUNK = 'stream_chunk',
  // 流式结束标记
  STREAM_END = 'stream_end',
  // 心跳检测
  HEARTBEAT = 'heartbeat',
  // 错误消息
  ERROR = 'error'
}

/**
 * 软总线请求消息结构
 */
export interface SoftBusRequest {
  // 消息ID，用于关联请求和响应
  messageId: string;
  // 消息类型
  type: SoftBusMessageType;
  // API端点
  endpoint: string;
  // HTTP方法
  method: 'GET' | 'POST';
  // 请求头
  headers?: Record<string, string>;
  // 请求体数据
  data?: object;
  // 时间戳
  timestamp: number;
}

/**
 * 软总线响应消息结构
 */
export interface SoftBusResponse {
  // 对应请求的消息ID
  messageId: string;
  // 消息类型
  type: SoftBusMessageType;
  // 响应状态码
  statusCode: number;
  // 响应数据（普通响应或流式数据块）
  data?: string | ArrayBuffer;
  // 错误信息
  error?: string;
  // 时间戳
  timestamp: number;
}

/**
 * 设备信息结构
 */
export interface DeviceInfo {
  // 设备ID
  deviceId: string;
  // 设备名称
  deviceName: string;
  // 设备类型 (0: 未知, 1: 手机, 2: 平板, 3: 电视, 4: PC, 5: 手表)
  deviceType: number;
  // 网络ID
  networkId?: string;
  // 是否在线
  isOnline: boolean;
}

/**
 * Session配置
 */
export interface SessionConfig {
  // Session名称
  sessionName: string;
  // 对端设备ID
  peerDeviceId: string;
  // 对端Session名称
  peerSessionName: string;
  // Session类型 (bytes/message/stream/file)
  sessionType: 'bytes' | 'message' | 'stream' | 'file';
}

/**
 * 软总线协议工具类
 */
export class SoftBusProtocol {
  // Session名称前缀
  static readonly SESSION_NAME_PREFIX = 'AIModelChat_';
  // 默认Session名称
  static readonly DEFAULT_SESSION_NAME = 'AIModelChat_Session';
  // 心跳间隔（毫秒）
  static readonly HEARTBEAT_INTERVAL = 30000;
  // 请求超时时间（毫秒）
  static readonly REQUEST_TIMEOUT = 180000;

  /**
   * 生成唯一消息ID
   */
  static generateMessageId(): string {
    return `msg_${Date.now()}_${Math.random().toString(36).substring(2, 9)}`;
  }

  /**
   * 创建请求消息
   */
  static createRequest(
    endpoint: string,
    method: 'GET' | 'POST',
    data?: object,
    headers?: Record<string, string>
  ): SoftBusRequest {
    return {
      messageId: SoftBusProtocol.generateMessageId(),
      type: SoftBusMessageType.REQUEST,
      endpoint,
      method,
      headers,
      data,
      timestamp: Date.now()
    };
  }

  /**
   * 创建响应消息
   */
  static createResponse(
    messageId: string,
    statusCode: number,
    data?: string | ArrayBuffer,
    error?: string
  ): SoftBusResponse {
    return {
      messageId,
      type: error ? SoftBusMessageType.ERROR : SoftBusMessageType.RESPONSE,
      statusCode,
      data,
      error,
      timestamp: Date.now()
    };
  }

  /**
   * 创建流式数据块响应
   */
  static createStreamChunk(messageId: string, data: ArrayBuffer): SoftBusResponse {
    return {
      messageId,
      type: SoftBusMessageType.STREAM_CHUNK,
      statusCode: 200,
      data,
      timestamp: Date.now()
    };
  }

  /**
   * 创建流式结束标记
   */
  static createStreamEnd(messageId: string): SoftBusResponse {
    return {
      messageId,
      type: SoftBusMessageType.STREAM_END,
      statusCode: 200,
      timestamp: Date.now()
    };
  }

  /**
   * 序列化消息为ArrayBuffer
   */
  static serialize(message: SoftBusRequest | SoftBusResponse): ArrayBuffer {
    const jsonStr = JSON.stringify(message);
    const encoder = new util.TextEncoder();
    const encoded = encoder.encodeInto(jsonStr);
    return encoded.buffer as ArrayBuffer;
  }

  /**
   * 反序列化ArrayBuffer为消息
   */
  static deserialize<T extends SoftBusRequest | SoftBusResponse>(buffer: ArrayBuffer): T {
    const decoder = new util.TextDecoder('utf-8');
    const jsonStr = decoder.decodeToString(new Uint8Array(buffer));
    return JSON.parse(jsonStr) as T;
  }
}
