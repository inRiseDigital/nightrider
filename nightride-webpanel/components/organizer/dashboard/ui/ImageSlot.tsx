"use client";

import { useCallback, useId, useRef, useState } from "react";
import { ImagePlus } from "lucide-react";
import { cn } from "@/components/admin/ui/cn";
import { useOrganizerDashboard } from "@/lib/organizer/dashboard/store";

/**
 * React port of the design's `<image-slot>` custom element.
 *
 * Click to browse or drag an image onto it. The file is read as a data URL and
 * stored in the dashboard store keyed by `slotId`, so two slots sharing an id
 * — the venue editor's hero and the live app preview's hero, for instance —
 * always show the same photo. Uploads are local only; nothing is sent to
 * Storage yet.
 */
export function ImageSlot({
  slotId,
  placeholder = "Drop an image",
  className,
  rounded = "rounded-lg",
  compact = false,
}: {
  slotId: string;
  placeholder?: string;
  className?: string;
  rounded?: string;
  compact?: boolean;
}) {
  const { images, setImage } = useOrganizerDashboard();
  const [dragging, setDragging] = useState(false);
  const inputRef = useRef<HTMLInputElement>(null);
  const inputId = useId();
  const src = images[slotId];

  const readFile = useCallback(
    (file: File | undefined) => {
      if (!file || !file.type.startsWith("image/")) return;
      const reader = new FileReader();
      reader.onload = () => {
        if (typeof reader.result === "string") setImage(slotId, reader.result);
      };
      reader.readAsDataURL(file);
    },
    [slotId, setImage]
  );

  return (
    <div
      onDragOver={(e) => {
        e.preventDefault();
        setDragging(true);
      }}
      onDragLeave={() => setDragging(false)}
      onDrop={(e) => {
        e.preventDefault();
        setDragging(false);
        readFile(e.dataTransfer.files?.[0]);
      }}
      className={cn("relative h-full w-full overflow-hidden", rounded, className)}
    >
      <input
        ref={inputRef}
        id={inputId}
        type="file"
        accept="image/*"
        className="sr-only"
        onChange={(e) => {
          readFile(e.target.files?.[0]);
          // Allow re-picking the same file straight after a removal.
          e.target.value = "";
        }}
      />
      <button
        type="button"
        onClick={() => inputRef.current?.click()}
        aria-label={src ? `Replace image: ${placeholder}` : `Add image: ${placeholder}`}
        className={cn(
          "group flex h-full w-full items-center justify-center overflow-hidden border border-dashed transition-colors",
          rounded,
          src ? "border-transparent" : "hover:bg-white/5",
          dragging && "!border-[var(--m3-pri)]"
        )}
        style={
          src
            ? undefined
            : {
                borderColor: dragging ? "var(--m3-pri)" : "var(--m3-outline)",
                background: dragging
                  ? "color-mix(in srgb, var(--m3-pri) 10%, transparent)"
                  : "var(--m3-surf2)",
              }
        }
      >
        {src ? (
          // A data URL of arbitrary dimensions — next/image would need a loader
          // and buys nothing for a client-side blob.
          // eslint-disable-next-line @next/next/no-img-element
          <img src={src} alt="" className="h-full w-full object-cover" />
        ) : (
          <span
            className={cn(
              "flex flex-col items-center gap-1.5 px-2 text-center transition-colors",
              compact ? "text-[10px]" : "text-xs"
            )}
            style={{ color: "var(--m3-outline)" }}
          >
            <ImagePlus size={compact ? 14 : 18} />
            {!compact && <span className="leading-tight">{placeholder}</span>}
          </span>
        )}
      </button>
    </div>
  );
}
