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

import { preferences } from '@kit.ArkData';
import { common, UIAbility } from '@kit.AbilityKit';
import Logger from '../utils/Logger';

const TAG: string = 'PreferenceModel';

let preference: preferences.Preferences;
let preferenceTemp: preferences.Preferences;

/**
 * Preference model.
 *
 */
class PreferenceModel {
  context: common.UIAbilityContext | undefined;

  /**
   * Read the specified Preferences persistence file and load the data into the Preferences instance.
   */
  getPreferencesFromStorage(context: common.UIAbilityContext, db_name: string) {
    let options: preferences.Options = { name: db_name };
    this.context = context;
    try {
      preference = preferences.getPreferencesSync(context, options);
    } catch (err) {
      Logger.info(TAG, `Failed to get preferences, Cause: ${err}`);
    }
  }

  /**
   * Deletes the specified Preferences persistence file from memory and removes the Preferences instance.
   */
  async deletePreferences(db_name: string) {
    try {
      await preferences.deletePreferences(this.context, db_name);
    } catch (err) {
      Logger.error(TAG, `Failed to delete preferences, Cause: ${err}`);
    }
    ;
    preference = preferenceTemp;
  }

  /**
   * Save the data to the Preferences.
   *
   */
  putPreference(data: string, db_name: string, key: string) {
    if (!preference) {
      this.getPreferencesFromStorage(this.context!, db_name);
    }
    // The fruit name and fruit quantity data entered by the user are saved to the cached Preference instance.
    try {
      preference.putSync(key, data);
    } catch (err) {
      Logger.error(TAG, `Failed to put value, Cause: ${err}`);
    }
    // Store the Preference instance in the preference persistence file
    preference.flush();
  }

  /**
   * Get preference data.
   */
  getPreference(db_name: string, key: string) {
    let storage = '';
    if (!preference) {
      this.getPreferencesFromStorage(this.context!, db_name);
    }
    try {
      storage = (preference.getSync(key, '')).toString();
    } catch (err) {
      Logger.error(TAG, `Failed to get value, Cause: ${err}`);
    }
    // If the data is empty, a message is displayed indicating that data needs to be written.
    if (storage === '') {
      return '';
    }
    return storage;
  }

  /**
   * Process the data obtained from the database.
   */
  getData(db_name: string, key: string): string {
    return this.getPreference(db_name, key);
  }

  /**
   * write data.
   *
   */
  writeData(data: string, db_name: string, key: string) {
    // The data is inserted into the preferences database if it is not empty.
    this.putPreference(data, db_name, key);
    Logger.info(TAG, `${db_name}: key:${key} value:${data}写入成功`)
  }
}

export default new PreferenceModel();