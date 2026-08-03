import { ReactNode } from "react";
import { Inbox } from "lucide-react";

export function EmptyState({
  icon: Icon = Inbox,
  title,
  description,
  action,
}: {
  icon?: React.ComponentType<{ size?: number; className?: string }>;
  title: string;
  description?: string;
  action?: ReactNode;
}) {
  return (
    <div className="flex flex-col items-center justify-center gap-3 px-6 py-16 text-center">
      <div className="flex h-12 w-12 items-center justify-center rounded-full bg-white/5 text-nr-text-hint">
        <Icon size={22} />
      </div>
      <div>
        <p className="font-medium text-nr-text-primary">{title}</p>
        {description && <p className="mt-1 max-w-sm text-sm text-nr-text-secondary">{description}</p>}
      </div>
      {action}
    </div>
  );
}
