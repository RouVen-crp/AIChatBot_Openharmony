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

import { http } from "@kit.NetworkKit";
import { BusinessError } from "@kit.BasicServicesKit";
import Logger from "../utils/Logger";
import { ISearchEngine } from "./inf/SearchInf";
import { search_result, webSearchResult } from "./model/SearchModel";

const TAG = '[baidu_search]';

export default class Baidu implements ISearchEngine {
  constructor() {
  }

  webSearch(query: string): Promise<webSearchResult[]> {
    return new Promise((resolve, reject) => {
      let httpRequest = http.createHttp();
      let searchResults: webSearchResult[] = [];
      httpRequest.request(`http://www.baidu.com/s?wd=${encodeURIComponent(query)}&tn=json&rn=5`, {
        method: http.RequestMethod.GET,
        header: [{
          'Content-Type': 'application/json'
        }],
        readTimeout: 180000,
        connectTimeout: 180000
      }, (err: BusinessError, data: http.HttpResponse) => {
        if (err || !data.result) {
          Logger.info(TAG, `search err = ${JSON.stringify(err)}`);
          httpRequest.destroy();
          return reject(err);
        }
        Logger.info(TAG, `data = ${JSON.stringify(data.result)}`);
        let result: search_result[] = JSON.parse(data.result as string)['feed']['entry'] as search_result[];
        searchResults = result.map((result: search_result) => {
          let title = result?.title || "";
          let link = result?.url;
          let content = result?.abs || "";
          let message: webSearchResult = {
            title: title,
            url: link,
            content: content
          }
          return message;
        })
        Logger.info(TAG, `dataSet = ${JSON.stringify(searchResults)}`);
        httpRequest.destroy();
        resolve(searchResults);
      })
    })
  }
}
