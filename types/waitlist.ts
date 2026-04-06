export type WaitlistSubmissionPayload = {
  email: string;
  companySize: string;
};

export type WaitlistRow = {
  id?: string;
  email: string;
  company_size: string;
  created_at: string;
};

export type WaitlistSuccessResponse = {
  status: "success";
  code: "WAITLIST_JOINED";
  message: string;
};

export type WaitlistErrorResponse = {
  status: "error";
  code:
    | "INVALID_INPUT"
    | "DUPLICATE_EMAIL"
    | "SERVER_ERROR"
    | "INVALID_REQUEST_METHOD";
  message: string;
  fieldErrors?: Partial<Record<keyof WaitlistSubmissionPayload, string>>;
};

export type WaitlistResponse =
  | WaitlistSuccessResponse
  | WaitlistErrorResponse;
