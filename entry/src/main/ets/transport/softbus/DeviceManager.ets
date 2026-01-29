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

import { DeviceInfo } from "./SoftBusProtocol";

/**
 * 设备状态变化回调
 */
export type DeviceStateCallback = (device: DeviceInfo, state: 'online' | 'offline' | 'changed') => void;

/**
 * 设备发现回调
 */
export type DeviceDiscoverCallback = (device: DeviceInfo) => void;

/**
 * 设备管理器状态
 */
export enum DeviceManagerState {
  // 未初始化
  UNINITIALIZED = 'uninitialized',
  // 已初始化
  INITIALIZED = 'initialized',
  // 正在发现设备
  DISCOVERING = 'discovering',
  // 已停止发现
  STOPPED = 'stopped',
  // 错误状态
  ERROR = 'error'
}

/**
 * 设备管理器
 * 负责设备发现、设备状态管理和可信设备列表维护
 * 注意：此功能需要在真机上运行，模拟器不支持软总线功能
 */
export class DeviceManager {
  private static instance: DeviceManager | null = null;
  private state: DeviceManagerState = DeviceManagerState.UNINITIALIZED;
  private discoveredDevices: Map<string, DeviceInfo> = new Map();
  private trustedDevices: Map<string, DeviceInfo> = new Map();
  private deviceStateCallbacks: DeviceStateCallback[] = [];
  private deviceDiscoverCallbacks: DeviceDiscoverCallback[] = [];
  private dmInstance: object | null = null;

  private constructor() {}

  /**
   * 获取单例实例
   */
  static getInstance(): DeviceManager {
    if (!DeviceManager.instance) {
      DeviceManager.instance = new DeviceManager();
    }
    return DeviceManager.instance;
  }

  /**
   * 初始化设备管理器
   * 注意：需要真机环境，模拟器会返回失败
   */
  async initialize(bundleName: string): Promise<boolean> {
    if (this.state === DeviceManagerState.INITIALIZED) {
      return true;
    }

    try {
      // 动态导入 deviceManager 模块，避免在模拟器上编译错误
      // 实际使用时需要：import deviceManager from '@ohos.distributedDeviceManager';
      // const dm = await import('@ohos.distributedDeviceManager');

      // 由于模拟器不支持软总线，这里提供框架代码
      // 真机部署时取消注释以下代码：
      /*
      deviceManager.createDeviceManager(bundleName, (err, data) => {
        if (err) {
          console.error('DeviceManager: Failed to create device manager:', err);
          this.state = DeviceManagerState.ERROR;
          return;
        }

        this.dmInstance = data;
        this.state = DeviceManagerState.INITIALIZED;

        // 注册设备状态变化监听
        this.dmInstance.on('deviceStateChange', (data) => {
          this.handleDeviceStateChange(data);
        });

        // 注册设备发现监听
        this.dmInstance.on('deviceFound', (data) => {
          this.handleDeviceFound(data);
        });
      });
      */

      // 模拟器环境下标记为已初始化（但功能不可用）
      console.warn('DeviceManager: Running in simulator mode. SoftBus features are not available.');
      this.state = DeviceManagerState.INITIALIZED;
      return true;

    } catch (error) {
      console.error('DeviceManager: Initialization failed:', error);
      this.state = DeviceManagerState.ERROR;
      return false;
    }
  }

  /**
   * 开始设备发现
   */
  async startDiscovery(): Promise<boolean> {
    if (this.state !== DeviceManagerState.INITIALIZED) {
      console.error('DeviceManager: Not initialized');
      return false;
    }

    try {
      // 真机部署时取消注释以下代码：
      /*
      const subscribeInfo = {
        subscribeId: Date.now(),
        mode: 0, // 主动发现模式
        medium: 2, // 软总线介质
        freq: 2, // 高频发现
        isSameAccount: true,
        isWakeRemote: true
      };

      this.dmInstance?.startDeviceDiscovery(subscribeInfo);
      */

      this.state = DeviceManagerState.DISCOVERING;
      console.info('DeviceManager: Device discovery started (simulator mode - no actual discovery)');
      return true;

    } catch (error) {
      console.error('DeviceManager: Failed to start discovery:', error);
      return false;
    }
  }

  /**
   * 停止设备发现
   */
  stopDiscovery(): void {
    if (this.state !== DeviceManagerState.DISCOVERING) {
      return;
    }

    try {
      // 真机部署时取消注释：
      // this.dmInstance?.stopDeviceDiscovery(this.subscribeId);

      this.state = DeviceManagerState.STOPPED;
      console.info('DeviceManager: Device discovery stopped');

    } catch (error) {
      console.error('DeviceManager: Failed to stop discovery:', error);
    }
  }

  /**
   * 获取已发现的设备列表
   */
  getDiscoveredDevices(): DeviceInfo[] {
    return Array.from(this.discoveredDevices.values());
  }

  /**
   * 获取可信设备列表
   */
  getTrustedDevices(): DeviceInfo[] {
    // 真机部署时使用：
    // return this.dmInstance?.getTrustedDeviceListSync() ?? [];

    return Array.from(this.trustedDevices.values());
  }

  /**
   * 认证设备（PIN码认证）
   */
  async authenticateDevice(deviceId: string): Promise<boolean> {
    try {
      // 真机部署时取消注释：
      /*
      const authParam = {
        authType: 1, // PIN码认证
        extraInfo: {}
      };

      return new Promise((resolve) => {
        this.dmInstance?.authenticateDevice(deviceInfo, authParam, (err) => {
          if (err) {
            console.error('DeviceManager: Authentication failed:', err);
            resolve(false);
          } else {
            resolve(true);
          }
        });
      });
      */

      console.warn('DeviceManager: Authentication not available in simulator mode');
      return false;

    } catch (error) {
      console.error('DeviceManager: Authentication error:', error);
      return false;
    }
  }

  /**
   * 注册设备状态变化回调
   */
  onDeviceStateChange(callback: DeviceStateCallback): void {
    this.deviceStateCallbacks.push(callback);
  }

  /**
   * 注册设备发现回调
   */
  onDeviceDiscover(callback: DeviceDiscoverCallback): void {
    this.deviceDiscoverCallbacks.push(callback);
  }

  /**
   * 取消设备状态变化回调
   */
  offDeviceStateChange(callback: DeviceStateCallback): void {
    const index = this.deviceStateCallbacks.indexOf(callback);
    if (index > -1) {
      this.deviceStateCallbacks.splice(index, 1);
    }
  }

  /**
   * 取消设备发现回调
   */
  offDeviceDiscover(callback: DeviceDiscoverCallback): void {
    const index = this.deviceDiscoverCallbacks.indexOf(callback);
    if (index > -1) {
      this.deviceDiscoverCallbacks.splice(index, 1);
    }
  }

  /**
   * 处理设备状态变化
   */
  private handleDeviceStateChange(data: object): void {
    // 解析设备状态变化数据
    const deviceInfo = this.parseDeviceInfo(data);
    if (!deviceInfo) return;

    // 更新设备列表
    if ((data as Record<string, number>)['action'] === 0) { // ONLINE
      this.trustedDevices.set(deviceInfo.deviceId, deviceInfo);
      this.notifyDeviceStateChange(deviceInfo, 'online');
    } else if ((data as Record<string, number>)['action'] === 1) { // OFFLINE
      this.trustedDevices.delete(deviceInfo.deviceId);
      this.notifyDeviceStateChange(deviceInfo, 'offline');
    } else { // CHANGE
      this.trustedDevices.set(deviceInfo.deviceId, deviceInfo);
      this.notifyDeviceStateChange(deviceInfo, 'changed');
    }
  }

  /**
   * 处理设备发现
   */
  private handleDeviceFound(data: object): void {
    const deviceInfo = this.parseDeviceInfo(data);
    if (!deviceInfo) return;

    this.discoveredDevices.set(deviceInfo.deviceId, deviceInfo);
    this.notifyDeviceDiscover(deviceInfo);
  }

  /**
   * 解析设备信息
   */
  private parseDeviceInfo(data: object): DeviceInfo | null {
    try {
      const rawData = data as Record<string, string | number | boolean>;
      return {
        deviceId: rawData['deviceId'] as string,
        deviceName: rawData['deviceName'] as string,
        deviceType: rawData['deviceType'] as number,
        networkId: rawData['networkId'] as string,
        isOnline: true
      };
    } catch {
      return null;
    }
  }

  /**
   * 通知设备状态变化
   */
  private notifyDeviceStateChange(device: DeviceInfo, state: 'online' | 'offline' | 'changed'): void {
    this.deviceStateCallbacks.forEach(callback => {
      callback(device, state);
    });
  }

  /**
   * 通知设备发现
   */
  private notifyDeviceDiscover(device: DeviceInfo): void {
    this.deviceDiscoverCallbacks.forEach(callback => {
      callback(device);
    });
  }

  /**
   * 获取当前状态
   */
  getState(): DeviceManagerState {
    return this.state;
  }

  /**
   * 释放资源
   */
  release(): void {
    this.stopDiscovery();

    // 真机部署时取消注释：
    // this.dmInstance?.release();

    this.dmInstance = null;
    this.discoveredDevices.clear();
    this.trustedDevices.clear();
    this.deviceStateCallbacks = [];
    this.deviceDiscoverCallbacks = [];
    this.state = DeviceManagerState.UNINITIALIZED;

    DeviceManager.instance = null;
  }
}
