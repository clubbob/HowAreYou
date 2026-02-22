import { NextResponse } from 'next/server';
import { verifyAdminSession } from '@/lib/admin-auth';
import { getAdminFirestore } from '@/lib/firebase-admin';

export async function GET() {
  if (!(await verifyAdminSession())) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
  }
  const db = getAdminFirestore();
  if (!db) {
    return NextResponse.json({
      usersCount: 0,
      inquiriesCount: 0,
      unansweredInquiriesCount: 0,
      announcementsCount: 0,
      waitlistCount: 0,
      serviceFeedbackCount: 0,
      firebaseConfigured: false,
    });
  }

  const [usersSnap, inquiriesSnap, announcementsSnap, waitlistSnap, serviceFeedbackSnap] =
    await Promise.all([
      db.collection('users').get(),
      db.collection('inquiries').limit(300).get(),
      db.collection('announcements').get(),
      db.collection('waitlist').get(),
      db.collection('service_feedback').limit(500).get(),
    ]);

  const inquiries = inquiriesSnap.docs.map((d) => d.data());
  const unansweredCount = inquiries.filter((i) => !(i.replies && i.replies.length > 0)).length;

  return NextResponse.json({
    usersCount: usersSnap.size,
    inquiriesCount: inquiriesSnap.size,
    unansweredInquiriesCount: unansweredCount,
    announcementsCount: announcementsSnap.size,
    waitlistCount: waitlistSnap.size,
    serviceFeedbackCount: serviceFeedbackSnap.size,
    firebaseConfigured: true,
  });
}
