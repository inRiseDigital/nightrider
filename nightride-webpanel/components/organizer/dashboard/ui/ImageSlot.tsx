"use client";

import { useCallback, useEffect, useId, useRef, useState } from "react";
import { ImagePlus, RotateCw } from "lucide-react";
import { cn } from "@/components/admin/ui/cn";
import { useOrganizerDashboard } from "@/lib/organizer/dashboard/store";
import { uploadSlotImage } from "@/lib/organizer/dashboard/data/images";

/**
 * React port of the design's `<image-slot>` custom element.
 *
 * Click to browse or drag an image onto it. T12: the file no longer becomes
 * a base64 data URL in localStorage — it uploads to Cloud Storage
 * (`uploadSlotImage`, resized client-side first) and the resulting `https`
 * URL is written onto the Firestore document that owns this slot
 * (`useOrganizerDashboard().commitSlotImage`, dispatched by `slotId`). Two
 * slots sharing an id still always show the same photo, because both read
 * `images[slotId]` — now derived from that document, not a shared blob.
 *
 * Upload flow: `URL.createObjectURL` for an instant local preview -> upload
 * with a progress bar -> write the URL to the owning document, then drop the
 * local objectURL. On failure the local preview is NEVER cleared — the tile
 * shows the error plus a retry action, exactly so a failed upload cannot look
 * to the organizer like "accepted, then vanished".
 */
export function ImageSlot({
  slotId,
  placeholder = "Drop an image",
  className,
  rounded = "rounded-lg",
  compact = false,
  disabled = false,
  disabledHint,
}: {
  slotId: string;
  placeholder?: string;
  className?: string;
  rounded?: string;
  compact?: boolean;
  /** True while the owning document doesn't exist yet (a new, unsaved event) — see the T12 brief's ordering constraint. */
  disabled?: boolean;
  disabledHint?: string;
}) {
  const { images, commitSlotImage, showSnack } = useOrganizerDashboard();
  const [dragging, setDragging] = useState(false);
  const [uploading, setUploading] = useState(false);
  const [progress, setProgress] = useState(0);
  const [error, setError] = useState("");
  // Takes priority over `images[slotId]` — the local objectURL while
  // uploading, then the final `https` URL once the upload (and write)
  // succeed. Never cleared on failure, only on a fresh successful pick.
  const [localSrc, setLocalSrc] = useState<string | null>(null);
  const pendingFileRef = useRef<File | null>(null);
  const objectUrlRef = useRef<string | null>(null);
  const inputRef = useRef<HTMLInputElement>(null);
  const inputId = useId();

  const revokeObjectUrl = useCallback(() => {
    if (objectUrlRef.current) {
      URL.revokeObjectURL(objectUrlRef.current);
      objectUrlRef.current = null;
    }
  }, []);

  // Revoke on unmount, whatever state an in-flight upload was in.
  useEffect(() => () => revokeObjectUrl(), [revokeObjectUrl]);

  const src = localSrc ?? images[slotId];

  const startUpload = useCallback(
    (file: File) => {
      pendingFileRef.current = file;
      revokeObjectUrl();
      const objectUrl = URL.createObjectURL(file);
      objectUrlRef.current = objectUrl;
      setLocalSrc(objectUrl);
      setError("");
      setUploading(true);
      setProgress(0);

      uploadSlotImage(slotId, file, setProgress)
        .then(async (url) => {
          await commitSlotImage(slotId, url);
          revokeObjectUrl();
          setLocalSrc(url);
          setUploading(false);
          setProgress(0);
          pendingFileRef.current = null;
        })
        .catch((err) => {
          setUploading(false);
          const message = err instanceof Error ? err.message : "Upload failed. Try again.";
          setError(message);
          showSnack(message, "error");
          // `localSrc` (the local preview) is deliberately left set — a
          // failed upload must never clear the tile.
        });
    },
    [slotId, commitSlotImage, showSnack, revokeObjectUrl]
  );

  const readFile = useCallback(
    (file: File | undefined) => {
      if (!file || !file.type.startsWith("image/") || disabled) return;
      startUpload(file);
    },
    [startUpload, disabled]
  );

  const retry = useCallback(() => {
    if (pendingFileRef.current) startUpload(pendingFileRef.current);
  }, [startUpload]);

  return (
    <div
      onDragOver={(e) => {
        if (disabled) return;
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
        accept="image/jpeg,image/png,image/webp"
        className="sr-only"
        disabled={disabled}
        onChange={(e) => {
          readFile(e.target.files?.[0]);
          // Allow re-picking the same file straight after a removal.
          e.target.value = "";
        }}
      />
      <button
        type="button"
        onClick={() => !disabled && inputRef.current?.click()}
        disabled={disabled}
        title={disabled ? disabledHint : undefined}
        aria-label={src ? `Replace image: ${placeholder}` : `Add image: ${placeholder}`}
        className={cn(
          "group flex h-full w-full items-center justify-center overflow-hidden border border-dashed transition-colors",
          rounded,
          src ? "border-transparent" : "hover:bg-white/5",
          dragging && "!border-[var(--m3-pri)]",
          disabled && "cursor-not-allowed opacity-50"
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
          // A local/object or `https` URL of arbitrary dimensions —
          // next/image would need a loader and buys nothing here.
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
            {!compact && <span className="leading-tight">{disabled ? disabledHint ?? placeholder : placeholder}</span>}
          </span>
        )}
      </button>

      {uploading && (
        <div className="pointer-events-none absolute inset-x-0 bottom-0 h-1 bg-black/30">
          <div
            className="h-full bg-[var(--m3-pri)] transition-[width]"
            style={{ width: `${Math.round(progress * 100)}%` }}
          />
        </div>
      )}

      {error && (
        <div className="absolute inset-x-0 bottom-0 flex items-center justify-between gap-1 bg-black/70 px-1.5 py-1">
          <span className="truncate text-[10px] text-white" title={error}>
            {error}
          </span>
          <button
            type="button"
            onClick={retry}
            aria-label="Retry upload"
            className="flex shrink-0 items-center gap-1 rounded bg-white/15 px-1.5 py-0.5 text-[10px] font-medium text-white hover:bg-white/25"
          >
            <RotateCw size={10} />
            Retry
          </button>
        </div>
      )}
    </div>
  );
}
