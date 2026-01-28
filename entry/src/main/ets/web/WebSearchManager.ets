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

import Constants from "../common/Constants";
import Logger from "../utils/Logger";
import { ISearchEngine } from "./inf/SearchInf";
import { SearchEngineType, webSearchResult } from "./model/SearchModel";
import WebSearchEngineFactory from "./WebSearchEngineFactory";

const TAG = '[WebSearchManager]';

export class WebSearchManager {
  private static instance: WebSearchManager;
  private searchEngine: ISearchEngine | undefined = undefined;

  constructor() {
  }

  public static getInstance() {
    if (!WebSearchManager.instance) {
      WebSearchManager.instance = new WebSearchManager();
      WebSearchManager.instance.init();
    }
    return WebSearchManager.instance;
  }

  private async init() {
    this.searchEngine = WebSearchEngineFactory.createSearchEngine(SearchEngineType.Baidu);
  }

  getSearchList(): Array<ResourceStr> {
    let SearchEngineDisplayArray: ResourceStr[] = [];
    let SearchEngineDisplayMap: Record<SearchEngineType, ResourceStr> = {
      [SearchEngineType.Baidu]: $r('app.string.search_baidu'),
    };

    Object.entries(SearchEngineDisplayMap).forEach(entry => {
      let value = entry[1];
      SearchEngineDisplayArray.push(value);
    });
    return SearchEngineDisplayArray;
  }

  setSearchEngine() {
  }

  public async search(query: string): Promise<webSearchResult[]> {
    if (!this.searchEngine) {
      Logger.info(TAG, `get searchEngine error`);
      throw new Error(Constants.INIT_WEB_ENGINE_ERROR);
    }
    return this.searchEngine.webSearch(query);
  }
}