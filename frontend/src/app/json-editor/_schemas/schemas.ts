import { z } from "zod";
import { AlertColors } from "@/config/site-config";

export const InstallMethodSchema = z.object({
  type: z.enum(["default", "alpine"], {
    message: "类型必须是 'default' 或 'alpine'",
  }),
  script: z.string().min(1, "脚本内容不能为空"),
  resources: z.object({
    cpu: z.number().nullable(),
    ram: z.number().nullable(),
    hdd: z.number().nullable(),
    os: z.string().nullable(),
    version: z.string().nullable(),
  }),
});

const NoteSchema = z.object({
  text: z.string().min(1, "备注文本不能为空"),
  type: z.enum(Object.keys(AlertColors) as [keyof typeof AlertColors, ...(keyof typeof AlertColors)[]], {
    message: `类型必须是以下之一：${Object.keys(AlertColors).join(", ")}`,
  }),
});

export const ScriptSchema = z.object({
  name: z.string().min(1, "名称为必填项"),
  slug: z.string().min(1, "Slug 为必填项"),
  categories: z.array(z.number()),
  date_created: z.string().regex(/^\d{4}-\d{2}-\d{2}$/, "日期必须为 YYYY-MM-DD 格式").min(1, "日期为必填项"),
  type: z.enum(["vm", "ct", "pve", "addon", "turnkey"], {
    message: "类型必须是 'vm'、'ct'、'pve'、'addon' 或 'turnkey'",
  }),
  updateable: z.boolean(),
  privileged: z.boolean(),
  interface_port: z.number().nullable(),
  documentation: z.string().nullable(),
  website: z.url().nullable(),
  logo: z.url().nullable(),
  config_path: z.string(),
  description: z.string().min(1, "描述为必填项"),
  disable: z.boolean().optional(),
  disable_description: z.string().optional(),
  install_methods: z.array(InstallMethodSchema).min(1, "至少需要一个安装方法"),
  default_credentials: z.object({
    username: z.string().nullable(),
    password: z.string().nullable(),
  }),
  notes: z.array(NoteSchema).optional().default([]),
}).refine((data) => {
  if (data.disable === true && !data.disable_description) {
    return false;
  }
  return true;
}, {
  message: "当 disable 为 true 时，disable_description 为必填项",
  path: ["disable_description"],
});

export type Script = z.infer<typeof ScriptSchema>;
