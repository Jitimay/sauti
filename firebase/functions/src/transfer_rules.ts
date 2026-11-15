/**
 * Pure, framework-free transfer validation. The single source of truth for
 * server-side money rules; unit-tested without emulators.
 */

export const POLICY = {
  currency: 'BIF',
  minimumMinor: 500,
  perTransferLimitMinor: 2_000_000,
  dailyLimitMinor: 5_000_000,
  flatFeeMinor: 0,
} as const;

export interface TransferInput {
  idempotencyKey: string;
  fromAccountId: string;
  beneficiaryId: string;
  amountMinor: number;
  currency: string;
  note?: string;
}

export type RuleError =
  | 'invalid_argument'
  | 'invalid_amount'
  | 'limit_exceeded'
  | 'insufficient_funds'
  | 'unknown_beneficiary'
  | 'unknown_account'
  | 'idempotency_conflict';

const ID = /^[A-Za-z0-9_-]{1,128}$/;

/** Strictly parses untrusted callable data. Unknown keys are rejected. */
export function parseTransferInput(data: unknown): TransferInput | RuleError {
  if (typeof data !== 'object' || data === null || Array.isArray(data)) return 'invalid_argument';
  const d = data as Record<string, unknown>;
  const allowed = new Set(['idempotencyKey', 'fromAccountId', 'beneficiaryId', 'amountMinor', 'currency', 'note']);
  if (Object.keys(d).some((k) => !allowed.has(k))) return 'invalid_argument';
  const { idempotencyKey, fromAccountId, beneficiaryId, amountMinor, currency, note } = d;
  if (typeof idempotencyKey !== 'string' || !ID.test(idempotencyKey) || idempotencyKey.length < 16) return 'invalid_argument';
  if (typeof fromAccountId !== 'string' || !ID.test(fromAccountId)) return 'invalid_argument';
  if (typeof beneficiaryId !== 'string' || !ID.test(beneficiaryId)) return 'invalid_argument';
  if (typeof amountMinor !== 'number' || !Number.isSafeInteger(amountMinor)) return 'invalid_amount';
  if (currency !== POLICY.currency) return 'invalid_amount';
  if (note !== undefined && (typeof note !== 'string' || note.length > 140)) return 'invalid_argument';
  return { idempotencyKey, fromAccountId, beneficiaryId, amountMinor, currency, note: note as string | undefined };
}

export interface LedgerState {
  availableMinor: number;
  currency: string;
  transferredTodayMinor: number;
  beneficiaryExists: boolean;
}

/** Business checks against current ledger state (inside a transaction). */
export function checkTransfer(input: TransferInput, s: LedgerState): RuleError | null {
  if (!s.beneficiaryExists) return 'unknown_beneficiary';
  if (s.currency !== input.currency) return 'invalid_amount';
  if (input.amountMinor < POLICY.minimumMinor) return 'invalid_amount';
  if (input.amountMinor > POLICY.perTransferLimitMinor) return 'limit_exceeded';
  if (s.transferredTodayMinor + input.amountMinor > POLICY.dailyLimitMinor) return 'limit_exceeded';
  if (input.amountMinor + POLICY.flatFeeMinor > s.availableMinor) return 'insufficient_funds';
  return null;
}

/** A replay is valid only if it is the same request. */
export function isSameRequest(
  stored: { amountMinor: number; beneficiaryId: string; fromAccountId: string; note?: string | null },
  input: TransferInput,
): boolean {
  return (
    stored.amountMinor === input.amountMinor &&
    stored.beneficiaryId === input.beneficiaryId &&
    stored.fromAccountId === input.fromAccountId &&
    (stored.note ?? null) === (input.note ?? null)
  );
}

export function startOfDayUtcPlus2(now: Date): Date {
  // Burundi is UTC+2 year-round (no DST).
  const shifted = new Date(now.getTime() + 2 * 3600_000);
  shifted.setUTCHours(0, 0, 0, 0);
  return new Date(shifted.getTime() - 2 * 3600_000);
}
