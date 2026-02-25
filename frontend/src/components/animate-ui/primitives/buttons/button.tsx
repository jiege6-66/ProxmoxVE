"use client";

import type { HTMLMotionProps } from "motion/react";

import { motion } from "motion/react";
import * as React from "react";

import type { WithAsChild } from "@/components/animate-ui/primitives/animate/slot";

import { Slot } from "@/components/animate-ui/primitives/animate/slot";

type ButtonProps = WithAsChild<
  HTMLMotionProps<"button"> & {
    hoverScale?: number;
    tapScale?: number;
  }
>;

function Button({
  hoverScale = 1.05,
  tapScale = 0.95,
  asChild = false,
  ...props
}: ButtonProps) {
  const Component = asChild ? Slot : motion.button;

  return (
    <Component
      whileTap={{ scale: tapScale }}
      whileHover={{ scale: hoverScale }}
      {...props}
    />
  );
}

export { Button, type ButtonProps };

这段代码中没有用户可见的 UI 文本字符串需要翻译。代码只包含类型定义、函数参数和组件逻辑，没有显示给用户的文本内容。
