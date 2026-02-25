import type { Metadata } from "next";

import { NuqsAdapter } from "nuqs/adapters/next/app";
import { Inter } from "next/font/google";
import Script from "next/script";
import React from "react";

import { ThemeProvider } from "@/components/theme-provider";
import { analytics, basePath } from "@/config/site-config";
import QueryProvider from "@/components/query-provider";
import { Toaster } from "@/components/ui/sonner";
import Footer from "@/components/footer";
import Navbar from "@/components/navbar";
import "@/styles/globals.css";

const inter = Inter({ subsets: ["latin"] });

export const metadata: Metadata = {
  title: "Proxmox VE 辅助脚本",
  description:
    "Proxmox VE 辅助脚本（社区版）仓库的官方网站。提供超过 400 多个脚本来帮助您管理 Proxmox 虚拟环境。",
  applicationName: "Proxmox VE 辅助脚本",
  generator: "Next.js",
  referrer: "origin-when-cross-origin",
  keywords: [
    "Proxmox VE",
    "Helper-Scripts",
    "tteck",
    "helper",
    "scripts",
    "proxmox",
    "VE",
    "virtualization",
    "containers",
    "LXC",
    "VM",
  ],
  authors: [
    { name: "Bram Suurd", url: "https://github.com/BramSuurdje" },
    { name: "Community Scripts", url: "https://github.com/Community-Scripts" },
  ],
  creator: "Bram Suurd",
  publisher: "Community Scripts",
  metadataBase: new URL(`https://community-scripts.github.io/${basePath}/`),
  alternates: {
    canonical: `https://community-scripts.github.io/${basePath}/`,
  },
  viewport: {
    width: "device-width",
    initialScale: 1,
    maximumScale: 5,
  },
  formatDetection: {
    email: false,
    address: false,
    telephone: false,
  },
  openGraph: {
    title: "Proxmox VE 辅助脚本",
    description:
      "Proxmox VE 辅助脚本（社区版）仓库的官方网站。提供超过 400 多个脚本来帮助您管理 Proxmox 虚拟环境。",
    url: `https://community-scripts.github.io/${basePath}/`,
    siteName: "Proxmox VE 辅助脚本",
    images: [
      {
        url: `https://community-scripts.github.io/${basePath}/defaultimg.png`,
        width: 1200,
        height: 630,
        alt: "Proxmox VE 辅助脚本",
      },
    ],
    locale: "en_US",
    type: "website",
  },
  twitter: {
    card: "summary_large_image",
    title: "Proxmox VE 辅助脚本",
    creator: "@BramSuurdje",
    description:
      "Proxmox VE 辅助脚本（社区版）仓库的官方网站。提供超过 400 多个脚本来帮助您管理 Proxmox 虚拟环境。",
    images: [`https://community-scripts.github.io/${basePath}/defaultimg.png`],
  },
  manifest: "/manifest.webmanifest",
  appleWebApp: {
    capable: true,
    statusBarStyle: "default",
    title: "Proxmox VE 辅助脚本",
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" suppressHydrationWarning>
      <head>
        <link rel="canonical" href={metadata.metadataBase?.href} />
        <link rel="manifest" href="manifest.webmanifest" />
        <link rel="preconnect" href="https://api.github.com" />
      </head>
      <body className={inter.className}>
        <Script
          src={`https://${analytics.url}/api/script.js`}
          data-site-id={analytics.token}
          strategy="afterInteractive"
        />
        <ThemeProvider attribute="class" defaultTheme="dark" enableSystem disableTransitionOnChange>
          <div className="flex w-full flex-col justify-center">
            <NuqsAdapter>
              <QueryProvider>
                <Navbar />
                <div className="flex min-h-screen flex-col justify-center">
                  <div className="flex w-full justify-center">
                    <div className="w-full max-w-[1440px] ">
                      {children}
                      <Toaster richColors />
                    </div>
                  </div>
                  <Footer />
                </div>
              </QueryProvider>
            </NuqsAdapter>
          </div>
        </ThemeProvider>
      </body>
    </html>
  );
}
