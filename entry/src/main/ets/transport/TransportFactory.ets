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

import { ITransport, TransportType, TransportConfig } from "./ITransport";
import { HttpTransport } from "./http/HttpTransport";
import { SoftBusTransport } from "./softbus/SoftBusTransport";

/**
 * 传输层工厂类
 * 根据配置创建对应的传输层实例（HTTP或软总线）
 */
export class TransportFactory {
  /**
   * 创建传输层实例
   * @param type 传输层类型
   * @returns 传输层实例
   */
  static create(type: TransportType): ITransport {
    switch (type) {
      case 'http':
        return new HttpTransport();
      case 'softbus':
        return new SoftBusTransport();
      default:
        throw new Error(`Unsupported transport type: ${type}`);
    }
  }

  /**
   * 创建并连接传输层
   * @param config 传输层配置
   * @returns 已连接的传输层实例
   */
  static async createAndConnect(config: TransportConfig): Promise<ITransport> {
    const transport = TransportFactory.create(config.type);
    const connected = await transport.connect(config);
    if (!connected) {
      throw new Error(`Failed to connect with transport type: ${config.type}`);
    }
    return transport;
  }
}
