"use client";

import Link from "next/link";
import { useSearchParams } from "next/navigation";
import { useEffect, useState } from "react";

import { Button } from "@/components/ui/Button";
import { Input } from "@/components/ui/Input";
import { StatusMessage } from "@/components/ui/StatusMessage";
import { getBrowserSupabaseClient } from "@/lib/supabase/browser-client";

type ResetStatus =
  | { status: "success"; message: string }
  | { status: "error"; message: string };

export default function ResetPasswordClientPage() {
  const searchParams = useSearchParams();
  const [password, setPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [fieldErrors, setFieldErrors] = useState<Record<string, string>>({});
  const [response, setResponse] = useState<ResetStatus | null>(null);
  const [isVerifying, setIsVerifying] = useState(true);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [isRecoveryReady, setIsRecoveryReady] = useState(false);

  const tokenHash = searchParams.get("token_hash");
  const type = searchParams.get("type");

  useEffect(() => {
    let isMounted = true;

    async function verifyRecoveryLink() {
      if (!tokenHash || type !== "recovery") {
        if (isMounted) {
          setResponse({
            status: "error",
            message:
              "This password reset link is incomplete or invalid. Request a new reset email and try again.",
          });
          setIsVerifying(false);
        }
        return;
      }

      try {
        const supabase = getBrowserSupabaseClient();
        const { error } = await supabase.auth.verifyOtp({
          token_hash: tokenHash,
          type: "recovery",
        });

        if (!isMounted) {
          return;
        }

        if (error) {
          setResponse({
            status: "error",
            message:
              error.message ||
              "We could not verify this reset link. Request a new password reset email and try again.",
          });
        } else {
          setIsRecoveryReady(true);
        }
      } catch {
        if (!isMounted) {
          return;
        }

        setResponse({
          status: "error",
          message:
            "Something went wrong while preparing your password reset. Please request a fresh reset link and try again.",
        });
      } finally {
        if (isMounted) {
          setIsVerifying(false);
        }
      }
    }

    void verifyRecoveryLink();

    return () => {
      isMounted = false;
    };
  }, [tokenHash, type]);

  async function handleSubmit(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();

    const nextErrors: Record<string, string> = {};

    if (!password) {
      nextErrors.password = "New password is required.";
    } else if (password.length < 8) {
      nextErrors.password = "Use at least 8 characters for your new password.";
    }

    if (!confirmPassword) {
      nextErrors.confirmPassword = "Please confirm your new password.";
    } else if (confirmPassword !== password) {
      nextErrors.confirmPassword = "Passwords do not match.";
    }

    setFieldErrors(nextErrors);
    setResponse(null);

    if (Object.keys(nextErrors).length > 0) {
      return;
    }

    setIsSubmitting(true);

    try {
      const supabase = getBrowserSupabaseClient();
      const { error } = await supabase.auth.updateUser({ password });

      if (error) {
        setResponse({
          status: "error",
          message:
            error.message ||
            "We could not update your password right now. Please request a new reset email and try again.",
        });
      } else {
        setResponse({
          status: "success",
          message:
            "Your password has been updated successfully. Return to the Tadester Ops app and sign in with your new password.",
        });
        setPassword("");
        setConfirmPassword("");
      }
    } catch {
      setResponse({
        status: "error",
        message:
          "Something went wrong while updating your password. Please request a fresh reset email and try again.",
      });
    } finally {
      setIsSubmitting(false);
    }
  }

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

      {isVerifying ? (
        <div className="rounded-xl border border-zinc-200 bg-zinc-50 px-4 py-4 text-sm text-zinc-600">
          Verifying your password reset link...
        </div>
      ) : null}

      {!isVerifying && response ? <StatusMessage response={response} /> : null}

      {!isVerifying && isRecoveryReady ? (
        <form className="space-y-4" onSubmit={handleSubmit}>
          <Input
            id="password"
            label="New password"
            type="password"
            autoComplete="new-password"
            placeholder="Enter a strong new password"
            value={password}
            onChange={(event) => setPassword(event.target.value)}
            error={fieldErrors.password}
          />
          <Input
            id="confirm-password"
            label="Confirm new password"
            type="password"
            autoComplete="new-password"
            placeholder="Re-enter your new password"
            value={confirmPassword}
            onChange={(event) => setConfirmPassword(event.target.value)}
            error={fieldErrors.confirmPassword}
          />
          <Button type="submit" isLoading={isSubmitting}>
            Update password
          </Button>
        </form>
      ) : null}

      <div className="rounded-xl border border-zinc-200 bg-zinc-50 px-5 py-4 text-sm text-zinc-600">
        If this link has expired, request another password reset from the mobile app login
        screen and use the newest email.
      </div>

      <Link
        href="/"
        className="inline-flex rounded-lg border border-zinc-900 px-4 py-2 text-sm font-semibold text-zinc-900 transition hover:bg-zinc-900 hover:text-white"
      >
        Back to homepage
      </Link>
    </section>
  );
}
