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
import { ITransport, TransportConfig, RequestOptions, TransportResponse } from "../ITransport";
import { DeviceManager } from "./DeviceManager";
import {
  SoftBusProtocol,
  SoftBusRequest,
  SoftBusResponse,
  SoftBusMessageType
} from "./SoftBusProtocol";

/**
 * Session状态
 */
enum SessionState {
  DISCONNECTED = 'disconnected',
  CONNECTING = 'connecting',
  CONNECTED = 'connected',
  ERROR = 'error'
}

/**
 * 待处理请求信息
 */
interface PendingRequest {
  messageId: string;
  resolve: (value: number) => void;
  reject: (reason: Error) => void;
  dataCallback?: Callback<ArrayBuffer>;
  timeout: number;
}

/**
 * 软总线传输层实现
 * 基于HarmonyOS分布式软总线实现端侧与边侧的通信
 * 注意：此功能需要在真机上运行，模拟器不支持软总线功能
 */
export class SoftBusTransport implements ITransport {
  private deviceManager: DeviceManager;
  private sessionState: SessionState = SessionState.DISCONNECTED;
  private sessionId: number = -1;
  private peerDeviceId: string = '';
  private sessionName: string = SoftBusProtocol.DEFAULT_SESSION_NAME;
  private dataCallback: Callback<ArrayBuffer> | null = null;
  private pendingRequests: Map<string, PendingRequest> = new Map();
  private heartbeatTimer: number | null = null;

  constructor() {
    this.deviceManager = DeviceManager.getInstance();
  }

  /**
   * 连接到边侧设备
   */
  async connect(config: TransportConfig): Promise<boolean> {
    if (!config.deviceId) {
      console.error('SoftBusTransport: deviceId is required');
      return false;
    }

    this.peerDeviceId = config.deviceId;
    if (config.sessionName) {
      this.sessionName = config.sessionName;
    }

    try {
      // 初始化设备管理器
      const initialized = await this.deviceManager.initialize('com.example.aimodelchat');
      if (!initialized) {
        console.error('SoftBusTransport: Failed to initialize device manager');
        return false;
      }

      // 创建Session连接
      this.sessionState = SessionState.CONNECTING;

      // 真机部署时取消注释以下代码：
      /*
      // 动态导入软总线模块
      // import socket from '@ohos.net.socket';

      const sessionAttribute = {
        dataType: 1, // 字节流类型
        linkTypeNum: 2,
        linkType: [1, 2], // WIFI_P2P, WIFI_STA
        attr: {
          minBW: 0,
          maxLatency: 0,
          minLatency: 0
        }
      };

      const sessionCallback = {
        onOpened: (sessionId: number) => {
          this.sessionId = sessionId;
          this.sessionState = SessionState.CONNECTED;
          this.startHeartbeat();
          console.info(`SoftBusTransport: Session opened, id: ${sessionId}`);
        },
        onClosed: (sessionId: number) => {
          this.handleSessionClosed(sessionId);
        },
        onBytesReceived: (sessionId: number, data: ArrayBuffer) => {
          this.handleDataReceived(sessionId, data);
        },
        onMessageReceived: (sessionId: number, data: ArrayBuffer) => {
          this.handleDataReceived(sessionId, data);
        }
      };

      // 创建Session
      this.sessionId = await softbus.createSessionServer(
        this.sessionName,
        this.peerDeviceId,
        sessionAttribute,
        sessionCallback
      );

      if (this.sessionId < 0) {
        this.sessionState = SessionState.ERROR;
        return false;
      }
      */

      // 模拟器环境下返回失败并提示
      console.warn('SoftBusTransport: SoftBus is not available in simulator mode.');
      console.warn('SoftBusTransport: Please use HTTP transport for testing, or deploy to real devices.');
      this.sessionState = SessionState.ERROR;
      return false;

    } catch (error) {
      console.error('SoftBusTransport: Connection failed:', error);
      this.sessionState = SessionState.ERROR;
      return false;
    }
  }

  /**
   * 断开连接
   */
  disconnect(): void {
    this.stopHeartbeat();

    if (this.sessionId >= 0) {
      // 真机部署时取消注释：
      // softbus.removeSessionServer(this.sessionName);

      this.sessionId = -1;
    }

    this.sessionState = SessionState.DISCONNECTED;
    this.pendingRequests.clear();
    console.info('SoftBusTransport: Disconnected');
  }

  /**
   * 发送流式请求
   */
  async sendStreamRequest(endpoint: string, options: RequestOptions): Promise<number> {
    if (this.sessionState !== SessionState.CONNECTED) {
      throw new Error('SoftBusTransport: Not connected');
    }

    const request = SoftBusProtocol.createRequest(
      endpoint,
      options.method,
      options.data,
      options.headers
    );

    return new Promise((resolve, reject) => {
      const timeout = options.readTimeout ?? SoftBusProtocol.REQUEST_TIMEOUT;

      // 设置超时
      const timeoutId = setTimeout(() => {
        this.pendingRequests.delete(request.messageId);
        reject(new Error('Request timeout'));
      }, timeout);

      // 保存待处理请求
      const pendingRequest: PendingRequest = {
        messageId: request.messageId,
        resolve,
        reject,
        dataCallback: this.dataCallback ?? undefined,
        timeout: timeoutId as number
      };
      this.pendingRequests.set(request.messageId, pendingRequest);

      // 发送请求
      this.sendData(request);
    });
  }

  /**
   * 发送普通请求
   */
  async sendRequest(endpoint: string, options: RequestOptions): Promise<TransportResponse> {
    if (this.sessionState !== SessionState.CONNECTED) {
      throw new Error('SoftBusTransport: Not connected');
    }

    const request = SoftBusProtocol.createRequest(
      endpoint,
      options.method,
      options.data,
      options.headers
    );

    return new Promise((resolve, reject) => {
      const timeout = options.readTimeout ?? SoftBusProtocol.REQUEST_TIMEOUT;
      let responseData = '';

      // 设置超时
      const timeoutId = setTimeout(() => {
        this.pendingRequests.delete(request.messageId);
        reject(new Error('Request timeout'));
      }, timeout);

      // 临时数据回调
      const tempCallback: Callback<ArrayBuffer> = (data: ArrayBuffer) => {
        const decoder = new util.TextDecoder('utf-8');
        responseData += decoder.decodeToString(new Uint8Array(data));
      };

      // 保存待处理请求（使用类型断言处理 resolve 类型）
      const resolveWrapper = (statusCode: number) => {
        clearTimeout(timeoutId);
        resolve({
          responseCode: statusCode,
          result: responseData
        });
      };
      const pendingRequest: PendingRequest = {
        messageId: request.messageId,
        resolve: resolveWrapper,
        reject,
        dataCallback: tempCallback,
        timeout: timeoutId as number
      };
      this.pendingRequests.set(request.messageId, pendingRequest);

      // 发送请求
      this.sendData(request);
    });
  }

  /**
   * 注册数据接收回调
   */
  onDataReceive(callback: Callback<ArrayBuffer>): void {
    this.dataCallback = callback;
  }

  /**
   * 取消数据接收回调
   */
  offDataReceive(): void {
    this.dataCallback = null;
  }

  /**
   * 获取连接状态
   */
  isConnected(): boolean {
    return this.sessionState === SessionState.CONNECTED;
  }

  /**
   * 销毁传输层实例
   */
  destroy(): void {
    this.disconnect();
    this.dataCallback = null;
  }

  /**
   * 发送数据到对端
   */
  private sendData(request: SoftBusRequest): void {
    const buffer = SoftBusProtocol.serialize(request);

    // 真机部署时取消注释：
    /*
    softbus.sendBytes(this.sessionId, buffer);
    */

    console.info(`SoftBusTransport: Sending request to ${request.endpoint}`);
  }

  /**
   * 处理接收到的数据
   */
  private handleDataReceived(sessionId: number, data: ArrayBuffer): void {
    if (sessionId !== this.sessionId) return;

    try {
      const response = SoftBusProtocol.deserialize<SoftBusResponse>(data);

      // 查找对应的待处理请求
      const pending = this.pendingRequests.get(response.messageId);
      if (!pending) {
        console.warn(`SoftBusTransport: No pending request for messageId: ${response.messageId}`);
        return;
      }

      switch (response.type) {
        case SoftBusMessageType.STREAM_CHUNK:
          // 流式数据块，调用回调
          if (pending.dataCallback && response.data) {
            if (typeof response.data === 'string') {
              const encoder = new util.TextEncoder();
              const encoded = encoder.encodeInto(response.data);
              pending.dataCallback(encoded.buffer as ArrayBuffer);
            } else {
              pending.dataCallback(response.data);
            }
          }
          break;

        case SoftBusMessageType.STREAM_END:
          // 流式结束
          clearTimeout(pending.timeout);
          this.pendingRequests.delete(response.messageId);
          pending.resolve(response.statusCode);
          break;

        case SoftBusMessageType.RESPONSE:
          // 普通响应
          if (pending.dataCallback && response.data) {
            if (typeof response.data === 'string') {
              const encoder = new util.TextEncoder();
              const encoded = encoder.encodeInto(response.data);
              pending.dataCallback(encoded.buffer as ArrayBuffer);
            } else {
              pending.dataCallback(response.data);
            }
          }
          clearTimeout(pending.timeout);
          this.pendingRequests.delete(response.messageId);
          pending.resolve(response.statusCode);
          break;

        case SoftBusMessageType.ERROR:
          // 错误响应
          clearTimeout(pending.timeout);
          this.pendingRequests.delete(response.messageId);
          pending.reject(new Error(response.error ?? 'Unknown error'));
          break;

        case SoftBusMessageType.HEARTBEAT:
          // 心跳响应，忽略
          break;
      }

    } catch (error) {
      console.error('SoftBusTransport: Failed to parse received data:', error);
    }
  }

  /**
   * 处理Session关闭
   */
  private handleSessionClosed(sessionId: number): void {
    if (sessionId !== this.sessionId) return;

    console.info(`SoftBusTransport: Session closed, id: ${sessionId}`);
    this.sessionState = SessionState.DISCONNECTED;
    this.sessionId = -1;
    this.stopHeartbeat();

    // 拒绝所有待处理的请求
    this.pendingRequests.forEach((pending) => {
      clearTimeout(pending.timeout);
      pending.reject(new Error('Session closed'));
    });
    this.pendingRequests.clear();
  }

  /**
   * 启动心跳
   */
  private startHeartbeat(): void {
    this.stopHeartbeat();

    const timerId = setInterval(() => {
      if (this.sessionState === SessionState.CONNECTED) {
        const heartbeat: SoftBusRequest = {
          messageId: SoftBusProtocol.generateMessageId(),
          type: SoftBusMessageType.HEARTBEAT,
          endpoint: '',
          method: 'GET',
          timestamp: Date.now()
        };
        this.sendData(heartbeat);
      }
    }, SoftBusProtocol.HEARTBEAT_INTERVAL);
    this.heartbeatTimer = timerId as number;
  }

  /**
   * 停止心跳
   */
  private stopHeartbeat(): void {
    if (this.heartbeatTimer !== null) {
      clearInterval(this.heartbeatTimer);
      this.heartbeatTimer = null;
    }
  }

  /**
   * 获取设备管理器
   */
  getDeviceManager(): DeviceManager {
    return this.deviceManager;
  }
}
