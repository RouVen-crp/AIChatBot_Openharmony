/*
 * Copyright (c) 2025 Hunan OpenValley Digital Industry Development Co., Ltd. & Huawei Device Co., Ltd.
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

import { connection } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
import Logger from './Logger';

const TAG = '[net_judge]';

export class NetJudge {
  public static netConnection: connection.NetConnection | undefined = undefined;
  private static JUDGE_NET_TAG: string = 'NetJudge.currNet.isUseful';
  public netAvailable: boolean = false;

  init() {
    NetJudge.netConnection = connection.createNetConnection();
    NetJudge.netConnection.register(() => {
      Logger.info(TAG, 'connection register success');
    });

    NetJudge.netConnection.on('netAvailable', (data) => {
      Logger.info(TAG, 'NetJudge  netAvailable ');
      AppStorage.setOrCreate(NetJudge.JUDGE_NET_TAG, this.judgeHasNet());
      this.netAvailable = true;
    });

    NetJudge.netConnection.on('netUnavailable', () => {
      Logger.info(TAG, 'NetJudge  netUnavailable ');
      AppStorage.setOrCreate(NetJudge.JUDGE_NET_TAG, this.judgeHasNet());
      this.netAvailable = false;
    });

    NetJudge.netConnection.on('netCapabilitiesChange', (data: connection.NetCapabilityInfo) => {
      AppStorage.setOrCreate(NetJudge.JUDGE_NET_TAG, this.judgeHasNet());
    });

    // 订阅网络连接信息变化事件。调用register后，才能接收到此事件通知
    NetJudge.netConnection.on('netConnectionPropertiesChange', (data: connection.NetConnectionPropertyInfo) => {
      AppStorage.setOrCreate(NetJudge.JUDGE_NET_TAG, this.judgeHasNet());
    });

    NetJudge.netConnection.on('netLost', () => {
      Logger.info(TAG, 'NetJudge  netLost ');
      AppStorage.setOrCreate(NetJudge.JUDGE_NET_TAG, this.judgeHasNet());
      this.netAvailable = false;
    });
  }

  regist() {
    if (NetJudge.netConnection === undefined) {
      this.init();
    }
  }

  judgeHasNet(): boolean {
    try { // 获取当前网络连接
      let netHandle = connection.getDefaultNetSync();

      // 0-100 为系统预留的连接
      if (!netHandle || netHandle.netId < 100) {
        return false;
      }

      // 获取连接的属性
      let netCapability = connection.getNetCapabilitiesSync(netHandle);
      let cap = netCapability.networkCap;
      if (!cap) {
        return false;
      }

      for (let em of cap) {
        if (connection.NetCap.NET_CAPABILITY_VALIDATED === em) {
          return true;
        }
      }
    } catch (e) {
      let err = e as BusinessError;
      Logger.error(TAG, 'get netInfo error ：' + JSON.stringify(err));
    }
    return false;
  }
}

export default new NetJudge();