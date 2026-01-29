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
import { socket } from '@kit.NetworkKit';
import { util } from '@kit.ArkTS';
import Logger from '../utils/Logger';

const TAG = '[EdgeServer]';

/**
 * 请求处理回调
 */
export type RequestHandler = (request: EdgeRequest) => Promise<EdgeResponse>;

/**
 * 边侧请求结构
 */
export interface EdgeRequest {
  method: string;
  path: string;
  headers: Record<string, string>;
  body: string;
}

/**
 * 边侧响应结构
 */
export interface EdgeResponse {
  statusCode: number;
  headers: Record<string, string>;
  body: string;
}

/**
 * 服务器状态
 */
export enum ServerState {
  STOPPED = 'stopped',
  STARTING = 'starting',
  RUNNING = 'running',
  STOPPING = 'stopping',
  ERROR = 'error'
}

/**
 * 边侧HTTP服务器
 * 接收来自端侧的HTTP请求，转发到本地Ollama
 */
export class EdgeServer {
  private tcpServer: socket.TCPSocketServer | null = null;
  private state: ServerState = ServerState.STOPPED;
  private port: number = 8080;
  private ollamaUrl: string = 'http://127.0.0.1:11434';
  private requestCount: number = 0;
  private clients: Map<number, socket.TCPSocketConnection> = new Map();
  private clientIdCounter: number = 0;
  private onStateChangeCallback: ((state: ServerState) => void) | null = null;
  private onRequestCallback: ((path: string, method: string) => void) | null = null;

  constructor() {}

  /**
   * 配置服务器
   */
  configure(port: number, ollamaUrl: string): void {
    this.port = port;
    this.ollamaUrl = ollamaUrl;
    Logger.info(TAG, `Server configured: port=${port}, ollamaUrl=${ollamaUrl}`);
  }

  /**
   * 启动服务器
   */
  async start(): Promise<boolean> {
    if (this.state === ServerState.RUNNING) {
      Logger.warn(TAG, 'Server is already running');
      return true;
    }

    try {
      this.setState(ServerState.STARTING);

      // 创建TCP服务器
      this.tcpServer = socket.constructTCPSocketServerInstance();

      // 监听连接
      this.tcpServer.on('connect', (client: socket.TCPSocketConnection) => {
        this.handleConnection(client);
      });

      // 绑定端口并开始监听
      const listenAddress: socket.NetAddress = {
        address: '0.0.0.0',
        port: this.port,
        family: 1 // IPv4
      };

      await this.tcpServer.listen(listenAddress);

      this.setState(ServerState.RUNNING);
      Logger.info(TAG, `Server started on port ${this.port}`);
      return true;

    } catch (error) {
      Logger.error(TAG, `Failed to start server: ${JSON.stringify(error)}`);
      this.setState(ServerState.ERROR);
      return false;
    }
  }

  /**
   * 停止服务器
   */
  async stop(): Promise<void> {
    if (this.state !== ServerState.RUNNING) {
      return;
    }

    try {
      this.setState(ServerState.STOPPING);

      // 关闭所有客户端连接
      const closePromises: Promise<void>[] = [];
      this.clients.forEach((client: socket.TCPSocketConnection, clientId: number) => {
        try {
          client.off('message');
          client.off('close');
          const closePromise = client.close().then(() => {
            Logger.info(TAG, `Client ${clientId} closed`);
          }).catch((e: Object) => {
            const errorMsg = e instanceof Error ? e.message : JSON.stringify(e);
            Logger.warn(TAG, `Error closing client ${clientId}: ${errorMsg}`);
          });
          closePromises.push(closePromise);
        } catch (err) {
          const errorMsg = err instanceof Error ? err.message : JSON.stringify(err);
          Logger.warn(TAG, `Error closing client ${clientId}: ${errorMsg}`);
        }
      });
      await Promise.all(closePromises);
      this.clients.clear();

      // 关闭服务器
      if (this.tcpServer) {
        this.tcpServer.off('connect');
        this.tcpServer = null;
      }

      this.setState(ServerState.STOPPED);
      Logger.info(TAG, 'Server stopped');

    } catch (error) {
      Logger.error(TAG, `Error stopping server: ${JSON.stringify(error)}`);
      this.setState(ServerState.ERROR);
    }
  }

  /**
   * 处理新连接
   */
  private handleConnection(client: socket.TCPSocketConnection): void {
    const clientId = ++this.clientIdCounter;
    this.clients.set(clientId, client);
    Logger.info(TAG, `Client ${clientId} connected`);

    let requestBuffer = '';

    // 监听数据
    client.on('message', async (value: socket.SocketMessageInfo) => {
      try {
        const decoder = new util.TextDecoder('utf-8');
        const chunk = decoder.decodeToString(new Uint8Array(value.message));
        Logger.info(TAG, `Client ${clientId} received ${chunk.length} bytes`);
        requestBuffer += chunk;

        // 检查是否收到完整的HTTP请求
        if (this.isCompleteRequest(requestBuffer)) {
          const request = this.parseHttpRequest(requestBuffer);
          requestBuffer = '';

          if (request) {
            this.requestCount++;
            this.notifyRequest(request.path, request.method);

            // 处理请求
            const response = await this.handleRequest(request);

            // 发送响应
            const responseStr = this.formatHttpResponse(response);
            const encoder = new util.TextEncoder();
            const responseData = encoder.encodeInto(responseStr);

            await client.send({ data: responseData.buffer as ArrayBuffer });
          }
        }
      } catch (error) {
        Logger.error(TAG, `Error handling message: ${JSON.stringify(error)}`);
      }
    });

    // 监听关闭
    client.on('close', () => {
      Logger.info(TAG, `Client ${clientId} disconnected`);
      this.clients.delete(clientId);
    });
  }

  /**
   * 检查是否为完整的HTTP请求
   */
  private isCompleteRequest(data: string): boolean {
    // 简单检查：包含双换行符表示头部结束
    const headerEnd = data.indexOf('\r\n\r\n');
    if (headerEnd === -1) {
      return false;
    }

    // 检查Content-Length
    const contentLengthMatch = data.match(/Content-Length:\s*(\d+)/i);
    if (contentLengthMatch) {
      const contentLength = parseInt(contentLengthMatch[1]);
      const bodyStart = headerEnd + 4;
      const body = data.substring(bodyStart);
      return body.length >= contentLength;
    }

    return true;
  }

  /**
   * 解析HTTP请求
   */
  private parseHttpRequest(data: string): EdgeRequest | null {
    try {
      const lines = data.split('\r\n');
      const requestLine = lines[0].split(' ');

      if (requestLine.length < 3) {
        return null;
      }

      const method = requestLine[0];
      const path = requestLine[1];
      const headers: Record<string, string> = {};

      let i = 1;
      while (i < lines.length && lines[i] !== '') {
        const colonIndex = lines[i].indexOf(':');
        if (colonIndex > 0) {
          const key = lines[i].substring(0, colonIndex).trim();
          const value = lines[i].substring(colonIndex + 1).trim();
          headers[key.toLowerCase()] = value;
        }
        i++;
      }

      // 获取body
      const bodyStart = data.indexOf('\r\n\r\n');
      const body = bodyStart >= 0 ? data.substring(bodyStart + 4) : '';

      return { method, path, headers, body };

    } catch (error) {
      Logger.error(TAG, `Error parsing request: ${error}`);
      return null;
    }
  }

  /**
   * 处理请求 - 转发到Ollama
   */
  private async handleRequest(request: EdgeRequest): Promise<EdgeResponse> {
    Logger.info(TAG, `Handling request: ${request.method} ${request.path}`);

    try {
      // 构建Ollama URL
      const targetUrl = this.ollamaUrl + request.path;

      // 创建HTTP请求
      const httpRequest = http.createHttp();

      const httpMethod = request.method === 'POST' ? http.RequestMethod.POST : http.RequestMethod.GET;

      const response = await httpRequest.request(targetUrl, {
        method: httpMethod,
        header: {
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        },
        extraData: request.body || undefined,
        readTimeout: 180000,
        connectTimeout: 30000
      });

      httpRequest.destroy();

      return {
        statusCode: response.responseCode,
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*'
        },
        body: typeof response.result === 'string' ? response.result : JSON.stringify(response.result)
      };

    } catch (error) {
      Logger.error(TAG, `Error forwarding request: ${JSON.stringify(error)}`);
      return {
        statusCode: 502,
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ error: 'Bad Gateway', message: 'Failed to connect to Ollama' })
      };
    }
  }

  /**
   * 格式化HTTP响应
   */
  private formatHttpResponse(response: EdgeResponse): string {
    const statusText = this.getStatusText(response.statusCode);
    let result = `HTTP/1.1 ${response.statusCode} ${statusText}\r\n`;

    // 添加headers
    const headerKeys = Object.keys(response.headers);
    for (let i = 0; i < headerKeys.length; i++) {
      const key = headerKeys[i];
      const value = response.headers[key];
      result += `${key}: ${value}\r\n`;
    }

    // 添加Content-Length
    const bodyBytes = new util.TextEncoder().encodeInto(response.body);
    result += `Content-Length: ${bodyBytes.length}\r\n`;
    result += '\r\n';
    result += response.body;

    return result;
  }

  /**
   * 获取状态文本
   */
  private getStatusText(code: number): string {
    const statusTexts: Record<number, string> = {
      200: 'OK',
      201: 'Created',
      400: 'Bad Request',
      404: 'Not Found',
      500: 'Internal Server Error',
      502: 'Bad Gateway'
    };
    return statusTexts[code] || 'Unknown';
  }

  /**
   * 设置状态
   */
  private setState(state: ServerState): void {
    this.state = state;
    if (this.onStateChangeCallback) {
      this.onStateChangeCallback(state);
    }
  }

  /**
   * 通知请求
   */
  private notifyRequest(path: string, method: string): void {
    if (this.onRequestCallback) {
      this.onRequestCallback(path, method);
    }
  }

  /**
   * 注册状态变化回调
   */
  onStateChange(callback: (state: ServerState) => void): void {
    this.onStateChangeCallback = callback;
  }

  /**
   * 注册请求回调
   */
  onRequest(callback: (path: string, method: string) => void): void {
    this.onRequestCallback = callback;
  }

  /**
   * 获取当前状态
   */
  getState(): ServerState {
    return this.state;
  }

  /**
   * 获取端口
   */
  getPort(): number {
    return this.port;
  }

  /**
   * 获取请求计数
   */
  getRequestCount(): number {
    return this.requestCount;
  }

  /**
   * 获取连接数
   */
  getClientCount(): number {
    return this.clients.size;
  }
}
