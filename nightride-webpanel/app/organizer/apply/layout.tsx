import type { ReactNode } from "react";
import { ApplyMaterialShell } from "./_components/ApplyMaterialShell";
import "./material.css";

export default function ApplyLayout({ children }: { children: ReactNode }) {
  return <ApplyMaterialShell>{children}</ApplyMaterialShell>;
}
