import { collection, addDoc, serverTimestamp } from 'firebase/firestore';
import { firestore } from './firebase';

export async function addToWaitlist(email: string): Promise<void> {
  if (!firestore) {
    throw new Error('Firebase가 설정되지 않았습니다. 관리자에게 문의해 주세요.');
  }
  await addDoc(collection(firestore, 'waitlist'), {
    email: email.trim().toLowerCase(),
    createdAt: serverTimestamp(),
  });
}
