import { initials } from "@/lib/admin/format";
import { cn } from "./cn";

export function Avatar({
  name,
  src,
  size = 36,
  className,
}: {
  name: string;
  src?: string;
  size?: number;
  className?: string;
}) {
  if (src) {
    return (
      // eslint-disable-next-line @next/next/no-img-element -- external mock avatar URLs, not part of the Next.js image pipeline
      <img
        src={src}
        alt={name}
        width={size}
        height={size}
        className={cn("shrink-0 rounded-full bg-nr-surface-raised object-cover ring-1 ring-white/10", className)}
        style={{ width: size, height: size }}
      />
    );
  }
  return (
    <div
      className={cn(
        "flex shrink-0 items-center justify-center rounded-full bg-nr-primary/20 font-medium text-nr-primary-light ring-1 ring-white/10",
        className
      )}
      style={{ width: size, height: size, fontSize: size * 0.38 }}
    >
      {initials(name)}
    </div>
  );
}
