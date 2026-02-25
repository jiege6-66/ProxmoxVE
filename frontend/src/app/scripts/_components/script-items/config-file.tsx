import ConfigCopyButton from "@/components/ui/config-copy-button";

export default function ConfigFile({ configPath }: { configPath: string }) {
  return (
    <div className="px-4 pb-4">
      <ConfigCopyButton>{configPath}</ConfigCopyButton>
    </div>
  );
}

这个文件中没有用户可见的 UI 文本需要翻译。代码只包含组件结构和 props 传递，`configPath` 是动态内容，不是硬编码的英文文本。
