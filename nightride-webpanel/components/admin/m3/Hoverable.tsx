"use client";

import { useState } from "react";
import type { CSSProperties, MouseEventHandler, ReactNode } from "react";

export function Hoverable({
  as = "div",
  style,
  hoverStyle,
  onClick,
  className,
  title,
  disabled,
  children,
}: {
  as?: "div" | "button";
  style: CSSProperties;
  hoverStyle?: CSSProperties;
  onClick?: MouseEventHandler;
  className?: string;
  title?: string;
  disabled?: boolean;
  children?: ReactNode;
}) {
  const [hovered, setHovered] = useState(false);
  const merged = hovered && hoverStyle && !disabled ? { ...style, ...hoverStyle } : style;
  const Tag = as as "div";

  return (
    <Tag
      style={merged}
      onMouseEnter={() => setHovered(true)}
      onMouseLeave={() => setHovered(false)}
      onClick={disabled ? undefined : onClick}
      className={className}
      title={title}
      {...(as === "button" ? { disabled, type: "button" as const } : {})}
    >
      {children}
    </Tag>
  );
}
