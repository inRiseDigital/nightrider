/** `users/{uid}` account-identity fields the organizer can change directly. */
export interface AccountIdentity {
  email: string;
  phone: string;
}

export function parseAccountIdentity(data: Record<string, unknown> | undefined): AccountIdentity {
  const d = data ?? {};
  return {
    email: typeof d.email === "string" ? d.email : "",
    phone: typeof d.phone === "string" ? d.phone : "",
  };
}

export function toAccountIdentityFields(
  ui: AccountIdentity,
  ctx: { raw: Record<string, unknown> }
): Record<string, unknown> {
  return { ...ctx.raw, email: ui.email, phone: ui.phone };
}
