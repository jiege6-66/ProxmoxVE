import type { Category } from "./types";

export async function fetchCategories() {
  const response = await fetch(`/ProxmoxVE/api/categories`);
  if (!response.ok) {
    throw new Error(`获取分类失败: ${response.statusText}`);
  }
  const categories: Category[] = await response.json();
  return categories;
}

export async function fetchVersions() {
  const response = await fetch(`/ProxmoxVE/api/github-versions`);
  if (!response.ok) {
    throw new Error(`获取版本失败: ${response.statusText}`);
  }
  return response.json();
}
