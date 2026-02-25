import type { MetadataRoute } from "next";

import { basePath } from "@/config/site-config";

export const dynamic = "force-static";

export default async function sitemap(): Promise<MetadataRoute.Sitemap> {
  const domain = "community-scripts.github.io";
  const protocol = "https";
  return [
    {
      url: `${protocol}://${domain}/${basePath}`,
      lastModified: new Date(),
    },
    {
      url: `${protocol}://${domain}/${basePath}/scripts`,
      lastModified: new Date(),
    },
    {
      url: `${protocol}://${domain}/${basePath}/json-editor`,
      lastModified: new Date(),
    },
  ];
}

代码中没有用户可见的 UI 文本需要翻译，所有字符串都是 URL 路径和配置值。
