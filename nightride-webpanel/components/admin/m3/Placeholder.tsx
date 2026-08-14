import { Icon } from "./Icon";

export function Placeholder({ title }: { title: string }) {
  return (
    <div
      style={{
        height: "60vh",
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        borderRadius: 16,
        background: "#1B181B",
      }}
    >
      <div style={{ textAlign: "center" }}>
        <Icon name="construction" size={40} color="#524549" />
        <div style={{ fontSize: 18, marginTop: 12 }}>{title}</div>
        <div style={{ fontSize: 13, color: "#9A8C91", marginTop: 4 }}>Not built yet — up next</div>
      </div>
    </div>
  );
}
