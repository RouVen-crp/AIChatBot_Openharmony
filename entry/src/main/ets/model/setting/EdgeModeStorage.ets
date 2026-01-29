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

import { DeviceMode } from '../../edgeServer/EdgeServerManager';

/**
 * 边侧模式配置存储
 */
@ObservedV2
export class EdgeModeStorage {
  /** 设备模式：端侧或边侧 */
  @Trace deviceMode: DeviceMode = DeviceMode.END_SIDE;

  /** 边侧服务端口 */
  @Trace serverPort: string = '8080';

  /** Ollama服务地址（边侧模式使用） */
  @Trace ollamaHost: string = '127.0.0.1';

  /** Ollama服务端口（边侧模式使用） */
  @Trace ollamaPort: string = '11434';

  /** 边侧服务是否运行中 */
  @Trace isServerRunning: boolean = false;

  /** 本机IP地址 */
  @Trace localIp: string = '';

  /** 请求计数 */
  @Trace requestCount: number = 0;

  /** 当前连接数 */
  @Trace clientCount: number = 0;

  /** 最后一次请求路径 */
  @Trace lastRequestPath: string = '';

  /** 端侧模式 - 边侧服务器地址 */
  @Trace edgeServerHost: string = '';

  /** 端侧模式 - 边侧服务器端口 */
  @Trace edgeServerPort: string = '8080';
}
