"use client";

import { useState, type FormEvent } from "react";

import { validateWaitlistSubmission } from "@/lib/validations/waitlist";
import type {
  WaitlistResponse,
  WaitlistSubmissionPayload,
} from "@/types/waitlist";

import { Button } from "@/components/ui/Button";
import { Input } from "@/components/ui/Input";
import { Select } from "@/components/ui/Select";
import { StatusMessage } from "@/components/ui/StatusMessage";

const COMPANY_SIZE_OPTIONS = [
  { value: "1-10", label: "1-10 employees" },
  { value: "11-50", label: "11-50 employees" },
  { value: "51-200", label: "51-200 employees" },
  { value: "201+", label: "201+ employees" },
];

const INITIAL_FORM: WaitlistSubmissionPayload = {
  email: "",
  companySize: "",
};

export function WaitlistSection() {
  const [form, setForm] = useState(INITIAL_FORM);
  const [fieldErrors, setFieldErrors] = useState<
    Partial<Record<keyof WaitlistSubmissionPayload, string>>
  >({});
  const [status, setStatus] = useState<WaitlistResponse | null>(null);
  const [isSubmitting, setIsSubmitting] = useState(false);

  function updateField<K extends keyof WaitlistSubmissionPayload>(
    key: K,
    value: WaitlistSubmissionPayload[K],
  ) {
    setForm((current) => ({ ...current, [key]: value }));
    setFieldErrors((current) => ({ ...current, [key]: undefined }));
  }

  async function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setStatus(null);

    const validation = validateWaitlistSubmission(form);

    if (!validation.isValid) {
      setFieldErrors(validation.errors);
      setStatus({
        status: "error",
        code: "INVALID_INPUT",
        message: "Please correct the highlighted fields and try again.",
        fieldErrors: validation.errors,
      });
      return;
    }

    setFieldErrors({});
    setIsSubmitting(true);

    try {
      const response = await fetch("/api/waitlist", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify(form),
      });

      const result = (await response.json()) as WaitlistResponse;
      setStatus(result);

      if (result.status === "error" && result.fieldErrors) {
        setFieldErrors(result.fieldErrors);
      } else if (result.status === "error" && result.code === "DUPLICATE_EMAIL") {
        setFieldErrors({ email: "This email is already on the waitlist." });
      }

      if (response.ok && result.status === "success") {
        setForm(INITIAL_FORM);
        setFieldErrors({});
      }
    } catch {
      setStatus({
        status: "error",
        code: "SERVER_ERROR",
        message: "Something went wrong. Please try again shortly.",
      });
    } finally {
      setIsSubmitting(false);
    }
  }

  return (
    <section id="waitlist" className="section pt-6">
      <div className="container">
        <div className="mx-auto max-w-2xl rounded-[24px] border border-zinc-900/20 bg-white px-6 py-8 shadow-[0_22px_48px_rgba(15,23,42,0.12)] sm:px-10">
          <div className="text-center">
            <h2 className="text-[2.1rem] font-semibold tracking-[-0.04em] text-zinc-950">
              Get Early Access
            </h2>
            <p className="mx-auto mt-3 max-w-xl text-base leading-7 text-zinc-600">
              Join the waitlist for launch updates and early access to routing,
              crew accountability, and real-time map visibility.
            </p>
          </div>

          <form className="mt-8 space-y-5" onSubmit={handleSubmit} noValidate>
            <Input
              id="email"
              type="email"
              label="Work Email"
              placeholder="you@company.com"
              value={form.email}
              onChange={(event) => updateField("email", event.target.value)}
              error={fieldErrors.email}
              disabled={isSubmitting}
              autoComplete="email"
            />

            <Select
              id="companySize"
              label="Company Size"
              value={form.companySize}
              onChange={(event) =>
                updateField("companySize", event.target.value)
              }
              options={COMPANY_SIZE_OPTIONS}
              placeholder="Select size"
              error={fieldErrors.companySize}
              disabled={isSubmitting}
            />

            <StatusMessage response={status} />

            <Button type="submit" isLoading={isSubmitting} disabled={isSubmitting}>
              Get Early Access
            </Button>
          </form>
        </div>
      </div>
    </section>
  );
}
