import type { MetadataRoute } from "next";

import { basePath } from "@/config/site-config";

export const dynamic = "force-static";

export default function robots(): MetadataRoute.Robots {
  return {
    rules: {
      userAgent: "*",
      allow: "/",
    },
    sitemap: `https://community-scripts.github.io/${basePath}/sitemap.xml`,
  };
}

这个文件中没有用户可见的 UI 文本需要翻译。它只包含 robots.txt 的配置信息，这些都是技术性的配置项，不是面向用户的界面文字。
