"use client";

import type { z } from "zod";

import { CalendarIcon, Check, Clipboard, Download } from "lucide-react";
import { useCallback, useEffect, useMemo, useState } from "react";
import { format } from "date-fns";
import { toast } from "sonner";

import type { Category } from "@/lib/types";

import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Popover, PopoverContent, PopoverTrigger } from "@/components/ui/popover";
import { Alert, AlertDescription, AlertTitle } from "@/components/ui/alert";
import { Calendar } from "@/components/ui/calendar";
import { Textarea } from "@/components/ui/textarea";
import { Button } from "@/components/ui/button";
import { Switch } from "@/components/ui/switch";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { fetchCategories } from "@/lib/data";
import { cn } from "@/lib/utils";

import type { Script } from "./_schemas/schemas";

import InstallMethod from "./_components/install-method";
import { ScriptSchema } from "./_schemas/schemas";
import Categories from "./_components/categories";
import Note from "./_components/note";

import { githubGist, nord } from "react-syntax-highlighter/dist/esm/styles/hljs";
import SyntaxHighlighter from "react-syntax-highlighter";
import { ScriptItem } from "../scripts/_components/script-item";
import { DropdownMenu, DropdownMenuContent, DropdownMenuGroup, DropdownMenuItem, DropdownMenuTrigger } from "@/components/ui/dropdown-menu";
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle, DialogTrigger } from "@/components/ui/dialog";
import { search } from "@/components/command-menu";
import { basePath } from "@/config/site-config";
import Image from "next/image";
import { useTheme } from "next-themes";

const initialScript: Script = {
  name: "",
  slug: "",
  categories: [],
  date_created: format(new Date(), "yyyy-MM-dd"),
  type: "ct",
  updateable: false,
  privileged: false,
  interface_port: null,
  documentation: null,
  config_path: "",
  website: null,
  logo: null,
  description: "",
  disable: undefined,
  disable_description: undefined,
  install_methods: [],
  default_credentials: {
    username: null,
    password: null,
  },
  notes: [],
};

export default function JSONGenerator() {
  const { theme } = useTheme();
  const [script, setScript] = useState<Script>(initialScript);
  const [isCopied, setIsCopied] = useState(false);
  const [isValid, setIsValid] = useState(false);
  const [categories, setCategories] = useState<Category[]>([]);
  const [currentTab, setCurrentTab] = useState<"json" | "preview">("json");
  const [selectedCategory, setSelectedCategory] = useState<string>("");
  const [searchQuery, setSearchQuery] = useState<string>("");
  const [isImportDialogOpen, setIsImportDialogOpen] = useState(false);
  const [zodErrors, setZodErrors] = useState<z.ZodError | null>(null);

  const selectedCategoryObj = useMemo(
    () => categories.find(cat => cat.id.toString() === selectedCategory),
    [categories, selectedCategory]
  );

  const allScripts = useMemo(
    () => categories.flatMap(cat => cat.scripts || []),
    [categories]
  );

  const scripts = useMemo(() => {
    const query = searchQuery.trim()

    if (query) {
      return search(allScripts, query)
    }

    if (selectedCategoryObj) {
      return selectedCategoryObj.scripts || []
    }

    return []
  }, [allScripts, selectedCategoryObj, searchQuery]);

  useEffect(() => {
    fetchCategories()
      .then(setCategories)
      .catch((error) => console.error("Error fetching categories:", error));
  }, []);

  useEffect(() => {
    if (!isValid && currentTab === "preview") {
      setCurrentTab("json");
      toast.error("由于配置无效，已切换到 JSON 标签页。");
    }
  }, [isValid, currentTab]);

  const updateScript = useCallback((key: keyof Script, value: Script[keyof Script]) => {
    setScript((prev) => {
      const updated = { ...prev, [key]: value };

      if (updated.slug && updated.type) {
        updated.install_methods = updated.install_methods.map((method) => {
          let scriptPath = "";

          if (updated.type === "pve") {
            scriptPath = `tools/pve/${updated.slug}.sh`;
          } else if (updated.type === "addon") {
            scriptPath = `tools/addon/${updated.slug}.sh`;
          } else if (method.type === "alpine") {
            scriptPath = `${updated.type}/alpine-${updated.slug}.sh`;
          } else {
            scriptPath = `${updated.type}/${updated.slug}.sh`;
          }

          return {
            ...method,
            script: scriptPath,
          };
        });
      }

      const result = ScriptSchema.safeParse(updated);
      setIsValid(result.success);
      setZodErrors(result.success ? null : result.error);
      return updated;
    });
  }, []);

  const handleCopy = useCallback(() => {
    if (!isValid) toast.warning("JSON 架构无效。仍然复制。");
    navigator.clipboard.writeText(JSON.stringify(script, null, 2));
    setIsCopied(true);
    setTimeout(() => setIsCopied(false), 2000);
    if (isValid) toast.success("已复制元数据到剪贴板");
  }, [script]);

  const importScript = (script: Script) => {
    try {
      const result = ScriptSchema.safeParse(script);
      if (!result.success) {
        setIsValid(false);
        setZodErrors(result.error);
        toast.error("导入的 JSON 不符合架构。");
        return;
      }

      setScript(result.data);
      setIsValid(true);
      setZodErrors(null);
      toast.success("成功导入 JSON");
    } catch (error) {
      toast.error("读取或解析 JSON 文件失败。");
    }

  }

  const handleFileImport = useCallback(() => {
    const input = document.createElement("input");
    input.type = "file";
    input.accept = "application/json";

    input.onchange = (e: Event) => {
      const target = e.target as HTMLInputElement;
      const file = target.files?.[0];
      if (!file) return;

      const reader = new FileReader();
      reader.onload = (event) => {
        try {
          const content = event.target?.result as string;
          const parsed = JSON.parse(content);
          importScript(parsed);
          toast.success("成功导入 JSON");
        } catch (error) {
          toast.error("读取 JSON 文件失败。");
        }
      };
      reader.readAsText(file);
    };

    input.click();
  }, [setScript]);

  const handleDownload = useCallback(() => {
    if (isValid === false) {
      toast.error("无法下载无效的 JSON");
      return;
    }
    const jsonString = JSON.stringify(script, null, 2);
    const blob = new Blob([jsonString], { type: "application/json" });
    const url = URL.createObjectURL(blob);

    const a = document.createElement("a");
    a.href = url;
    a.download = `${script.slug || "script"}.json`;
    document.body.appendChild(a);
    a.click();

    URL.revokeObjectURL(url);
    document.body.removeChild(a);
  }, [script]);

  const handleDateSelect = useCallback(
    (date: Date | undefined) => {
      updateScript("date_created", format(date || new Date(), "yyyy-MM-dd"));
    },
    [updateScript],
  );

  const formattedDate = useMemo(
    () => (script.date_created ? format(script.date_created, "PPP") : undefined),
    [script.date_created],
  );

  const validationAlert = useMemo(
    () => (
      <Alert className={cn("text-black", isValid ? "bg-green-100" : "bg-red-100")}>
        <AlertTitle>{isValid ? "有效的 JSON" : "无效的 JSON"}</AlertTitle>
        <AlertDescription>
          {isValid
            ? "当前 JSON 符合架构要求。"
            : "当前 JSON 不符合所需架构。"}
        </AlertDescription>
        {zodErrors && (
          <div className="mt-2 space-y-1">
            {zodErrors.issues.map((error, index) => (
              <AlertDescription key={index} className="p-1 text-red-500">
                {error.path.join(".")} -{error.message}
              </AlertDescription>
            ))}
          </div>
        )}
      </Alert>
    ),
    [isValid, zodErrors],
  );

  return (
    <div className="flex h-screen mt-20">
      <div className="w-1/2 p-4 overflow-y-auto">
        <div className="flex justify-between items-center mb-4">
          <h2 className="text-2xl font-bold">JSON 生成器</h2>
          <DropdownMenu>
            <DropdownMenuTrigger asChild>
              <Button>导入</Button>
            </DropdownMenuTrigger>
            <DropdownMenuContent className="w-52" align="start">
              <DropdownMenuGroup>
                <DropdownMenuItem onSelect={handleFileImport}>导入本地 JSON 文件</DropdownMenuItem>
                <Dialog
                  open={isImportDialogOpen}
                  onOpenChange={setIsImportDialogOpen}
                >
                  <DialogTrigger asChild>
                    <DropdownMenuItem onSelect={(e) => e.preventDefault()}>
                      导入现有脚本
                    </DropdownMenuItem>
                  </DialogTrigger>
                  <DialogContent className="sm:max-w-md w-full">
                    <DialogHeader>
                      <DialogTitle>导入现有脚本</DialogTitle>
                      <DialogDescription>
                        选择一个已发布的脚本以导入其元数据。
                      </DialogDescription>

                    </DialogHeader>
                    <div className="flex items-center gap-2">
                      <div className="grid flex-1 gap-2">
                        <Select
                          value={selectedCategory}
                          onValueChange={setSelectedCategory}
                        >
                          <SelectTrigger>
                            <SelectValue placeholder="分类" />
                          </SelectTrigger>
                          <SelectContent>
                            {categories.map((category) => (
                              <SelectItem key={category.id} value={category.id.toString()}>
                                {category.name}
                              </SelectItem>
                            ))}
                          </SelectContent>
                        </Select>
                        <Input
                          placeholder="搜索脚本..."
                          value={searchQuery}
                          onChange={(e) => setSearchQuery(e.target.value)}
                        />
                        {!selectedCategory && !searchQuery ? (
                          <p className="text-muted-foreground text-sm text-center">
                            选择一个分类或搜索脚本
                          </p>
                        ) : scripts.length === 0 ? (
                          <p className="text-muted-foreground text-sm text-center">
                            未找到脚本
                          </p>
                        ) : (
                          <div className="grid grid-cols-3 auto-rows-min h-64 overflow-y-auto gap-4">
                            {scripts.map(script => (
                              <div
                                key={script.slug}
                                className="p-2 border rounded cursor-pointer hover:bg-accent hover:text-accent-foreground"
                                onClick={() => {
                                  importScript(script);
                                  setIsImportDialogOpen(false);
                                }}
                              >
                                <Image
                                  src={script.logo || `/${basePath}/logo.png`}
                                  alt={script.name}
                                  className="w-full h-12 object-contain mb-2"
                                  width={16}
                                  height={16}
                                  unoptimized
                                />
                                <p className="text-sm text-center">{script.name}</p>
                              </div>
                            ))}
                          </div>
                        )}
                      </div>
                    </div>
                  </DialogContent>
                </Dialog>
              </DropdownMenuGroup>
            </DropdownMenuContent>
          </DropdownMenu>
        </div>
        <form className="space-y-4">
          <div className="grid grid-cols-2 gap-4">
            <div>
              <Label>
                名称 <span className="text-red-500">*</span>
              </Label>
              <Input placeholder="示例" value={script.name} onChange={(e) => updateScript("name", e.target.value)} />
            </div>
            <div>
              <Label>
                标识符 <span className="text-red-500">*</span>
              </Label>
              <Input placeholder="example" value={script.slug} onChange={(e) => updateScript("slug", e.target.value)} />
            </div>
          </div>
          <div>
            <Label>
              Logo
            </Label>
            <Input
              placeholder="完整 logo URL"
              value={script.logo || ""}
              onChange={(e) => updateScript("logo", e.target.value || null)}
            />
          </div>
          <div>
            <Label>配置路径</Label>
            <Input
              placeholder="配置文件路径"
              value={script.config_path || ""}
              onChange={(e) => updateScript("config_path", e.target.value || "")}
            />
          </div>
          <div>
            <Label>
              描述 <span className="text-red-500">*</span>
            </Label>
            <Textarea
              placeholder="示例"
              value={script.description}
              onChange={(e) => updateScript("description", e.target.value)}
            />
          </div>
          <Categories script={script} setScript={setScript} categories={categories} />
          <div className="flex gap-2">
            <div className="flex flex-col gap-2 w-full">
              <Label>
                创建日期 <span className="text-red-500">*</span>
              </Label>
              <Popover>
                <PopoverTrigger asChild className="flex-1">
                  <Button
                    variant="outline"
                    className={cn("pl-3 text-left font-normal w-full", !script.date_created && "text-muted-foreground")}
                  >
                    {formattedDate || <span>选择日期</span>}
                    <CalendarIcon className="ml-auto h-4 w-4 opacity-50" />
                  </Button>
                </PopoverTrigger>
                <PopoverContent className="w-auto p-0" align="start">
                  <Calendar
                    mode="single"
                    selected={new Date(script.date_created)}
                    onSelect={handleDateSelect}
                    autoFocus
                  />
                </PopoverContent>
              </Popover>
            </div>
            <div className="flex flex-col gap-2 w-full">
              <Label>类型</Label>
              <Select value={script.type} onValueChange={(value) => updateScript("type", value)}>
                <SelectTrigger className="flex-1">
                  <SelectValue placeholder="类型" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="ct">LXC 容器</SelectItem>
                  <SelectItem value="vm">虚拟机</SelectItem>
                  <SelectItem value="pve">PVE 工具</SelectItem>
                  <SelectItem value="addon">附加组件</SelectItem>
                </SelectContent>
              </Select>
            </div>
          </div>
          <div className="w-full flex gap-5">
            <div className="flex items-center space-x-2">
              <Switch checked={script.updateable} onCheckedChange={(checked) => updateScript("updateable", checked)} />
              <label>可更新</label>
            </div>
            <div className="flex items-center space-x-2">
              <Switch checked={script.privileged} onCheckedChange={(checked) => updateScript("privileged", checked)} />
              <label>特权模式</label>
            </div>
            <div className="flex items-center space-x-2">
              <Switch
                checked={script.disable || false}
                onCheckedChange={(checked) => updateScript("disable", checked)}
              />
              <label>已禁用</label>
            </div>
          </div>
          {script.disable && (
            <div>
              <Label>
                禁用说明 <span className="text-red-500">*</span>
              </Label>
              <Textarea
                placeholder="解释为什么禁用此脚本..."
                value={script.disable_description || ""}
                onChange={(e) => updateScript("disable_description", e.target.value)}
              />
            </div>
          )}
          <Input
            placeholder="接口端口"
            type="number"
            value={script.interface_port || ""}
            onChange={(e) => updateScript("interface_port", e.target.value ? Number(e.target.value) : null)}
          />
          <div className="flex gap-2">
            <Input
              placeholder="网站 URL"
              value={script.website || ""}
              onChange={(e) => updateScript("website", e.target.value || null)}
            />
            <Input
              placeholder="文档 URL"
              value={script.documentation || ""}
              onChange={(e) => updateScript("documentation", e.target.value || null)}
            />
          </div>
          <InstallMethod script={script} setScript={setScript} setIsValid={setIsValid} setZodErrors={setZodErrors} />
          <h3 className="text-xl font-semibold">默认凭据</h3>
          <Input
            placeholder="用户名"
            value={script.default_credentials.username || ""}
            onChange={(e) =>
              updateScript("default_credentials", {
                ...script.default_credentials,
                username: e.target.value || null,
              })
            }
          />
          <Input
            placeholder="密码"
            value={script.default_credentials.password || ""}
            onChange={(e) =>
              updateScript("default_credentials", {
                ...script.default_credentials,
                password: e.target.value || null,
              })
            }
          />
          <Note script={script} setScript={setScript} setIsValid={setIsValid} setZodErrors={setZodErrors} />
        </form>
      </div>
      <div className="w-1/2 p-4 bg-background overflow-y-auto">
        <Tabs
          defaultValue="json"
          className="w-full"
          onValueChange={(value) => setCurrentTab(value as "json" | "preview")}
          value={currentTab}
        >
          <TabsList className="grid w-full grid-cols-2">
            <TabsTrigger value="json">JSON</TabsTrigger>
            <TabsTrigger disabled={!isValid} value="preview">预览</TabsTrigger>
          </TabsList>
          <TabsContent value="json" className="h-full w-full">
            {validationAlert}
            <div className="relative">
              <div className="absolute right-2 top-2 flex gap-1">
                <Button size="icon" variant="outline" onClick={handleCopy}>
                  {isCopied ? <Check className="h-4 w-4" /> : <Clipboard className="h-4 w-4" />}
                </Button>
                <Button size="icon" variant="outline" onClick={handleDownload}>
                  <Download className="h-4 w-4" />
                </Button>
              </div>

              <SyntaxHighlighter
                language="json"
                style={theme === "light" ? githubGist : nord}
                className="mt-4 p-4 bg-secondary rounded shadow overflow-x-scroll"
              >
                {JSON.stringify(script, null, 2)}
              </SyntaxHighlighter>
            </div>
          </TabsContent>
          <TabsContent value="preview" className="h-full w-full">
            <ScriptItem item={script} />
          </TabsContent>
        </Tabs>
      </div>
    </div>
  );
}
