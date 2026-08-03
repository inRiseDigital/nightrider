export function DetailRow({ label, value }: { label: string; value: string }) {
  return (
    <div className="flex justify-between gap-4">
      <dt className="text-nr-text-hint">{label}</dt>
      <dd className="truncate text-right text-nr-text-primary">{value}</dd>
    </div>
  );
}
