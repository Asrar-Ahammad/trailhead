import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "Trailhead API",
  description: "API for Trailhead mobile app",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body style={{ margin: 0, backgroundColor: '#121212' }}>
        {children}
      </body>
    </html>
  );
}
