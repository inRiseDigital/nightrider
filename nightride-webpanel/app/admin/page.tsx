import { AdminConsole } from "@/components/admin/m3/AdminConsole";
import { AdminGate } from "@/components/admin/m3/AdminGate";

export default function AdminPage() {
  return (
    <AdminGate>
      <AdminConsole />
    </AdminGate>
  );
}
