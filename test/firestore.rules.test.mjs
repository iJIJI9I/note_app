import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { after, before, beforeEach, test } from 'node:test';

import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  collection,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  serverTimestamp,
  setDoc,
  updateDoc,
} from 'firebase/firestore';

const ownerId = 'note-owner';
const otherUserId = 'another-user';
const notePath = `users/${ownerId}/notes/note-1`;

let testEnvironment;

before(async () => {
  testEnvironment = await initializeTestEnvironment({
    projectId: 'demo-notes-app',
    firestore: {
      rules: await readFile(new URL('../firestore.rules', import.meta.url), 'utf8'),
    },
  });
});

beforeEach(async () => {
  await testEnvironment.clearFirestore();
});

after(async () => {
  await testEnvironment.cleanup();
});

function validNote(overrides = {}) {
  return {
    title: 'Private note',
    content: 'Only its owner should read this.',
    createdAt: serverTimestamp(),
    updatedAt: null,
    ...overrides,
  };
}

test('allows an owner to create, read, update, list, and delete a note', async () => {
  const db = testEnvironment.authenticatedContext(ownerId).firestore();
  const noteRef = doc(db, notePath);

  await assertSucceeds(setDoc(noteRef, validNote()));
  await assertSucceeds(getDoc(noteRef));
  await assertSucceeds(getDocs(collection(db, `users/${ownerId}/notes`)));

  const storedNote = await getDoc(noteRef);
  await assertSucceeds(
    updateDoc(noteRef, {
      title: 'Updated note',
      updatedAt: serverTimestamp(),
    }),
  );
  assert.equal(storedNote.data().title, 'Private note');

  await assertSucceeds(deleteDoc(noteRef));
});

test('denies unauthenticated access', async () => {
  const db = testEnvironment.unauthenticatedContext().firestore();

  await assertFails(setDoc(doc(db, notePath), validNote()));
  await assertFails(getDoc(doc(db, notePath)));
  await assertFails(getDocs(collection(db, `users/${ownerId}/notes`)));
});

test('denies another authenticated user access to the owner notes', async () => {
  const ownerDb = testEnvironment.authenticatedContext(ownerId).firestore();
  await assertSucceeds(setDoc(doc(ownerDb, notePath), validNote()));

  const otherDb = testEnvironment.authenticatedContext(otherUserId).firestore();
  const noteRef = doc(otherDb, notePath);

  await assertFails(getDoc(noteRef));
  await assertFails(getDocs(collection(otherDb, `users/${ownerId}/notes`)));
  await assertFails(setDoc(noteRef, validNote()));
  await assertFails(deleteDoc(noteRef));
});

test('rejects unknown fields and nested objects', async () => {
  const db = testEnvironment.authenticatedContext(ownerId).firestore();

  await assertFails(
    setDoc(
      doc(db, notePath),
      validNote({ injected: { admin: true } }),
    ),
  );
  await assertFails(
    setDoc(doc(db, notePath), validNote({ content: { payload: true } })),
  );
});

test('rejects oversized fields and empty titles', async () => {
  const db = testEnvironment.authenticatedContext(ownerId).firestore();

  await assertFails(setDoc(doc(db, notePath), validNote({ title: '' })));
  await assertFails(
    setDoc(doc(db, notePath), validNote({ title: 't'.repeat(121) })),
  );
  await assertFails(
    setDoc(doc(db, notePath), validNote({ content: 'c'.repeat(20001) })),
  );
});

test('rejects forged timestamps and changes to creation time', async () => {
  const db = testEnvironment.authenticatedContext(ownerId).firestore();
  const noteRef = doc(db, notePath);

  await assertFails(
    setDoc(
      noteRef,
      validNote({ createdAt: new Date('2020-01-01T00:00:00.000Z') }),
    ),
  );
  await assertSucceeds(setDoc(noteRef, validNote()));
  await assertFails(
    updateDoc(noteRef, {
      createdAt: new Date('2020-01-01T00:00:00.000Z'),
      updatedAt: serverTimestamp(),
    }),
  );
});
