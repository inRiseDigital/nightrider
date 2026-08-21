import { RECAPTCHA_CONTAINER_ID } from "@/lib/organizer/constants";

/**
 * Mount point for the invisible reCAPTCHA widget backing phone verification.
 *
 * `RecaptchaVerifier` resolves this element when it is constructed, and the
 * store builds a fresh verifier for every send — including a resend from the
 * OTP stage — so both the phone and OTP stages render it. Only one stage is
 * mounted at a time (see ApplicationFlow), so the shared id never collides.
 *
 * Google's "protected by reCAPTCHA" badge is deliberately left visible: it
 * floats bottom-right, clear of the 400px card, and hiding it obliges us to
 * reproduce Google's Terms/Privacy disclosure in the UI instead.
 */
export function RecaptchaContainer() {
  return <div id={RECAPTCHA_CONTAINER_ID} />;
}
