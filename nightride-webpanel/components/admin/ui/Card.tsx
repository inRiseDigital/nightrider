import { HTMLAttributes, ReactNode } from "react";
import { cn } from "./cn";

export function Card({ className, children, ...props }: HTMLAttributes<HTMLDivElement>) {
  return (
    <div
      className={cn(
        "rounded-2xl border border-nr-border bg-nr-surface shadow-sm",
        className
      )}
      {...props}
    >
      {children}
    </div>
  );
}

export function CardHeader({
  title,
  description,
  action,
  className,
}: {
  title: ReactNode;
  description?: ReactNode;
  action?: ReactNode;
  className?: string;
}) {
  return (
    <div className={cn("flex items-start justify-between gap-4 border-b border-nr-border p-5", className)}>
      <div className="min-w-0">
        <h2 className="font-display text-lg tracking-wide text-nr-text-primary">{title}</h2>
        {description && <p className="mt-1 text-sm text-nr-text-secondary">{description}</p>}
      </div>
      {action && <div className="shrink-0">{action}</div>}
    </div>
  );
}

export function StatCard({
  label,
  value,
  icon: Icon,
  tone = "default",
}: {
  label: string;
  value: ReactNode;
  icon: React.ComponentType<{ size?: number; className?: string }>;
  tone?: "default" | "primary" | "danger" | "accent";
}) {
  const toneClasses: Record<string, string> = {
    default: "bg-white/5 text-nr-text-secondary",
    primary: "bg-nr-primary/10 text-nr-primary",
    danger: "bg-red-500/10 text-red-400",
    accent: "bg-nr-primary-light/10 text-nr-primary-light",
  };
  return (
    <Card className="p-5">
      <div className="flex items-center justify-between">
        <p className="text-xs font-medium uppercase tracking-wider text-nr-text-hint">{label}</p>
        <div className={cn("flex h-8 w-8 items-center justify-center rounded-lg", toneClasses[tone])}>
          <Icon size={16} />
        </div>
      </div>
      <p className="mt-3 font-display text-3xl text-nr-text-primary">{value}</p>
    </Card>
  );
}
