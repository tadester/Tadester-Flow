import { NextResponse } from "next/server";

import { getServerSupabaseClient } from "@/lib/supabase/server-client";
import {
  validateWaitlistSubmission,
  type WaitlistValidationErrors,
} from "@/lib/validations/waitlist";
import type {
  WaitlistResponse,
  WaitlistSubmissionPayload,
} from "@/types/waitlist";

const WAITLIST_TABLE = "waitlist_submissions";

function invalidInputResponse(fieldErrors?: WaitlistValidationErrors) {
  return NextResponse.json<WaitlistResponse>(
    {
      status: "error",
      code: "INVALID_INPUT",
      message: "Please correct the highlighted fields and try again.",
      fieldErrors,
    },
    { status: 400 },
  );
}

export async function POST(request: Request) {
  let payload: WaitlistSubmissionPayload;

  try {
    payload = (await request.json()) as WaitlistSubmissionPayload;
  } catch {
    return invalidInputResponse();
  }

  const normalizedPayload: WaitlistSubmissionPayload = {
    email: payload.email?.trim().toLowerCase() ?? "",
    companySize: payload.companySize?.trim() ?? "",
  };

  const validation = validateWaitlistSubmission(normalizedPayload);

  if (!validation.isValid) {
    return invalidInputResponse(validation.errors);
  }

  try {
    const supabase = getServerSupabaseClient();
    const { error } = await supabase.from(WAITLIST_TABLE).insert({
      email: normalizedPayload.email,
      company_size: normalizedPayload.companySize,
    });

    if (error) {
      if (error.code === "23505") {
        return NextResponse.json<WaitlistResponse>(
          {
            status: "error",
            code: "DUPLICATE_EMAIL",
            message: "This email is already on the waitlist.",
          },
          { status: 409 },
        );
      }

      return NextResponse.json<WaitlistResponse>(
        {
          status: "error",
          code: "SERVER_ERROR",
          message: "Something went wrong. Please try again shortly.",
        },
        { status: 500 },
      );
    }

    return NextResponse.json<WaitlistResponse>(
      {
        status: "success",
        code: "WAITLIST_JOINED",
        message: "You are on the waitlist. We will be in touch soon.",
      },
      { status: 201 },
    );
  } catch {
    return NextResponse.json<WaitlistResponse>(
      {
        status: "error",
        code: "SERVER_ERROR",
        message: "Something went wrong. Please try again shortly.",
      },
      { status: 500 },
    );
  }
}
