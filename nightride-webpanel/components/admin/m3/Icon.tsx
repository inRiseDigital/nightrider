import type { CSSProperties } from "react";

export function Icon({
  name,
  size = 20,
  color,
  filled,
  style,
  className,
}: {
  name: string;
  size?: number;
  color?: string;
  filled?: boolean;
  style?: CSSProperties;
  className?: string;
}) {
  return (
    <span
      className={`m3-icon${className ? " " + className : ""}`}
      style={{
        fontSize: size,
        color,
        flexShrink: 0,
        fontVariationSettings: filled ? "'FILL' 1" : undefined,
        ...style,
      }}
    >
      {name}
    </span>
  );
}
