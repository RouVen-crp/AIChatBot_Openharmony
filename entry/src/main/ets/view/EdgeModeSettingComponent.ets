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

import { AppStorageV2, promptAction } from "@kit.ArkUI";
import { AvoidArea } from "../model/layout/AvoidData";
import { NormalTitle } from "../component/NormalTitle";
import { EdgeModeStorage } from "../model/setting/EdgeModeStorage";
import { EdgeServerManager, DeviceMode } from "../edgeServer/EdgeServerManager";
import { ServerState } from "../edgeServer/EdgeServer";
import PreferenceModel from "../preference/PreferenceModel";
import Logger from "../utils/Logger";
import { OllamaStorage } from "../model/setting/OllamaStorage";

const TAG = '[EdgeModeSettingComponent]';

@Builder
export function edgeModeSettingBuilder(name: string, param: Object) {
  EdgeModeSettingComponent()
}

@Entry
@ComponentV2
struct EdgeModeSettingComponent {
  @Local avoidArea: AvoidArea = AppStorageV2.connect(AvoidArea, 'AvoidArea', () => new AvoidArea())!;
  @Local edgeModeStorage: EdgeModeStorage =
    AppStorageV2.connect(EdgeModeStorage, 'EdgeModeStorage', () => new EdgeModeStorage())!;
  @Local ollamaStorage: OllamaStorage =
    AppStorageV2.connect(OllamaStorage, 'OllamaStorage', () => new OllamaStorage())!;
  @Local serverManager: EdgeServerManager = EdgeServerManager.getInstance();
  @Local modeSelectedIndex: number = 0;
  @Local refreshTimer: number = 0;

  aboutToAppear(): void {
    // 加载保存的配置
    this.loadConfig();

    // 初始化模式选择索引
    this.modeSelectedIndex = this.edgeModeStorage.deviceMode === DeviceMode.EDGE_SIDE ? 1 : 0;

    // 注册服务器状态回调
    this.serverManager.getServer().onStateChange((state: ServerState) => {
      this.edgeModeStorage.isServerRunning = state === ServerState.RUNNING;
      if (state === ServerState.RUNNING) {
        this.edgeModeStorage.localIp = this.serverManager.getLocalIp();
      }
    });

    // 注册请求回调
    this.serverManager.getServer().onRequest((path: string, method: string) => {
      this.edgeModeStorage.requestCount = this.serverManager.getRequestCount();
      this.edgeModeStorage.lastRequestPath = `${method} ${path}`;
    });

    // 如果服务已在运行，更新状态
    if (this.serverManager.getServerState() === ServerState.RUNNING) {
      this.edgeModeStorage.isServerRunning = true;
      this.edgeModeStorage.localIp = this.serverManager.getLocalIp();
      this.startRefreshTimer();
    }
  }

  aboutToDisappear(): void {
    if (this.refreshTimer) {
      clearInterval(this.refreshTimer);
    }
  }

  loadConfig(): void {
    const mode = PreferenceModel.getData('edge_mode_setting', 'deviceMode');
    if (mode === 'edge_side') {
      this.edgeModeStorage.deviceMode = DeviceMode.EDGE_SIDE;
    } else {
      this.edgeModeStorage.deviceMode = DeviceMode.END_SIDE;
    }

    const serverPort = PreferenceModel.getData('edge_mode_setting', 'serverPort');
    if (serverPort) {
      this.edgeModeStorage.serverPort = serverPort;
    }

    const ollamaHost = PreferenceModel.getData('edge_mode_setting', 'ollamaHost');
    if (ollamaHost) {
      this.edgeModeStorage.ollamaHost = ollamaHost;
    }

    const ollamaPort = PreferenceModel.getData('edge_mode_setting', 'ollamaPort');
    if (ollamaPort) {
      this.edgeModeStorage.ollamaPort = ollamaPort;
    }

    const edgeServerHost = PreferenceModel.getData('edge_mode_setting', 'edgeServerHost');
    if (edgeServerHost) {
      this.edgeModeStorage.edgeServerHost = edgeServerHost;
    }

    const edgeServerPort = PreferenceModel.getData('edge_mode_setting', 'edgeServerPort');
    if (edgeServerPort) {
      this.edgeModeStorage.edgeServerPort = edgeServerPort;
    }

    this.serverManager.setDeviceMode(this.edgeModeStorage.deviceMode);
  }

  saveConfig(): void {
    PreferenceModel.writeData(this.edgeModeStorage.deviceMode, 'edge_mode_setting', 'deviceMode');
    PreferenceModel.writeData(this.edgeModeStorage.serverPort, 'edge_mode_setting', 'serverPort');
    PreferenceModel.writeData(this.edgeModeStorage.ollamaHost, 'edge_mode_setting', 'ollamaHost');
    PreferenceModel.writeData(this.edgeModeStorage.ollamaPort, 'edge_mode_setting', 'ollamaPort');
    PreferenceModel.writeData(this.edgeModeStorage.edgeServerHost, 'edge_mode_setting', 'edgeServerHost');
    PreferenceModel.writeData(this.edgeModeStorage.edgeServerPort, 'edge_mode_setting', 'edgeServerPort');
  }

  onModeChange(index: number): void {
    const newMode = index === 1 ? DeviceMode.EDGE_SIDE : DeviceMode.END_SIDE;
    this.edgeModeStorage.deviceMode = newMode;
    this.serverManager.setDeviceMode(newMode);
    this.saveConfig();
    Logger.info(TAG, `Device mode changed to: ${newMode}`);
  }

  async startServer(): Promise<void> {
    const port = parseInt(this.edgeModeStorage.serverPort) || 8080;
    const ollamaUrl = `http://${this.edgeModeStorage.ollamaHost}:${this.edgeModeStorage.ollamaPort}`;

    this.serverManager.configureServer(port, ollamaUrl);
    this.saveConfig();

    const started = await this.serverManager.startEdgeService();
    if (started) {
      this.edgeModeStorage.localIp = this.serverManager.getLocalIp();
      promptAction.showToast({ message: '边侧服务已启动' });
      this.startRefreshTimer();
    } else {
      promptAction.showToast({ message: '启动失败，请检查配置' });
    }
  }

  async stopServer(): Promise<void> {
    await this.serverManager.stopEdgeService();
    this.edgeModeStorage.isServerRunning = false;
    if (this.refreshTimer) {
      clearInterval(this.refreshTimer);
      this.refreshTimer = 0;
    }
    promptAction.showToast({ message: '边侧服务已停止' });
  }

  startRefreshTimer(): void {
    if (this.refreshTimer) {
      clearInterval(this.refreshTimer);
    }
    const timerId = setInterval(() => {
      this.edgeModeStorage.clientCount = this.serverManager.getClientCount();
      this.edgeModeStorage.requestCount = this.serverManager.getRequestCount();
    }, 1000);
    this.refreshTimer = timerId as number;
  }

  @Builder
  SectionTitle(title: string) {
    Text(title)
      .fontSize(14)
      .fontColor($r('app.color.list_item_text_secondary'))
      .width('100%')
      .margin({ top: 16, bottom: 8 })
  }

  build() {
    Column() {
      NormalTitle()

      Scroll() {
        Column({ space: 12 }) {
          // 模式说明
          Column() {
            Text('端边协同模式设置')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.list_item_text_primary'))
              .width('100%')
              .margin({ bottom: 8 })

            Text('选择当前设备的角色：\n• 端侧模式：作为用户交互端，发送请求到边侧\n• 边侧模式：作为服务端，接收请求并转发到Ollama')
              .fontSize(13)
              .fontColor($r('app.color.list_item_text_secondary'))
              .width('100%')
              .lineHeight(20)
          }
          .padding(16)
          .backgroundColor($r('app.color.item_button_background'))
          .borderRadius(12)

          // 模式选择
          Row() {
            Text('设备模式')
              .fontColor($r('app.color.list_item_text_primary'))
              .fontSize(16)

            Blank()

            Select([{ value: '端侧模式' }, { value: '边侧模式' }])
              .selected(this.modeSelectedIndex)
              .value(this.modeSelectedIndex === 0 ? '端侧模式' : '边侧模式')
              .backgroundColor(Color.Transparent)
              .onSelect((index: number) => {
                this.modeSelectedIndex = index;
                this.onModeChange(index);
              })
          }
          .width('100%')
          .height(56)
          .padding({ left: 16, right: 16 })
          .backgroundColor($r('app.color.item_button_background'))
          .borderRadius(12)

          // 边侧模式配置
          if (this.edgeModeStorage.deviceMode === DeviceMode.EDGE_SIDE) {
            this.SectionTitle('边侧服务配置')

            Column({ space: 1 }) {
              // 服务端口
              Row() {
                Text('服务端口')
                  .fontColor($r('app.color.list_item_text_primary'))
                  .fontSize(16)

                Blank()

                TextInput({ text: this.edgeModeStorage.serverPort })
                  .width(100)
                  .height(40)
                  .type(InputType.Number)
                  .textAlign(TextAlign.End)
                  .backgroundColor(Color.Transparent)
                  .onChange((value: string) => {
                    this.edgeModeStorage.serverPort = value;
                  })
              }
              .width('100%')
              .height(56)
              .padding({ left: 16, right: 16 })

              Divider().margin({ left: 16 })

              // Ollama地址
              Row() {
                Text('Ollama地址')
                  .fontColor($r('app.color.list_item_text_primary'))
                  .fontSize(16)

                Blank()

                TextInput({ text: this.edgeModeStorage.ollamaHost })
                  .width(150)
                  .height(40)
                  .textAlign(TextAlign.End)
                  .backgroundColor(Color.Transparent)
                  .onChange((value: string) => {
                    this.edgeModeStorage.ollamaHost = value;
                  })
              }
              .width('100%')
              .height(56)
              .padding({ left: 16, right: 16 })

              Divider().margin({ left: 16 })

              // Ollama端口
              Row() {
                Text('Ollama端口')
                  .fontColor($r('app.color.list_item_text_primary'))
                  .fontSize(16)

                Blank()

                TextInput({ text: this.edgeModeStorage.ollamaPort })
                  .width(100)
                  .height(40)
                  .type(InputType.Number)
                  .textAlign(TextAlign.End)
                  .backgroundColor(Color.Transparent)
                  .onChange((value: string) => {
                    this.edgeModeStorage.ollamaPort = value;
                  })
              }
              .width('100%')
              .height(56)
              .padding({ left: 16, right: 16 })
            }
            .backgroundColor($r('app.color.item_button_background'))
            .borderRadius(12)

            // 服务控制
            this.SectionTitle('服务控制')

            Column({ space: 1 }) {
              // 启动/停止按钮
              Row() {
                if (this.edgeModeStorage.isServerRunning) {
                  Column() {
                    Row() {
                      Badge({
                        value: '',
                        style: { badgeSize: 8, badgeColor: '#4CAF50' }
                      }) {
                        Text('运行中')
                          .fontColor('#4CAF50')
                          .fontSize(14)
                      }
                    }

                    Column() {
                      Text(`地址: ${this.edgeModeStorage.localIp}:${this.edgeModeStorage.serverPort}`)
                        .fontSize(12)
                        .fontColor($r('app.color.list_item_text_primary'))
                        .fontWeight(FontWeight.Medium)
                      Text('端侧设备请使用此地址连接')
                        .fontSize(11)
                        .fontColor($r('app.color.list_item_text_secondary'))
                        .margin({ top: 2 })
                    }
                    .margin({ top: 4 })
                  }
                  .alignItems(HorizontalAlign.Start)

                  Blank()

                  Button('停止服务')
                    .type(ButtonType.Normal)
                    .height(36)
                    .borderRadius(18)
                    .backgroundColor($r('sys.color.ohos_id_color_warning'))
                    .onClick(() => {
                      this.stopServer();
                    })
                } else {
                  Text('服务未启动')
                    .fontColor($r('app.color.list_item_text_secondary'))
                    .fontSize(14)

                  Blank()

                  Button('启动服务')
                    .type(ButtonType.Normal)
                    .height(36)
                    .borderRadius(18)
                    .onClick(() => {
                      this.startServer();
                    })
                }
              }
              .width('100%')
              .height(72)
              .padding({ left: 16, right: 16 })

              if (this.edgeModeStorage.isServerRunning) {
                Divider().margin({ left: 16 })

                // 统计信息
                Row() {
                  Column() {
                    Text('请求数')
                      .fontSize(12)
                      .fontColor($r('app.color.list_item_text_secondary'))
                    Text(`${this.edgeModeStorage.requestCount}`)
                      .fontSize(20)
                      .fontWeight(FontWeight.Bold)
                      .fontColor($r('sys.color.ohos_id_color_primary'))
                  }

                  Column() {
                    Text('连接数')
                      .fontSize(12)
                      .fontColor($r('app.color.list_item_text_secondary'))
                    Text(`${this.edgeModeStorage.clientCount}`)
                      .fontSize(20)
                      .fontWeight(FontWeight.Bold)
                      .fontColor($r('sys.color.ohos_id_color_primary'))
                  }

                  Column() {
                    Text('最后请求')
                      .fontSize(12)
                      .fontColor($r('app.color.list_item_text_secondary'))
                    Text(this.edgeModeStorage.lastRequestPath || '-')
                      .fontSize(12)
                      .fontColor($r('app.color.list_item_text_primary'))
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                  }
                  .layoutWeight(1)
                }
                .width('100%')
                .height(72)
                .padding({ left: 16, right: 16 })
                .justifyContent(FlexAlign.SpaceAround)
              }
            }
            .backgroundColor($r('app.color.item_button_background'))
            .borderRadius(12)
          }

          // 端侧模式配置
          if (this.edgeModeStorage.deviceMode === DeviceMode.END_SIDE) {
            this.SectionTitle('端侧连接配置')

            Column({ space: 1 }) {
              Text('在端侧模式下，你可以在Ollama设置页面配置连接地址。\n如需连接边侧设备，请输入边侧设备的IP地址和端口。')
                .fontSize(13)
                .fontColor($r('app.color.list_item_text_secondary'))
                .width('100%')
                .lineHeight(20)
                .padding(16)

              Divider().margin({ left: 16 })

              // 边侧服务器地址（可选配置）
              Row() {
                Text('边侧服务器IP')
                  .fontColor($r('app.color.list_item_text_primary'))
                  .fontSize(16)

                Blank()

                TextInput({ text: this.edgeModeStorage.edgeServerHost, placeholder: '如：192.168.1.100' })
                  .width(160)
                  .height(40)
                  .textAlign(TextAlign.End)
                  .backgroundColor(Color.Transparent)
                  .onChange((value: string) => {
                    this.edgeModeStorage.edgeServerHost = value;
                    this.saveConfig();
                  })
              }
              .width('100%')
              .height(56)
              .padding({ left: 16, right: 16 })

              Divider().margin({ left: 16 })

              Row() {
                Text('边侧服务器端口')
                  .fontColor($r('app.color.list_item_text_primary'))
                  .fontSize(16)

                Blank()

                TextInput({ text: this.edgeModeStorage.edgeServerPort })
                  .width(100)
                  .height(40)
                  .type(InputType.Number)
                  .textAlign(TextAlign.End)
                  .backgroundColor(Color.Transparent)
                  .onChange((value: string) => {
                    this.edgeModeStorage.edgeServerPort = value;
                    this.saveConfig();
                  })
              }
              .width('100%')
              .height(56)
              .padding({ left: 16, right: 16 })

              Divider().margin({ left: 16 })

              // 应用到Ollama设置按钮
              Row() {
                Button({ type: ButtonType.Normal }) {
                  Text('应用到Ollama设置')
                    .fontSize(14)
                }
                .layoutWeight(1)
                .height(44)
                .borderRadius(12)
                .backgroundColor($r('sys.color.ohos_id_color_primary'))
                .enabled(this.edgeModeStorage.edgeServerHost !== '')
                .onClick(() => {
                  if (this.edgeModeStorage.edgeServerHost && this.edgeModeStorage.edgeServerPort) {
                    // 保存到Ollama设置
                    PreferenceModel.writeData(this.edgeModeStorage.edgeServerHost, 'ollama_setting', 'ipConfig');
                    PreferenceModel.writeData(this.edgeModeStorage.edgeServerPort, 'ollama_setting', 'portConfig');
                    // 更新OllamaStorage
                    this.ollamaStorage.ipConfig = this.edgeModeStorage.edgeServerHost;
                    this.ollamaStorage.portConfig = this.edgeModeStorage.edgeServerPort;
                    promptAction.showToast({
                      message: `已应用到Ollama设置: ${this.edgeModeStorage.edgeServerHost}:${this.edgeModeStorage.edgeServerPort}`
                    });
                    Logger.info(TAG, `Applied edge server config to Ollama: ${this.edgeModeStorage.edgeServerHost}:${this.edgeModeStorage.edgeServerPort}`);
                  } else {
                    promptAction.showToast({
                      message: '请先配置边侧服务器IP和端口'
                    });
                  }
                })
              }
              .width('100%')
              .padding({ left: 16, right: 16, top: 8, bottom: 16 })
            }
            .backgroundColor($r('app.color.item_button_background'))
            .borderRadius(12)
          }

          // 使用说明
          this.SectionTitle('使用说明')

          Column() {
            Text('两个模拟器互联测试步骤：\n\n1. 在模拟器A上选择"边侧模式"，配置Ollama地址为本地电脑IP（如10.0.2.2:11434），启动服务\n\n2. 在模拟器B上选择"端侧模式"，在Ollama设置中将地址配置为模拟器A的IP和端口\n\n3. 在模拟器B上发送消息，请求会通过模拟器A转发到本地Ollama\n\n注：模拟器访问宿主机可使用IP 10.0.2.2')
              .fontSize(13)
              .fontColor($r('app.color.list_item_text_secondary'))
              .width('100%')
              .lineHeight(20)
          }
          .padding(16)
          .backgroundColor($r('app.color.item_button_background'))
          .borderRadius(12)
        }
        .padding(16)
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .padding({ top: this.avoidArea.topRectHeight + 'px', bottom: this.avoidArea.bottomRectHeight + 'px' })
    .backgroundColor($r('sys.color.ohos_id_color_panel_bg'))
  }
}
