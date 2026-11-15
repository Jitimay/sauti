/**
 * Sauti Cloud Functions — SANDBOX bank execution.
 *
 * The client can never move money by writing Firestore (rules deny it).
 * All money movement happens here, inside a Firestore transaction, after:
 *   1. Firebase Auth verification (request.auth),
 *   2. App Check verification (enforceAppCheck),
 *   3. strict input parsing (unknown keys rejected),
 *   4. ownership checks (account + beneficiary under users/{uid}),
 *   5. limits & balance checks,
 *   6. idempotency (users/{uid}/transferRequests/{key}).
 */
import { initializeApp } from 'firebase-admin/app';
import { FieldValue, getFirestore, Timestamp } from 'firebase-admin/firestore';
import { HttpsError, onCall } from 'firebase-functions/v2/https';
import { logger } from 'firebase-functions/v2';

import { checkTransfer, isSameRequest, parseTransferInput, POLICY, RuleError, startOfDayUtcPlus2 } from './transfer_rules';

initializeApp();
const db = getFirestore();

const callableOptions = {
  region: 'europe-west1',
  enforceAppCheck: true,
  // Replay protection for this sensitive endpoint.
  consumeAppCheckToken: true,
} as const;

/**
 * `consumeAppCheckToken` only marks the token as used; the framework does not
 * reject a replayed token by itself. Sensitive handlers must check it.
 */
function rejectReplayedAppCheckToken(app: { alreadyConsumed?: boolean } | undefined): void {
  if (!app || app.alreadyConsumed) {
    throw new HttpsError('unauthenticated', 'app_check_token_replayed');
  }
}

function fail(code: RuleError): never {
  const httpsCode = code === 'invalid_argument' ? 'invalid-argument' : 'failed-precondition';
  throw new HttpsError(httpsCode, code);
}

export const submitTransfer = onCall(callableOptions, async (request) => {
  const uid = request.auth?.uid;
  if (!uid) throw new HttpsError('unauthenticated', 'sign_in_required');
  rejectReplayedAppCheckToken(request.app);

  const parsed = parseTransferInput(request.data);
  if (typeof parsed === 'string') fail(parsed);
  const input = parsed;

  const user = db.collection('users').doc(uid);
  const accountRef = user.collection('accounts').doc(input.fromAccountId);
  const beneficiaryRef = user.collection('beneficiaries').doc(input.beneficiaryId);
  const requestRef = user.collection('transferRequests').doc(input.idempotencyKey);

  const receipt = await db.runTransaction(async (tx) => {
    const prior = await tx.get(requestRef);
    if (prior.exists) {
      const p = prior.data()!;
      if (!isSameRequest(p.request, input)) fail('idempotency_conflict');
      return p.receipt as Record<string, unknown>;
    }

    const [account, beneficiary] = await Promise.all([tx.get(accountRef), tx.get(beneficiaryRef)]);
    if (!account.exists) fail('unknown_account');
    const acc = account.data()!;

    const now = new Date();
    const todays = await tx.get(
      user
        .collection('transactions')
        .where('direction', '==', 'outgoing')
        .where('category', '==', 'transfer')
        .where('timestamp', '>=', Timestamp.fromDate(startOfDayUtcPlus2(now))),
    );
    const transferredTodayMinor = todays.docs.reduce((sum, d) => sum + (d.get('amount.minor') as number), 0);

    const err = checkTransfer(input, {
      availableMinor: acc.availableBalance.minor,
      currency: acc.availableBalance.currency,
      transferredTodayMinor,
      beneficiaryExists: beneficiary.exists,
    });
    if (err) fail(err);

    const ben = beneficiary.data()!;
    const total = input.amountMinor + POLICY.flatFeeMinor;
    const newAvailable = acc.availableBalance.minor - total;
    const txRef = user.collection('transactions').doc();
    // Firestore auto-ids are unique; a timestamp alone can collide.
    const reference = `SAUTI-SBX-${txRef.id.toUpperCase()}`;
    const money = (minor: number) => ({ minor, currency: POLICY.currency });

    tx.update(accountRef, {
      'balance.minor': FieldValue.increment(-total),
      'availableBalance.minor': FieldValue.increment(-total),
    });
    tx.set(txRef, {
      accountId: input.fromAccountId,
      direction: 'outgoing',
      amount: money(input.amountMinor),
      counterparty: ben.name,
      category: 'transfer',
      description: input.note ? `Transfer sent — ${input.note}` : 'Transfer sent',
      timestamp: Timestamp.fromDate(now),
      status: 'completed',
      reference,
      ...(POLICY.flatFeeMinor > 0 ? { fee: money(POLICY.flatFeeMinor) } : {}),
    });
    tx.set(user.collection('notifications').doc(), {
      kind: 'transferSent',
      timestamp: Timestamp.fromDate(now),
      amount: money(input.amountMinor),
      counterparty: ben.name,
      transactionId: txRef.id,
      read: false,
    });

    const r = {
      reference,
      idempotencyKey: input.idempotencyKey,
      beneficiaryName: ben.name,
      beneficiaryMasked: ben.maskedAccount,
      amountMinor: input.amountMinor,
      feeMinor: POLICY.flatFeeMinor,
      newBalanceMinor: newAvailable,
      currency: POLICY.currency,
      executedAt: now.toISOString(),
      transactionId: txRef.id,
    };
    tx.create(requestRef, {
      request: {
        amountMinor: input.amountMinor,
        beneficiaryId: input.beneficiaryId,
        fromAccountId: input.fromAccountId,
        note: input.note ?? null,
      },
      receipt: r,
      createdAt: FieldValue.serverTimestamp(),
    });
    return r;
  });

  // Audit log without PII beyond the uid.
  logger.info('transfer_executed', { uid, amountMinor: input.amountMinor, ref: receipt.reference });
  return receipt;
});

/**
 * Provisions a SANDBOX account with fictitious data for a newly registered
 * live-mode user. Idempotent; never touches existing accounts.
 */
export const provisionSandboxAccount = onCall(callableOptions, async (request) => {
  const uid = request.auth?.uid;
  if (!uid) throw new HttpsError('unauthenticated', 'sign_in_required');
  rejectReplayedAppCheckToken(request.app);
  const user = db.collection('users').doc(uid);
  const main = user.collection('accounts').doc('sandbox-main');

  const created = await db.runTransaction(async (tx) => {
    if ((await tx.get(main)).exists) return false;
    const m = (minor: number) => ({ minor, currency: 'BIF' });
    const now = Date.now();
    tx.set(main, {
      name: 'Sandbox current account',
      maskedNumber: '•••• 0001',
      type: 'current',
      balance: m(250000),
      availableBalance: m(250000),
      institution: 'Sauti Sandbox Bank',
    });
    const bens = [
      ['sandbox-jean', 'Jean Ndayishimiye', '•••• 1104', ['Jean']],
      ['sandbox-aline', 'Aline Irakoze', '•••• 5532', ['Aline']],
    ] as const;
    for (const [id, name, masked, aliases] of bens) {
      tx.set(user.collection('beneficiaries').doc(id), {
        name,
        maskedAccount: masked,
        institution: 'Sauti Sandbox Bank',
        aliases,
      });
    }
    tx.set(user.collection('transactions').doc(), {
      accountId: 'sandbox-main',
      direction: 'incoming',
      amount: m(50000),
      counterparty: 'Jean Ndayishimiye',
      category: 'income',
      description: 'Transfer received',
      timestamp: Timestamp.fromMillis(now - 3600_000),
      status: 'completed',
    });
    return true;
  });
  return { created };
});
