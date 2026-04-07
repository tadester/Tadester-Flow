import type { ReactNode } from "react";

import { Footer } from "./Footer";
import { Navbar } from "./Navbar";

type AuthPageShellProps = {
  children: ReactNode;
};

export function AuthPageShell({ children }: AuthPageShellProps) {
  return (
    <>
      <Navbar />
      <main className="section">
        <div className="container">
          <div className="mx-auto max-w-2xl">{children}</div>
        </div>
      </main>
      <Footer />
    </>
  );
}
