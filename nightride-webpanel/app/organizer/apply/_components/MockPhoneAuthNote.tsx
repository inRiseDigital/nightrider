import { OTP_LENGTH, PHONE_AUTH_MOCK } from "@/lib/organizer/constants";

/**
 * Renders only while `PHONE_AUTH_MOCK` is on, and deliberately in production
 * builds too, not just in dev: a mocked flow that looks real is how a demo
 * gets mistaken for working verification, and how the flag gets left on. The
 * amber styling keeps it distinct from ErrorNote's red.
 */
export function MockPhoneAuthNote() {
  if (!PHONE_AUTH_MOCK) return null;

  return (
    <p
      role="status"
      className="mt-3 rounded-lg border border-amber-500/30 bg-amber-500/10 px-3 py-2.5 text-center text-[11px] leading-relaxed text-amber-400"
    >
      Phone verification is mocked — no SMS is sent and any {OTP_LENGTH} digits will pass.
    </p>
  );
}
