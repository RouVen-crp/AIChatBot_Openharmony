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

import { EdgeServer, ServerState } from './EdgeServer';
import Logger from '../utils/Logger';
import { wifiManager } from '@kit.ConnectivityKit';

const TAG = '[EdgeServerManager]';

/**
 * 设备模式
 */
export enum DeviceMode {
  /** 端侧模式 - 发送请求到边侧 */
  END_SIDE = 'end_side',
  /** 边侧模式 - 接收请求并转发到Ollama */
  EDGE_SIDE = 'edge_side'
}

/**
 * 边侧服务器管理器
 * 单例模式，管理EdgeServer的生命周期
 */
export class EdgeServerManager {
  private static instance: EdgeServerManager | null = null;
  private server: EdgeServer;
  private deviceMode: DeviceMode = DeviceMode.END_SIDE;
  private serverPort: number = 8080;
  private ollamaUrl: string = 'http://127.0.0.1:11434';
  private localIp: string = '';

  private constructor() {
    this.server = new EdgeServer();
  }

  /**
   * 获取单例实例
   */
  static getInstance(): EdgeServerManager {
    if (!EdgeServerManager.instance) {
      EdgeServerManager.instance = new EdgeServerManager();
    }
    return EdgeServerManager.instance;
  }

  /**
   * 设置设备模式
   */
  setDeviceMode(mode: DeviceMode): void {
    this.deviceMode = mode;
    Logger.info(TAG, `Device mode set to: ${mode}`);
  }

  /**
   * 获取设备模式
   */
  getDeviceMode(): DeviceMode {
    return this.deviceMode;
  }

  /**
   * 配置服务器
   */
  configureServer(port: number, ollamaUrl: string): void {
    this.serverPort = port;
    this.ollamaUrl = ollamaUrl;
    this.server.configure(port, ollamaUrl);
  }

  /**
   * 启动边侧服务
   */
  async startEdgeService(): Promise<boolean> {
    if (this.deviceMode !== DeviceMode.EDGE_SIDE) {
      Logger.warn(TAG, 'Cannot start edge service in end-side mode');
      return false;
    }

    // 获取本机IP
    await this.updateLocalIp();

    // 配置并启动服务器
    this.server.configure(this.serverPort, this.ollamaUrl);
    return await this.server.start();
  }

  /**
   * 停止边侧服务
   */
  async stopEdgeService(): Promise<void> {
    await this.server.stop();
  }

  /**
   * 获取服务器实例（用于注册回调）
   */
  getServer(): EdgeServer {
    return this.server;
  }

  /**
   * 获取服务器状态
   */
  getServerState(): ServerState {
    return this.server.getState();
  }

  /**
   * 获取服务器端口
   */
  getServerPort(): number {
    return this.serverPort;
  }

  /**
   * 获取Ollama URL
   */
  getOllamaUrl(): string {
    return this.ollamaUrl;
  }

  /**
   * 获取本机IP地址
   */
  getLocalIp(): string {
    return this.localIp;
  }

  /**
   * 更新本机IP地址
   */
  async updateLocalIp(): Promise<string> {
    try {
      // 尝试获取WiFi IP
      const ipInfo = wifiManager.getIpInfo();
      if (ipInfo && ipInfo.ipAddress) {
        // 将整数IP转换为点分十进制
        this.localIp = this.intToIp(ipInfo.ipAddress);
        Logger.info(TAG, `Local IP (WiFi): ${this.localIp}`);
        
        // 检查是否为模拟器环境（10.0.2.x网段）
        if (this.localIp.startsWith('10.0.2.')) {
          Logger.info(TAG, `Detected emulator IP: ${this.localIp}`);
        }
        
        return this.localIp;
      } else {
        Logger.warn(TAG, 'WiFi IP info is null or empty');
      }
    } catch (error) {
      Logger.warn(TAG, `Failed to get WiFi IP: ${JSON.stringify(error)}`);
    }

    // 如果无法获取IP，在模拟器环境中可能需要手动配置
    // 默认使用localhost（但这在模拟器间通信时不可用）
    this.localIp = '127.0.0.1';
    Logger.warn(TAG, `Using default IP: ${this.localIp}. If this is an emulator, you may need to check the IP manually.`);
    return this.localIp;
  }

  /**
   * 整数IP转点分十进制
   */
  private intToIp(ipInt: number): string {
    return [
      (ipInt & 0xFF),
      ((ipInt >> 8) & 0xFF),
      ((ipInt >> 16) & 0xFF),
      ((ipInt >> 24) & 0xFF)
    ].join('.');
  }

  /**
   * 获取边侧服务地址（供端侧连接）
   */
  getEdgeServiceAddress(): string {
    return `http://${this.localIp}:${this.serverPort}`;
  }

  /**
   * 获取请求统计
   */
  getRequestCount(): number {
    return this.server.getRequestCount();
  }

  /**
   * 获取当前连接数
   */
  getClientCount(): number {
    return this.server.getClientCount();
  }
}
