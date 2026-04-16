import { Suspense } from "react";

import { AuthPageShell } from "@/components/layout/AuthPageShell";

import ResetPasswordClientPage from "./page-client";

export default function ResetPasswordPage() {
  return (
    <AuthPageShell>
      <Suspense fallback={<ResetPasswordFallback />}>
        <ResetPasswordClientPage />
      </Suspense>
    </AuthPageShell>
  );
}

function ResetPasswordFallback() {
  return (
    <section className="surface-card space-y-6 px-6 py-8 sm:px-8 sm:py-10">
      <div className="space-y-3">
        <span className="eyebrow">Password Reset</span>
        <h1 className="section-title text-zinc-950">Set a new password</h1>
        <p className="section-copy">
          Use this secure recovery screen to set a new password for your Tadester Ops
          account.
        </p>
      </div>
      <div className="rounded-xl border border-zinc-200 bg-zinc-50 px-4 py-4 text-sm text-zinc-600">
        Verifying your password reset link...
      </div>
    </section>
  );
}
