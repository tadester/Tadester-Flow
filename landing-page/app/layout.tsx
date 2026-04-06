import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "Tadester Ops",
  description:
    "Tadester Ops helps rugged field teams cut fuel costs with smarter routing and real-time crew visibility.",
  applicationName: "Tadester Ops",
  keywords: [
    "field operations",
    "routing",
    "geofencing",
    "crew tracking",
    "landscaping software",
    "snow removal software",
  ],
};

type RootLayoutProps = {
  children: React.ReactNode;
};

export default function RootLayout({ children }: RootLayoutProps) {
  return (
    <html lang="en">
      <body>
        <div className="site-shell">{children}</div>
      </body>
    </html>
  );
}
