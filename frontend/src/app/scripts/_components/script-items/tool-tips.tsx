import { CircleHelp } from "lucide-react";
import React from "react";

import type { BadgeProps } from "@/components/ui/badge";
import type { Script } from "@/lib/types";

import { Tooltip, TooltipContent, TooltipProvider, TooltipTrigger } from "@/components/ui/tooltip";
import { Badge } from "@/components/ui/badge";
import { cn } from "@/lib/utils";

type TooltipProps = {
  variant: BadgeProps["variant"];
  label: string;
  content?: string;
};

const TooltipBadge: React.FC<TooltipProps> = ({ variant, label, content }) => (
  <TooltipProvider>
    <Tooltip delayDuration={100}>
      <TooltipTrigger className={cn("flex items-center", !content && "cursor-default")}>
        <Badge variant={variant} className="flex items-center gap-1">
          {label}
          {" "}
          {content && <CircleHelp className="size-3" />}
        </Badge>
      </TooltipTrigger>
      {content && (
        <TooltipContent side="bottom" className="text-sm max-w-64">
          {content}
        </TooltipContent>
      )}
    </Tooltip>
  </TooltipProvider>
);

export default function Tooltips({ item }: { item: Script }) {
  return (
    <div className="flex items-center gap-2">
      {item.privileged && (
        <TooltipBadge variant="warning" label="特权模式" content="此脚本将在特权 LXC 中运行" />
      )}
      {item.updateable && item.type !== "pve" && (
        <TooltipBadge
          variant="success"
          label="可更新"
          content={`要更新 ${item.name}，请在 LXC 控制台中运行以下命令（或输入 update）。`}
        />
      )}
      {!item.updateable && item.type !== "pve" && <TooltipBadge variant="failure" label="不可更新" />}
    </div>
  );
}
