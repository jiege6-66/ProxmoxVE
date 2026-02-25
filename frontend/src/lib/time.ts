export function extractDate(dateString: string): string {
  const date = new Date(dateString);
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, "0");
  const day = String(date.getDate()).padStart(2, "0");
  return `${year}-${month}-${day}`;
}

这段代码中没有用户可见的 UI 文本需要翻译，它只是一个日期格式化的工具函数。
