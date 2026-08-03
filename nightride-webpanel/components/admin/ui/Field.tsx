"use client";

import { InputHTMLAttributes, ReactNode, SelectHTMLAttributes, TextareaHTMLAttributes, forwardRef } from "react";
import { cn } from "./cn";

export function FieldWrapper({
  label,
  error,
  hint,
  children,
  htmlFor,
}: {
  label?: string;
  error?: string;
  hint?: string;
  children: ReactNode;
  htmlFor?: string;
}) {
  return (
    <label htmlFor={htmlFor} className="block">
      {label && <span className="mb-1.5 block text-sm font-medium text-nr-text-primary">{label}</span>}
      {children}
      {error ? (
        <span className="mt-1.5 block text-xs text-red-400">{error}</span>
      ) : hint ? (
        <span className="mt-1.5 block text-xs text-nr-text-hint">{hint}</span>
      ) : null}
    </label>
  );
}

const baseInputClasses =
  "w-full rounded-lg border border-nr-border bg-nr-surface-raised px-3 py-2 text-sm text-nr-text-primary placeholder:text-nr-text-hint focus:border-nr-primary-light focus:outline-none focus:ring-1 focus:ring-nr-primary-light disabled:opacity-50";

interface InputProps extends InputHTMLAttributes<HTMLInputElement> {
  label?: string;
  error?: string;
  hint?: string;
}

export const Input = forwardRef<HTMLInputElement, InputProps>(
  ({ label, error, hint, className, id, ...props }, ref) => (
    <FieldWrapper label={label} error={error} hint={hint} htmlFor={id}>
      <input
        ref={ref}
        id={id}
        className={cn(baseInputClasses, error && "border-red-500 focus:border-red-500 focus:ring-red-500", className)}
        {...props}
      />
    </FieldWrapper>
  )
);
Input.displayName = "Input";

interface TextareaProps extends TextareaHTMLAttributes<HTMLTextAreaElement> {
  label?: string;
  error?: string;
  hint?: string;
}

export const Textarea = forwardRef<HTMLTextAreaElement, TextareaProps>(
  ({ label, error, hint, className, id, rows = 3, ...props }, ref) => (
    <FieldWrapper label={label} error={error} hint={hint} htmlFor={id}>
      <textarea
        ref={ref}
        id={id}
        rows={rows}
        className={cn(baseInputClasses, "resize-none", error && "border-red-500", className)}
        {...props}
      />
    </FieldWrapper>
  )
);
Textarea.displayName = "Textarea";

interface SelectProps extends SelectHTMLAttributes<HTMLSelectElement> {
  label?: string;
  error?: string;
  hint?: string;
  options: { label: string; value: string }[];
}

export const Select = forwardRef<HTMLSelectElement, SelectProps>(
  ({ label, error, hint, className, id, options, ...props }, ref) => (
    <FieldWrapper label={label} error={error} hint={hint} htmlFor={id}>
      <select
        ref={ref}
        id={id}
        className={cn(baseInputClasses, "appearance-none bg-no-repeat pr-8", error && "border-red-500", className)}
        style={{
          backgroundImage:
            "url(\"data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 20 20' fill='%239EAFA0'%3E%3Cpath fill-rule='evenodd' d='M5.23 7.21a.75.75 0 011.06.02L10 11.168l3.71-3.938a.75.75 0 111.08 1.04l-4.25 4.5a.75.75 0 01-1.08 0l-4.25-4.5a.75.75 0 01.02-1.06z' clip-rule='evenodd'/%3E%3C/svg%3E\")",
          backgroundPosition: "right 0.5rem center",
          backgroundSize: "1.25em",
        }}
        {...props}
      >
        {options.map((o) => (
          <option key={o.value} value={o.value}>
            {o.label}
          </option>
        ))}
      </select>
    </FieldWrapper>
  )
);
Select.displayName = "Select";

export function Checkbox({
  checked,
  onChange,
  disabled,
  "aria-label": ariaLabel,
}: {
  checked: boolean;
  onChange: (checked: boolean) => void;
  disabled?: boolean;
  "aria-label"?: string;
}) {
  return (
    <input
      type="checkbox"
      checked={checked}
      disabled={disabled}
      aria-label={ariaLabel}
      onChange={(e) => onChange(e.target.checked)}
      className="h-4 w-4 rounded border-nr-border bg-nr-surface-raised text-nr-primary accent-nr-primary focus:ring-nr-primary-light disabled:opacity-50"
    />
  );
}
