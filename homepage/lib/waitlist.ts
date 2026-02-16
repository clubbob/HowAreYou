import { collection, addDoc, serverTimestamp } from 'firebase/firestore';
import { getFunctions, httpsCallable } from 'firebase/functions';
import { app, firestore } from './firebase';

export type WaitlistResult = { status: 'success' } | { status: 'already_registered' };

/** Callable 실패 시 Firestore 직접 등록으로 폴백 */
async function addToWaitlistFallback(email: string): Promise<WaitlistResult> {
  if (!firestore) {
    throw new Error('Firebase가 설정되지 않았습니다. 관리자에게 문의해 주세요.');
  }
  await addDoc(collection(firestore, 'waitlist'), {
    email: email.trim().toLowerCase(),
    createdAt: serverTimestamp(),
  });
  return { status: 'success' };
}

export async function addToWaitlist(email: string): Promise<WaitlistResult> {
  if (!app) {
    throw new Error('Firebase가 설정되지 않았습니다. 관리자에게 문의해 주세요.');
  }

  const functions = getFunctions(app);
  const addToWaitlistFn = httpsCallable<
    { email: string },
    { status: 'success' | 'already_registered' }
  >(functions, 'addToWaitlist');

  try {
    const { data } = await addToWaitlistFn({ email: email.trim() });
    return data as WaitlistResult;
  } catch {
    return addToWaitlistFallback(email);
  }
}
