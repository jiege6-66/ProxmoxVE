import { Info } from "lucide-react";

import type { Script } from "@/lib/types";

import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Alert, AlertDescription } from "@/components/ui/alert";
import CodeCopyButton from "@/components/ui/code-copy-button";
import { basePath } from "@/config/site-config";

import { getDisplayValueFromType } from "../script-info-blocks";

function getInstallCommand(scriptPath = "", isAlpine = false, useGitea = false) {
  const githubUrl = `https://raw.githubusercontent.com/community-scripts/${basePath}/main/${scriptPath}`;
  const giteaUrl = `https://git.community-scripts.org/community-scripts/${basePath}/raw/branch/main/${scriptPath}`;
  const url = useGitea ? giteaUrl : githubUrl;
  return isAlpine ? `bash -c "$(curl -fsSL ${url})"` : `bash -c "$(curl -fsSL ${url})"`;
}

export default function InstallCommand({ item }: { item: Script }) {
  const alpineScript = item.install_methods.find(method => method.type === "alpine");
  const defaultScript = item.install_methods.find(method => method.type === "default");

  const renderInstructions = (isAlpine = false) => (
    <>
      <p className="text-sm mt-2">
        {isAlpine
          ? (
              <>
                作为替代选项，您可以使用 Alpine Linux 和
                {" "}
                {item.name}
                {" "}
                软件包来创建一个
                {" "}
                {item.name}
                {" "}
                {getDisplayValueFromType(item.type)}
                {" "}
                容器，具有更快的创建时间和最小的系统资源使用。
                您还需要遵守软件包维护者提供的更新。
              </>
            )
          : item.type === "pve"
            ? (
                <>
                  要使用
                  {" "}
                  {item.name}
                  {" "}
                  脚本，请**仅**在 Proxmox VE Shell 中运行以下命令。此脚本旨在直接管理或增强主机系统。
                </>
              )
            : item.type === "addon"
              ? (
                  <>
                    此脚本增强现有设置。您可以在运行的 LXC 容器内或直接在 Proxmox VE 主机上使用它，以通过
                    {" "}
                    {item.name}
                    {" "}
                    扩展功能。
                  </>
                )
              : (
                  <>
                    要创建新的 Proxmox VE
                    {" "}
                    {item.name}
                    {" "}
                    {getDisplayValueFromType(item.type)}
                    ，请在 Proxmox VE Shell 中运行以下命令。
                  </>
                )}
      </p>
      {isAlpine && (
        <p className="mt-2 text-sm">
          要创建新的 Proxmox VE Alpine-
          {item.name}
          {" "}
          {getDisplayValueFromType(item.type)}
          ，请在 Proxmox VE Shell 中运行以下命令。
        </p>
      )}
    </>
  );

  const renderGiteaInfo = () => (
    <Alert className="mt-3 mb-3">
      <Info className="h-4 w-4" />
      <AlertDescription className="text-sm">
        <strong>何时使用 Gitea：</strong>
        {" "}
        GitHub 可能存在问题，包括连接缓慢、错误修复后更新延迟、不支持 IPv6、API 速率限制（60次/小时）。当遇到这些问题时，请使用我们的 Gitea 镜像作为可靠的替代方案。
      </AlertDescription>
    </Alert>
  );

  const renderScriptTabs = (useGitea = false) => {
    if (alpineScript) {
      return (
        <Tabs defaultValue="default" className="mt-2 w-full max-w-4xl">
          <TabsList>
            <TabsTrigger value="default">默认</TabsTrigger>
            <TabsTrigger value="alpine">Alpine Linux</TabsTrigger>
          </TabsList>
          <TabsContent value="default">
            {renderInstructions()}
            <CodeCopyButton>{getInstallCommand(defaultScript?.script, false, useGitea)}</CodeCopyButton>
          </TabsContent>
          <TabsContent value="alpine">
            {renderInstructions(true)}
            <CodeCopyButton>{getInstallCommand(alpineScript.script, true, useGitea)}</CodeCopyButton>
          </TabsContent>
        </Tabs>
      );
    }
    else if (defaultScript?.script) {
      return (
        <>
          {renderInstructions()}
          <CodeCopyButton>{getInstallCommand(defaultScript.script, false, useGitea)}</CodeCopyButton>
        </>
      );
    }
    return null;
  };

  return (
    <div className="p-4">
      <Tabs defaultValue="github" className="w-full max-w-4xl">
        <TabsList>
          <TabsTrigger value="github">GitHub</TabsTrigger>
          <TabsTrigger value="gitea">Gitea</TabsTrigger>
        </TabsList>
        <TabsContent value="github">
          {renderScriptTabs(false)}
        </TabsContent>
        <TabsContent value="gitea">
          {renderGiteaInfo()}
          {renderScriptTabs(true)}
        </TabsContent>
      </Tabs>
    </div>
  );
}
