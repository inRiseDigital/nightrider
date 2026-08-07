import { LoginForm } from "./_components/LoginForm";

export const metadata = {
  title: "Organizer Login — Night Ride",
  description: "Sign in to the Night Ride organizer panel.",
};

export default function OrganizerLoginPage() {
  return (
    <div className="flex min-h-0 w-full flex-1 items-center justify-center overflow-y-auto px-5 py-10">
      <LoginForm />
    </div>
  );
}
