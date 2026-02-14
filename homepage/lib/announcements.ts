import { collection, query, orderBy, limit, getDocs, Timestamp } from 'firebase/firestore';
import { firestore } from './firebase';

export type AnnouncementDoc = {
  id: string;
  title: string;
  content: string;
  createdAt: { seconds: number } | null;
  pinned?: boolean;
};

export async function getAnnouncements(): Promise<AnnouncementDoc[]> {
  if (!firestore) return [];
  const q = query(
    collection(firestore, 'announcements'),
    orderBy('createdAt', 'desc'),
    limit(10)
  );
  const snap = await getDocs(q);
  return snap.docs.map((doc) => {
    const d = doc.data();
    const createdAt = d.createdAt instanceof Timestamp ? d.createdAt : null;
    return {
      id: doc.id,
      title: d.title ?? '',
      content: d.content ?? '',
      createdAt: createdAt ? { seconds: createdAt.seconds } : null,
      pinned: d.pinned ?? false,
    };
  });
}
