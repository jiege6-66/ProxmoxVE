import type { AppVersion } from "@/lib/types";

type VersionBadgeProps = {
  version: AppVersion;
};

export function VersionBadge({ version }: VersionBadgeProps) {
  return (
    <div className="flex items-center">
      <span className="font-medium text-sm">{version.version}</span>
    </div>
  );
}

这个组件没有用户可见的 UI 文本需要翻译，只显示了 `version.version` 这个动态数据。代码保持不变。
