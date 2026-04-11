import { Suspense } from "react";

import { AuthPageShell } from "@/components/layout/AuthPageShell";

import ConfirmClientPage from "./page-client";

export default function ConfirmPage() {
  return (
    <AuthPageShell>
      <Suspense fallback={<ConfirmFallback />}>
        <ConfirmClientPage />
      </Suspense>
    </AuthPageShell>
  );
}

function ConfirmFallback() {
  return (
    <section className="surface-card space-y-6 px-6 py-8 sm:px-8 sm:py-10">
      <div className="space-y-3">
        <span className="eyebrow">Account Confirmation</span>
        <h1 className="section-title text-zinc-950">Confirm your Tadester Ops account</h1>
        <p className="section-copy">
          We are verifying your email so you can safely sign in and access your field
          operations workspace.
        </p>
      </div>
      <div className="rounded-xl border border-zinc-200 bg-zinc-50 px-4 py-4 text-sm text-zinc-600">
        Verifying your confirmation link...
      </div>
    </section>
  );
}
