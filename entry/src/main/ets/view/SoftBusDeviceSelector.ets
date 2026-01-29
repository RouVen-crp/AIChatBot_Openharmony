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
import { OllamaStorage } from "../model/setting/OllamaStorage";
import { AvoidArea } from "../model/layout/AvoidData";
import { NormalTitle } from "../component/NormalTitle";
import { DeviceManager, DeviceManagerState } from "../transport/softbus/DeviceManager";
import { DeviceInfo } from "../transport/softbus/SoftBusProtocol";
import PreferenceModel from "../preference/PreferenceModel";
import Logger from "../utils/Logger";

const TAG = '[softbus_device_selector]';

/**
 * 获取设备类型图标
 * 使用项目中已有的图标资源
 */
function getDeviceTypeIcon(deviceType: number): Resource {
  // 由于项目中可能没有专门的设备类型图标，使用通用图标
  // 后续可以根据需要添加具体的设备图标
  return $r('app.media.externaldrive');
}

/**
 * 获取设备类型名称
 */
function getDeviceTypeName(deviceType: number): string {
  switch (deviceType) {
    case 1:
      return '手机';
    case 2:
      return '平板';
    case 3:
      return '电视';
    case 4:
      return '电脑';
    case 5:
      return '手表';
    default:
      return '未知设备';
  }
}

@Builder
export function softBusDeviceSelectorBuilder(name: string, param: Object) {
  SoftBusDeviceSelector()
}

@Entry
@ComponentV2
struct SoftBusDeviceSelector {
  @Local avoidArea: AvoidArea = AppStorageV2.connect(AvoidArea, 'AvoidArea', () => new AvoidArea())!;
  @Local ollamaStorage: OllamaStorage =
    AppStorageV2.connect(OllamaStorage, 'OllamaStorage', () => new OllamaStorage())!;

  private deviceManager: DeviceManager = DeviceManager.getInstance();

  aboutToAppear(): void {
    // 初始化设备管理器
    this.initDeviceManager();

    // 注册设备发现回调
    this.deviceManager.onDeviceDiscover((device: DeviceInfo) => {
      Logger.info(TAG, `Device discovered: ${device.deviceName}`);
      // 更新发现的设备列表
      const exists = this.ollamaStorage.discoveredDevices.some(d => d.deviceId === device.deviceId);
      if (!exists) {
        this.ollamaStorage.discoveredDevices = [...this.ollamaStorage.discoveredDevices, device];
      }
    });

    // 注册设备状态变化回调
    this.deviceManager.onDeviceStateChange((device: DeviceInfo, state: 'online' | 'offline' | 'changed') => {
      Logger.info(TAG, `Device state changed: ${device.deviceName} -> ${state}`);
      if (state === 'offline') {
        this.ollamaStorage.discoveredDevices =
          this.ollamaStorage.discoveredDevices.filter(d => d.deviceId !== device.deviceId);
        if (this.ollamaStorage.selectedDeviceId === device.deviceId) {
          this.ollamaStorage.selectedDeviceId = '';
          this.ollamaStorage.selectedDeviceName = '';
          this.ollamaStorage.isSoftBusConnected = false;
        }
      }
    });
  }

  aboutToDisappear(): void {
    // 停止设备发现
    if (this.ollamaStorage.isDiscovering) {
      this.deviceManager.stopDiscovery();
      this.ollamaStorage.isDiscovering = false;
    }
  }

  async initDeviceManager(): Promise<void> {
    const bundleName = 'com.example.aimodelchat';
    const initialized = await this.deviceManager.initialize(bundleName);
    if (!initialized) {
      Logger.warn(TAG, 'DeviceManager initialization failed (expected in simulator)');
    }
  }

  async startDiscovery(): Promise<void> {
    if (this.deviceManager.getState() === DeviceManagerState.UNINITIALIZED) {
      promptAction.showToast({ message: $r('app.string.softbus_not_supported') });
      return;
    }

    this.ollamaStorage.isDiscovering = true;
    this.ollamaStorage.discoveredDevices = [];

    const started = await this.deviceManager.startDiscovery();
    if (!started) {
      this.ollamaStorage.isDiscovering = false;
      promptAction.showToast({ message: $r('app.string.softbus_not_supported') });
    }
  }

  stopDiscovery(): void {
    this.deviceManager.stopDiscovery();
    this.ollamaStorage.isDiscovering = false;
  }

  async connectToDevice(device: DeviceInfo): Promise<void> {
    // 先进行设备认证
    const authenticated = await this.deviceManager.authenticateDevice(device.deviceId);
    if (!authenticated) {
      promptAction.showToast({ message: '设备认证失败，请在模拟器上使用HTTP模式' });
      return;
    }

    // 保存选中的设备
    this.ollamaStorage.selectedDeviceId = device.deviceId;
    this.ollamaStorage.selectedDeviceName = device.deviceName;
    this.ollamaStorage.isSoftBusConnected = true;

    // 保存到偏好设置
    PreferenceModel.writeData(device.deviceId, 'ollama_setting', 'softbus_deviceId');
    PreferenceModel.writeData(device.deviceName, 'ollama_setting', 'softbus_deviceName');

    promptAction.showToast({ message: $r('app.string.softbus_connected') });
  }

  disconnectDevice(): void {
    this.ollamaStorage.selectedDeviceId = '';
    this.ollamaStorage.selectedDeviceName = '';
    this.ollamaStorage.isSoftBusConnected = false;

    PreferenceModel.writeData('', 'ollama_setting', 'softbus_deviceId');
    PreferenceModel.writeData('', 'ollama_setting', 'softbus_deviceName');
  }

  @Builder
  DeviceItem(device: DeviceInfo) {
    Row() {
      Image(getDeviceTypeIcon(device.deviceType))
        .width(40)
        .height(40)
        .margin({ right: 12 })
        .fillColor($r('sys.color.ohos_id_color_primary'))

      Column() {
        Text(device.deviceName)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.list_item_text_primary'))

        Text(getDeviceTypeName(device.deviceType))
          .fontSize(12)
          .fontColor($r('app.color.list_item_text_secondary'))
          .margin({ top: 4 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      if (this.ollamaStorage.selectedDeviceId === device.deviceId) {
        Image($r('app.media.ic_public_check_update'))
          .width(24)
          .height(24)
          .fillColor($r('sys.color.ohos_id_color_primary'))
      }
    }
    .width('100%')
    .height(72)
    .padding({ left: 16, right: 16 })
    .backgroundColor($r('app.color.item_button_background'))
    .borderRadius(12)
    .onClick(() => {
      this.connectToDevice(device);
    })
  }

  build() {
    Column() {
      NormalTitle()

      Column({ space: 16 }) {
        // 标题和说明
        Column({ space: 8 }) {
          Text($r('app.string.softbus_device_discovery'))
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.list_item_text_primary'))

          Text('搜索局域网内的鸿蒙设备，选择边侧设备进行连接。\n注意：此功能需要在真机上运行，模拟器不支持软总线。')
            .fontSize(14)
            .fontColor($r('app.color.list_item_text_secondary'))
            .lineHeight(20)
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)

        // 当前连接状态
        if (this.ollamaStorage.isSoftBusConnected && this.ollamaStorage.selectedDeviceName) {
          Row() {
            Column() {
              Text('已连接设备')
                .fontSize(14)
                .fontColor($r('app.color.list_item_text_secondary'))

              Text(this.ollamaStorage.selectedDeviceName)
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .fontColor($r('sys.color.ohos_id_color_primary'))
                .margin({ top: 4 })
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)

            Button($r('app.string.softbus_disconnect'))
              .type(ButtonType.Normal)
              .height(36)
              .borderRadius(18)
              .backgroundColor($r('sys.color.ohos_id_color_warning'))
              .onClick(() => {
                this.disconnectDevice();
              })
          }
          .width('100%')
          .padding(16)
          .backgroundColor($r('app.color.item_button_background'))
          .borderRadius(12)
        }

        // 搜索按钮
        Row({ space: 12 }) {
          if (this.ollamaStorage.isDiscovering) {
            LoadingProgress()
              .width(24)
              .height(24)
              .color($r('sys.color.ohos_id_color_primary'))

            Text('正在搜索设备...')
              .fontSize(14)
              .fontColor($r('app.color.list_item_text_secondary'))

            Blank()

            Button($r('app.string.softbus_stop_discovery'))
              .type(ButtonType.Normal)
              .height(36)
              .borderRadius(18)
              .onClick(() => {
                this.stopDiscovery();
              })
          } else {
            Button($r('app.string.softbus_start_discovery'))
              .type(ButtonType.Normal)
              .height(40)
              .width('100%')
              .borderRadius(20)
              .onClick(() => {
                this.startDiscovery();
              })
          }
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)

        // 设备列表
        if (this.ollamaStorage.discoveredDevices.length > 0) {
          Column({ space: 8 }) {
            Text('发现的设备')
              .fontSize(14)
              .fontColor($r('app.color.list_item_text_secondary'))
              .width('100%')

            ForEach(this.ollamaStorage.discoveredDevices, (device: DeviceInfo) => {
              this.DeviceItem(device)
            })
          }
          .width('100%')
        } else if (!this.ollamaStorage.isDiscovering) {
          Column() {
            Image($r('app.media.externaldrive'))
              .width(64)
              .height(64)
              .opacity(0.3)
              .margin({ bottom: 16 })

            Text($r('app.string.softbus_no_device_found'))
              .fontSize(14)
              .fontColor($r('app.color.list_item_text_secondary'))
          }
          .width('100%')
          .height(200)
          .justifyContent(FlexAlign.Center)
        }
      }
      .padding(16)
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .padding({ top: this.avoidArea.topRectHeight + 'px', bottom: this.avoidArea.bottomRectHeight + 'px' })
    .backgroundColor($r('sys.color.ohos_id_color_panel_bg'))
  }
}
