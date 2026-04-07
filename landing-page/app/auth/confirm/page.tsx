"use client";

import Link from "next/link";
import { useSearchParams } from "next/navigation";
import { useEffect, useMemo, useState } from "react";

import { AuthPageShell } from "@/components/layout/AuthPageShell";
import { StatusMessage } from "@/components/ui/StatusMessage";
import { getBrowserSupabaseClient } from "@/lib/supabase/browser-client";

type ConfirmStatus =
  | { status: "success"; message: string }
  | { status: "error"; message: string };

const SUPPORTED_CONFIRM_TYPES = new Set(["email", "signup", "invite", "magiclink"]);

export default function ConfirmPage() {
  const searchParams = useSearchParams();
  const [response, setResponse] = useState<ConfirmStatus | null>(null);
  const [isVerifying, setIsVerifying] = useState(true);

  const tokenHash = searchParams.get("token_hash");
  const type = useMemo(() => {
    const value = searchParams.get("type") ?? "email";
    return SUPPORTED_CONFIRM_TYPES.has(value) ? value : null;
  }, [searchParams]);

  useEffect(() => {
    let isMounted = true;

    async function verifyConfirmation() {
      if (!tokenHash || !type) {
        if (isMounted) {
          setResponse({
            status: "error",
            message:
              "This confirmation link is incomplete or invalid. Request a new email and try again.",
          });
          setIsVerifying(false);
        }
        return;
      }

      try {
        const supabase = getBrowserSupabaseClient();
        const { error } = await supabase.auth.verifyOtp({
          token_hash: tokenHash,
          type: type as "email" | "signup" | "invite" | "magiclink",
        });

        if (!isMounted) {
          return;
        }

        if (error) {
          setResponse({
            status: "error",
            message:
              error.message ||
              "We could not confirm your account from this link. Request a fresh confirmation email and try again.",
          });
        } else {
          setResponse({
            status: "success",
            message:
              "Your account has been confirmed successfully. You can return to the Tadester Ops app and sign in.",
          });
        }
      } catch {
        if (!isMounted) {
          return;
        }

        setResponse({
          status: "error",
          message:
            "Something went wrong while confirming your account. Please try again with a fresh email link.",
        });
      } finally {
        if (isMounted) {
          setIsVerifying(false);
        }
      }
    }

    void verifyConfirmation();

    return () => {
      isMounted = false;
    };
  }, [tokenHash, type]);

  return (
    <AuthPageShell>
      <section className="surface-card space-y-6 px-6 py-8 sm:px-8 sm:py-10">
        <div className="space-y-3">
          <span className="eyebrow">Account Confirmation</span>
          <h1 className="section-title text-zinc-950">Confirm your Tadester Ops account</h1>
          <p className="section-copy">
            We are verifying your email so you can safely sign in and access your field
            operations workspace.
          </p>
        </div>

        {isVerifying ? (
          <div className="rounded-xl border border-zinc-200 bg-zinc-50 px-4 py-4 text-sm text-zinc-600">
            Verifying your confirmation link...
          </div>
        ) : (
          <StatusMessage response={response} />
        )}

        <div className="rounded-xl border border-zinc-200 bg-zinc-50 px-5 py-4 text-sm text-zinc-600">
          Need a new link? Request another confirmation email from the mobile app, or contact
          your Tadester Ops administrator.
        </div>

        <Link
          href="/"
          className="inline-flex rounded-lg border border-zinc-900 px-4 py-2 text-sm font-semibold text-zinc-900 transition hover:bg-zinc-900 hover:text-white"
        >
          Back to homepage
        </Link>
      </section>
    </AuthPageShell>
  );
}
