import type { MetadataRoute } from "next";

import { basePath } from "@/config/site-config";

export function generateStaticParams() {
  return [];
}

export default function manifest(): MetadataRoute.Manifest {
  return {
    name: "Proxmox VE 辅助脚本",
    short_name: "Proxmox VE 辅助脚本",
    description:
      "Proxmox VE 辅助脚本仓库的重新设计前端。提供超过 300 多个脚本来帮助您管理 Proxmox 虚拟环境。",
    theme_color: "#030712",
    background_color: "#030712",
    display: "standalone",
    orientation: "portrait",
    scope: `${basePath}`,
    start_url: `${basePath}`,
    icons: [
      {
        src: "logo.png",
        sizes: "512x512",
        type: "image/png",
      },
    ],
  };
}
