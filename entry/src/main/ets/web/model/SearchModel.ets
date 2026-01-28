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

export interface webSearchResult {
  url: string;
  content: string;
  title: string;
}

export interface Category {
  label: string;
  value: string;
}

export interface search_result {
  title: string;
  url: string;
  urlEnc: string;
  source: string | null;
  category: Category;
  abs: string;
  imgUrl: string;
  time: string | null;
  relate: number;
  same: string | null;
  pn: number;
}

export enum SearchEngineType {
  Baidu = "Baidu",
}
