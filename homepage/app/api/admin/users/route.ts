import { NextResponse } from 'next/server';
import { verifyAdminSession } from '@/lib/admin-auth';
import { getAdminFirestore } from '@/lib/firebase-admin';

export async function GET() {
  if (!(await verifyAdminSession())) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
  }
  const db = getAdminFirestore();
  if (!db) {
    return NextResponse.json({ error: 'Firestore not configured' }, { status: 500 });
  }

  const [usersSnap, subjectsSnap] = await Promise.all([
    db.collection('users').limit(500).get(),
    db.collection('subjects').get(),
  ]);

  const uidToPhone = new Map<string, string>();
  usersSnap.docs.forEach((doc) => {
    const phone = doc.data()?.phone ?? '';
    if (phone) uidToPhone.set(doc.id, phone);
  });

  const guardianUids = new Set<string>();
  const subjectUids = new Set<string>();
  const subjectToGuardians = new Map<string, string[]>();
  const guardianToSubjects = new Map<string, string[]>();

  subjectsSnap.docs.forEach((doc) => {
    const subjectUid = doc.id;
    const data = doc.data();
    const paired = (data?.pairedGuardianUids as string[]) ?? [];
    const guardianInfos = (data?.guardianInfos as Record<string, { phone?: string }>) ?? {};

    subjectUids.add(subjectUid);
    const guardianPhones: string[] = [];
    paired.forEach((gUid: string) => {
      guardianUids.add(gUid);
      guardianPhones.push(guardianInfos[gUid]?.phone || uidToPhone.get(gUid) || '');
      if (!guardianToSubjects.has(gUid)) guardianToSubjects.set(gUid, []);
      guardianToSubjects.get(gUid)!.push(subjectUid);
    });
    subjectToGuardians.set(subjectUid, guardianPhones);
  });

  const list = usersSnap.docs.map((doc) => {
    const d = doc.data();
    const uid = doc.id;
    const isSubject = subjectUids.has(uid);
    const isGuardian = guardianUids.has(uid);
    let role = 'subject';
    if (isSubject && isGuardian) role = 'both';
    else if (isGuardian) role = 'guardian';
    else if (isSubject) role = 'subject';

    const guardianPhones = (isSubject ? subjectToGuardians.get(uid) : null) ?? [];
    const wardPhones = (isGuardian
      ? (guardianToSubjects.get(uid) ?? []).map((sUid) => uidToPhone.get(sUid) || sUid)
      : []) as string[];

    const createdAt = d.createdAt?.toDate?.();
    return {
      id: uid,
      phone: d.phone ?? '',
      displayName: d.displayName ?? null,
      role,
      createdAt: createdAt ? createdAt.toISOString() : null,
      guardianPhones: [...new Set(guardianPhones)].filter(Boolean),
      wardPhones: [...new Set(wardPhones)].filter(Boolean),
    };
  });

  // 동일 전화번호 중복 제거: 하나로 병합 (데이터 오류 방지)
  const byPhone = new Map<string, (typeof list)[0]>();
  for (const u of list) {
    const phone = (u.phone || '').trim();
    if (!phone) continue;
    const existing = byPhone.get(phone);
    if (!existing) {
      byPhone.set(phone, { ...u });
      continue;
    }
    // 병합: 역할 합치기, 연결 정보 합치기, 가장 이른 가입일 사용
    const merged = {
      ...existing,
      id: existing.id,
      role:
        existing.role === 'both' || u.role === 'both'
          ? 'both'
          : existing.role !== u.role
            ? 'both'
            : existing.role,
      guardianPhones: [...new Set([...(existing.guardianPhones ?? []), ...(u.guardianPhones ?? [])])].filter(Boolean),
      wardPhones: [...new Set([...(existing.wardPhones ?? []), ...(u.wardPhones ?? [])])].filter(Boolean),
      displayName: existing.displayName || u.displayName || null,
      createdAt:
        existing.createdAt && u.createdAt && new Date(u.createdAt) < new Date(existing.createdAt)
          ? u.createdAt
          : existing.createdAt,
    };
    byPhone.set(phone, merged);
  }

  const deduped = Array.from(byPhone.values());
  return NextResponse.json(deduped);
}
