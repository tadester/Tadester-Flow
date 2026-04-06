import type { SelectHTMLAttributes } from "react";

type SelectOption = {
  value: string;
  label: string;
};

type SelectProps = Omit<SelectHTMLAttributes<HTMLSelectElement>, "id"> & {
  id: string;
  label: string;
  options: SelectOption[];
  placeholder: string;
  error?: string;
};

export function Select({
  id,
  label,
  options,
  placeholder,
  error,
  className = "",
  ...props
}: SelectProps) {
  const describedBy = error ? `${id}-error` : undefined;

  return (
    <div className="space-y-2">
      <label htmlFor={id} className="block text-sm font-medium text-zinc-900">
        {label}
      </label>
      <select
        id={id}
        aria-invalid={Boolean(error)}
        aria-describedby={describedBy}
        className={[
          "min-h-12 rounded-xl border px-4 py-3 text-base text-zinc-950",
          error ? "border-[#b42318]" : "border-zinc-300",
          className,
        ].join(" ")}
        {...props}
      >
        <option value="">{placeholder}</option>
        {options.map((option) => (
          <option key={option.value} value={option.value}>
            {option.label}
          </option>
        ))}
      </select>
      {error ? (
        <p id={describedBy} className="text-sm text-[#b42318]">
          {error}
        </p>
      ) : null}
    </div>
  );
}
