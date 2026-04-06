import type { InputHTMLAttributes } from "react";

type InputProps = Omit<InputHTMLAttributes<HTMLInputElement>, "id"> & {
  id: string;
  label: string;
  error?: string;
};

export function Input({ id, label, error, className = "", ...props }: InputProps) {
  const describedBy = error ? `${id}-error` : undefined;

  return (
    <div className="space-y-2">
      <label htmlFor={id} className="block text-sm font-medium text-zinc-900">
        {label}
      </label>
      <input
        id={id}
        aria-invalid={Boolean(error)}
        aria-describedby={describedBy}
        className={[
          "min-h-12 rounded-xl border px-4 py-3 text-base text-zinc-950 placeholder:text-zinc-400",
          error ? "border-[#b42318]" : "border-zinc-300",
          className,
        ].join(" ")}
        {...props}
      />
      {error ? (
        <p id={describedBy} className="text-sm text-[#b42318]">
          {error}
        </p>
      ) : null}
    </div>
  );
}
