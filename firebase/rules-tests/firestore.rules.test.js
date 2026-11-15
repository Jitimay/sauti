// Firestore security rules tests. Requires Java 21+ for the emulator.
//   cd firebase/rules-tests && npm install && npm test
import { readFileSync } from 'node:fs';
import { after, before, beforeEach, test } from 'node:test';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import { doc, getDoc, setDoc, updateDoc, deleteDoc, collection, getDocs } from 'firebase/firestore';

let env;

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-sauti',
    firestore: { rules: readFileSync(new URL('../firestore.rules', import.meta.url), 'utf8') },
  });
});

after(async () => env.cleanup());

beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await setDoc(doc(db, 'users/alice'), { displayName: 'Alice' });
    await setDoc(doc(db, 'users/alice/accounts/main'), { availableBalance: { minor: 250000, currency: 'BIF' } });
    await setDoc(doc(db, 'users/alice/transactions/t1'), { amount: { minor: 100, currency: 'BIF' } });
    await setDoc(doc(db, 'users/alice/beneficiaries/b1'), { name: 'Jean' });
    await setDoc(doc(db, 'users/alice/notifications/n1'), { kind: 'reminder', read: false });
    await setDoc(doc(db, 'users/bob/accounts/main'), { availableBalance: { minor: 999, currency: 'BIF' } });
  });
});

const alice = () => env.authenticatedContext('alice').firestore();
const anon = () => env.unauthenticatedContext().firestore();

test('owner can read own banking data', async () => {
  await assertSucceeds(getDoc(doc(alice(), 'users/alice/accounts/main')));
  await assertSucceeds(getDocs(collection(alice(), 'users/alice/transactions')));
  await assertSucceeds(getDocs(collection(alice(), 'users/alice/beneficiaries')));
});

test('unauthenticated access is denied', async () => {
  await assertFails(getDoc(doc(anon(), 'users/alice/accounts/main')));
  await assertFails(getDoc(doc(anon(), 'users/alice')));
});

test("cannot read another user's data", async () => {
  await assertFails(getDoc(doc(alice(), 'users/bob/accounts/main')));
  await assertFails(getDocs(collection(alice(), 'users/bob/transactions')));
});

test('clients can never write money state', async () => {
  await assertFails(updateDoc(doc(alice(), 'users/alice/accounts/main'), { 'availableBalance.minor': 1e9 }));
  await assertFails(setDoc(doc(alice(), 'users/alice/transactions/x'), { amount: { minor: 1, currency: 'BIF' } }));
  await assertFails(deleteDoc(doc(alice(), 'users/alice/transactions/t1')));
  await assertFails(setDoc(doc(alice(), 'users/alice/beneficiaries/evil'), { name: 'Attacker' }));
  await assertFails(setDoc(doc(alice(), 'users/alice/transferRequests/k'), { receipt: {} }));
});

test('notifications: only flipping read to true is allowed', async () => {
  await assertSucceeds(updateDoc(doc(alice(), 'users/alice/notifications/n1'), { read: true }));
  await assertFails(updateDoc(doc(alice(), 'users/alice/notifications/n1'), { kind: 'paymentReceived' }));
  await assertFails(setDoc(doc(alice(), 'users/alice/notifications/new'), { kind: 'security', read: false }));
});

test('profile: whitelisted fields only, size-limited', async () => {
  await assertSucceeds(updateDoc(doc(alice(), 'users/alice'), { displayName: 'Alice N.' }));
  await assertFails(updateDoc(doc(alice(), 'users/alice'), { role: 'admin' }));
  await assertFails(updateDoc(doc(alice(), 'users/alice'), { displayName: 'x'.repeat(81) }));
});

test('conversations: own, bounded, language-restricted', async () => {
  const ref = doc(alice(), 'users/alice/conversations/c1');
  await assertSucceeds(setDoc(ref, { messages: [], language: 'rn', updatedAt: 1 }));
  await assertFails(setDoc(ref, { messages: [], language: 'xx', updatedAt: 1 }));
  await assertFails(setDoc(ref, { messages: [], language: 'en', balance: 1 }));
  await assertFails(setDoc(doc(alice(), 'users/bob/conversations/c1'), { messages: [], language: 'en', updatedAt: 1 }));
});

test('unknown top-level collections are denied', async () => {
  await assertFails(setDoc(doc(alice(), 'admin/config'), { open: true }));
  await assertFails(getDoc(doc(alice(), 'admin/config')));
});
