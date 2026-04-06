import type { ButtonHTMLAttributes, ReactNode } from "react";

type ButtonProps = ButtonHTMLAttributes<HTMLButtonElement> & {
  children: ReactNode;
  isLoading?: boolean;
};

export function Button({
  children,
  className = "",
  disabled = false,
  isLoading = false,
  type = "button",
  ...props
}: ButtonProps) {
  const isInactive = disabled || isLoading;

  return (
    <button
      type={type}
      disabled={isInactive}
      className={[
        "inline-flex min-h-12 w-full items-center justify-center rounded-xl bg-[#d90d0d] px-5 py-3 text-sm font-semibold text-white transition",
        isInactive ? "cursor-not-allowed opacity-70" : "hover:bg-[#b70b0b]",
        className,
      ].join(" ")}
      {...props}
    >
      {isLoading ? "Submitting..." : children}
    </button>
  );
}
