import type { WaitlistResponse } from "@/types/waitlist";

type StatusMessageProps = {
  response: WaitlistResponse | null;
};

export function StatusMessage({ response }: StatusMessageProps) {
  if (!response) {
    return null;
  }

  const isSuccess = response.status === "success";

  return (
    <div
      role="status"
      aria-live="polite"
      className={[
        "rounded-xl border px-4 py-3 text-sm",
        isSuccess
          ? "border-emerald-200 bg-emerald-50 text-emerald-700"
          : "border-red-200 bg-red-50 text-red-700",
      ].join(" ")}
    >
      {response.message}
    </div>
  );
}
