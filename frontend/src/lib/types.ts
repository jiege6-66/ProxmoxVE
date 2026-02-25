import type { AlertColors } from "@/config/site-config";

export type Script = {
  name: string;
  slug: string;
  categories: number[];
  date_created: string;
  type: "vm" | "ct" | "pve" | "addon" | "turnkey";
  updateable: boolean;
  privileged: boolean;
  interface_port: number | null;
  documentation: string | null;
  website: string | null;
  logo: string | null;
  config_path: string;
  description: string;
  disable?: boolean;
  disable_description?: string;
  install_methods: {
    type: "default" | "alpine";
    script: string;
    resources: {
      cpu: number | null;
      ram: number | null;
      hdd: number | null;
      os: string | null;
      version: string | null;
    };
  }[];
  default_credentials: {
    username: string | null;
    password: string | null;
  };
  notes: {
    text: string;
    type: keyof typeof AlertColors;
  }[];
};

export type Category = {
  name: string;
  id: number;
  sort_order: number;
  description: string;
  icon: string;
  scripts: Script[];
};

export type Metadata = {
  categories: Category[];
};

export type Version = {
  name: string;
  slug: string;
};

export type OperatingSystem = {
  name: string;
  versions: Version[];
};

export type AppVersion = {
  slug: string;
  repo: string;
  version: string;
  pinned: boolean;
  date: string;
};

export type GitHubVersionsResponse = {
  generated: string;
  versions: AppVersion[];
};

这个文件只包含 TypeScript 类型定义，没有用户可见的 UI 文本字符串需要翻译。所有的属性名都是代码标识符，应该保持英文不变。
