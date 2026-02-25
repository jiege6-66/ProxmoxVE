"use client";

import { useQuery } from "@tanstack/react-query";

import type { AppVersion, GitHubVersionsResponse } from "@/lib/types";

import { fetchVersions } from "@/lib/data";

export function useVersions() {
  return useQuery<AppVersion[]>({
    queryKey: ["versions"],
    queryFn: async () => {
      const response: GitHubVersionsResponse = await fetchVersions();
      return response.versions ?? [];
    },
  });
}

这段代码中没有用户可见的 UI 文本需要翻译。代码只包含变量名、函数名和类型定义，这些都是程序逻辑的一部分，不应该翻译。
