import { NextResponse } from 'next/server';
import { verifyAdminSession } from '@/lib/admin-auth';
import { getAdminFirestore } from '@/lib/firebase-admin';

function normalizePhone(phone: string): string {
  if (!phone || typeof phone !== 'string') return '';
  const digits = phone.replace(/\D/g, '');
  if (digits.length === 0) return '';
  if (digits.startsWith('82') && digits.length >= 11) return '+' + digits;
  if (digits.startsWith('010') && digits.length >= 9) return '+82' + digits.substring(1);
  if (digits.startsWith('0') && digits.length >= 10) return '+82' + digits.substring(1);
  return '+82' + digits;
}

export async function GET() {
  if (!(await verifyAdminSession())) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
  }
  const db = getAdminFirestore();
  if (!db) {
    return NextResponse.json({ error: 'Firestore not configured' }, { status: 500 });
  }

  const [waitlistSnap, usersSnap] = await Promise.all([
    db.collection('waitlist').limit(500).get(),
    db.collection('users').get(),
  ]);

  const usersPhoneSet = new Set<string>();
  const phoneToSignedOut = new Map<string, boolean>();
  for (const doc of usersSnap.docs) {
    const data = doc.data();
    const phone = (data.phone ?? '').toString().trim();
    if (!phone) continue;
    const normalized = normalizePhone(phone);
    usersPhoneSet.add(normalized);
    if (data.signedOutAt) {
      phoneToSignedOut.set(normalized, true);
    }
  }
  const loggedInPhoneSet = new Set(
    [...usersPhoneSet].filter((p) => !phoneToSignedOut.get(p))
  );

  const list = waitlistSnap.docs
    .map((doc) => {
      const d = doc.data();
      const phone = d.phone ?? '';
      const normalized = normalizePhone(phone);
      const createdAt = d.createdAt?.toDate?.() ?? new Date();
      const lastFcmSentAt = d.lastFcmSentAt?.toDate?.();
      const lastFcmOpenedAt = d.lastFcmOpenedAt?.toDate?.();
      const loggedIn = phone ? loggedInPhoneSet.has(normalized) : false;
      const appInstalled = phone ? usersPhoneSet.has(normalized) : false;
      return {
        id: doc.id,
        phone,
        name: d.name ?? '',
        cohort: d.cohort ?? '1',
        createdAt: createdAt.toISOString(),
        loggedIn,
        appInstalled,
        lastFcmSentAt: lastFcmSentAt ? lastFcmSentAt.toISOString() : null,
        lastFcmOpenedAt: lastFcmOpenedAt ? lastFcmOpenedAt.toISOString() : null,
      };
    })
    .filter((item) => item.phone)
    .sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime());
  return NextResponse.json(list);
}
