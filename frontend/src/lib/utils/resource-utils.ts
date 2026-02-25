export function getDisplayValueFromRAM(ram: number): string {
  return ram >= 1024 ? `${Math.floor(ram / 1024)}GB` : `${ram}MB`;
}

export function cleanSlug(slug: string): string {
  return slug.replace(/[^a-z0-9]/gi, "").toLowerCase();
}

这段代码中没有用户可见的 UI 文本需要翻译。代码只包含函数逻辑和单位标识（GB、MB），这些通常保持不变。
