"use client";

import type { ThemeProviderProps } from "next-themes";

import { ThemeProvider as NextThemesProvider } from "next-themes";

export function ThemeProvider({ children, ...props }: ThemeProviderProps) {
  return <NextThemesProvider {...props}>{children}</NextThemesProvider>;
}

这个文件中没有用户可见的 UI 文本需要翻译，它只是一个主题提供者组件的封装，没有包含任何字符串文本。
