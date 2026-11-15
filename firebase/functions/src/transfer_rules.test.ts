import { strict as assert } from 'node:assert';
import { test } from 'node:test';
import { checkTransfer, isSameRequest, parseTransferInput, POLICY, startOfDayUtcPlus2 } from './transfer_rules';

const valid = {
  idempotencyKey: '3f1c2b9a-0000-4000-8000-000000000001',
  fromAccountId: 'acc-main',
  beneficiaryId: 'ben-jean',
  amountMinor: 20000,
  currency: 'BIF',
};
const ledger = { availableMinor: 250000, currency: 'BIF', transferredTodayMinor: 0, beneficiaryExists: true };

test('parses a valid request', () => {
  const r = parseTransferInput(valid);
  assert.equal(typeof r, 'object');
});

test('rejects unknown keys (e.g. injected uid or balance)', () => {
  assert.equal(parseTransferInput({ ...valid, uid: 'victim' }), 'invalid_argument');
  assert.equal(parseTransferInput({ ...valid, newBalance: 1e9 }), 'invalid_argument');
});

test('rejects malformed values', () => {
  assert.equal(parseTransferInput(null), 'invalid_argument');
  assert.equal(parseTransferInput([]), 'invalid_argument');
  assert.equal(parseTransferInput({ ...valid, idempotencyKey: 'short' }), 'invalid_argument');
  assert.equal(parseTransferInput({ ...valid, beneficiaryId: '../x' }), 'invalid_argument');
  assert.equal(parseTransferInput({ ...valid, amountMinor: 20000.5 }), 'invalid_amount');
  assert.equal(parseTransferInput({ ...valid, amountMinor: '20000' }), 'invalid_amount');
  assert.equal(parseTransferInput({ ...valid, currency: 'USD' }), 'invalid_amount');
  assert.equal(parseTransferInput({ ...valid, note: 'x'.repeat(141) }), 'invalid_argument');
});

test('business checks', () => {
  const input = parseTransferInput(valid);
  if (typeof input === 'string') throw new Error(input);
  assert.equal(checkTransfer(input, ledger), null);
  assert.equal(checkTransfer({ ...input, amountMinor: 499 }, ledger), 'invalid_amount');
  assert.equal(checkTransfer({ ...input, amountMinor: -1 }, ledger), 'invalid_amount');
  assert.equal(checkTransfer({ ...input, amountMinor: POLICY.perTransferLimitMinor + 1 }, { ...ledger, availableMinor: 1e9 }), 'limit_exceeded');
  assert.equal(checkTransfer(input, { ...ledger, transferredTodayMinor: POLICY.dailyLimitMinor }), 'limit_exceeded');
  assert.equal(checkTransfer({ ...input, amountMinor: 250001 }, ledger), 'insufficient_funds');
  assert.equal(checkTransfer(input, { ...ledger, beneficiaryExists: false }), 'unknown_beneficiary');
});

test('idempotent replay must match the original request', () => {
  const input = parseTransferInput(valid);
  if (typeof input === 'string') throw new Error(input);
  assert.equal(isSameRequest({ amountMinor: 20000, beneficiaryId: 'ben-jean', fromAccountId: 'acc-main' }, input), true);
  assert.equal(isSameRequest({ amountMinor: 30000, beneficiaryId: 'ben-jean', fromAccountId: 'acc-main' }, input), false);
  // Same key reused with a different note is a different request.
  assert.equal(
    isSameRequest({ amountMinor: 20000, beneficiaryId: 'ben-jean', fromAccountId: 'acc-main', note: 'rent' }, input),
    false,
  );
  // Records written before notes were stored (note missing) still match a note-less retry.
  assert.equal(isSameRequest({ amountMinor: 20000, beneficiaryId: 'ben-jean', fromAccountId: 'acc-main', note: null }, input), true);
});

test('Burundi day boundary (UTC+2)', () => {
  const d = startOfDayUtcPlus2(new Date('2026-11-18T21:30:00Z')); // 23:30 local
  assert.equal(d.toISOString(), '2026-11-17T22:00:00.000Z');
});
