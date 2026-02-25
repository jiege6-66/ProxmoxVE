import type { ClassValue } from "clsx";

import { twMerge } from "tailwind-merge";
import { clsx } from "clsx";

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}

这个文件中没有用户可见的 UI 文本需要翻译。它只包含一个工具函数 `cn`，用于合并 CSS 类名，没有任何字符串文字或用户界面文本。
