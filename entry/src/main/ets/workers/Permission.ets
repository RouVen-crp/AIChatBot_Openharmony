/*
 * Copyright (c) 2025 Huawei Device Co., Ltd.
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

import { Permissions } from '@ohos.abilityAccessCtrl';
import bundleManager from '@ohos.bundle.bundleManager';
import common from '@ohos.app.ability.common';
import abilityAccessCtrl from '@ohos.abilityAccessCtrl';

export function allAllowed(permissions: Permissions[]): boolean {
  if (permissions.length == 0) {
    return false;
  }

  const mgr: abilityAccessCtrl.AtManager = abilityAccessCtrl.createAtManager();
  const bundleInfo = bundleManager.getBundleInfoForSelfSync(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION);
  let tokenID: number = bundleInfo.appInfo.accessTokenId;
  return permissions.every(permission => abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED ==
  mgr.checkAccessTokenSync(tokenID, permission));
}

export async function requestPermissions(permissions: Permissions[]): Promise<boolean> {
  const mgr: abilityAccessCtrl.AtManager = abilityAccessCtrl.createAtManager();
  const context: Context = getContext() as common.UIAbilityContext;
  const result = await mgr.requestPermissionsFromUser(context, permissions);
  return result.authResults.length > 0 && result.authResults.every(authResults => authResults == 0);
}