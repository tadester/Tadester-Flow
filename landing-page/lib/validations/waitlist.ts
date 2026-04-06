import type { WaitlistSubmissionPayload } from "@/types/waitlist";

export type WaitlistValidationErrors = Partial<
  Record<keyof WaitlistSubmissionPayload, string>
>;

export type WaitlistValidationResult = {
  isValid: boolean;
  errors: WaitlistValidationErrors;
};

const EMAIL_PATTERN = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

export function validateWaitlistSubmission(
  payload: WaitlistSubmissionPayload,
): WaitlistValidationResult {
  const errors: WaitlistValidationErrors = {};

  if (!payload.email.trim()) {
    errors.email = "Please enter your email address.";
  } else if (!EMAIL_PATTERN.test(payload.email)) {
    errors.email = "Please enter a valid email address.";
  }

  if (!payload.companySize.trim()) {
    errors.companySize = "Please select your company size.";
  }

  return {
    isValid: Object.keys(errors).length === 0,
    errors,
  };
}
