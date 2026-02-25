import * as React from "react";

function getStrictContext<T>(
  name?: string,
): readonly [
    ({
      value,
      children,
    }: {
      value: T;
      children?: React.ReactNode;
    }) => React.JSX.Element,
    () => T,
  ] {
  const Context = React.createContext<T | undefined>(undefined);

  const Provider = ({
    value,
    children,
  }: {
    value: T;
    children?: React.ReactNode;
  }) => <Context.Provider value={value}>{children}</Context.Provider>;

  const useSafeContext = () => {
    const ctx = React.useContext(Context);
    if (ctx === undefined) {
      throw new Error(`useContext 必须在 ${name ?? "Provider"} 内部使用`);
    }
    return ctx;
  };

  return [Provider, useSafeContext] as const;
}

export { getStrictContext };
