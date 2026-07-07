import type { Metadata } from "next";
import { Geist, Geist_Mono } from "next/font/google";
import "./globals.css";
import { ThemeProvider } from "@/components/ThemeProvider";
import { ClerkProvider } from "@clerk/nextjs";
import PwaRegister from "@/components/PwaRegister";
import BottomNav from "@/components/BottomNav";

const geistSans = Geist({
  variable: "--font-geist-sans",
  subsets: ["latin"],
});

const geistMono = Geist_Mono({
  variable: "--font-geist-mono",
  subsets: ["latin"],
});

export const metadata: Metadata = {
  title: "Trailhead",
  description: "Track your runs offline and sync seamlessly",
  manifest: "/manifest.json",
  appleWebApp: {
    capable: true,
    statusBarStyle: "black-translucent",
    title: "Trailhead",
  },
};

export const viewport = {
  width: "device-width",
  initialScale: 1,
  viewportFit: "cover",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <ClerkProvider>
      <html
        lang="en"
        className={`${geistSans.variable} ${geistMono.variable} h-[100dvh] antialiased`}
        suppressHydrationWarning
      >
        <body className="h-[100dvh] bg-background text-foreground transition-colors duration-200" suppressHydrationWarning>
          <ThemeProvider>
            <PwaRegister />
            <div className="h-[100dvh] flex flex-col max-w-lg mx-auto w-full relative pb-14">
              {children}
            </div>
            <BottomNav />
          </ThemeProvider>
        </body>
      </html>
    </ClerkProvider>
  );
}
