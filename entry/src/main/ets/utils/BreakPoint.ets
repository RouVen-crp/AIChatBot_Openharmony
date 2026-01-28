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

import { display } from '@kit.ArkUI';

export type Breakpoint = 'xs' | 'sm' | 'md' | 'lg';

export interface BreakpointData<T> {
  // [x: Breakpoint]: T
  xs?: T
  sm?: T
  md?: T
  lg?: T
}

function getBreakpointByWidth(width: number): Breakpoint {
  if (width < 320) return 'xs';
  if (width < 600) return 'sm';
  if (width < 840) return 'md';
  return 'lg';
}

export function setBreakpoint(windowWidth: number): Breakpoint {
  const windowWidthVp = windowWidth / display.getDefaultDisplaySync().densityPixels;
  const breakpoint = getBreakpointByWidth(windowWidthVp);
  AppStorage.setOrCreate('breakpoint', breakpoint);
  return breakpoint;
}

export function getDataByBreakpoint<T>(breakpoint: Breakpoint, data: Record<string, T>): T {
  return data[breakpoint];
}