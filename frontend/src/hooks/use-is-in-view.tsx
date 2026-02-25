import type { UseInViewOptions } from "motion/react";

import { useInView } from "motion/react";
import * as React from "react";

type UseIsInViewOptions = {
  inView?: boolean;
  inViewOnce?: boolean;
  inViewMargin?: UseInViewOptions["margin"];
};

function useIsInView<T extends HTMLElement = HTMLElement>(
  ref: React.Ref<T>,
  options: UseIsInViewOptions = {},
) {
  const { inView, inViewOnce = false, inViewMargin = "0px" } = options;
  const localRef = React.useRef<T>(null);
  React.useImperativeHandle(ref, () => localRef.current as T);
  const inViewResult = useInView(localRef, {
    once: inViewOnce,
    margin: inViewMargin,
  });
  const isInView = !inView || inViewResult;
  return { ref: localRef, isInView };
}

export { useIsInView, type UseIsInViewOptions };

这段代码中没有用户可见的 UI 文本需要翻译，所有内容都是代码逻辑、类型定义和变量名。
