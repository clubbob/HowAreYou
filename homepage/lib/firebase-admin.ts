import { initializeApp, getApps, cert, App } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';

let adminApp: App | null = null;

export function getAdminFirestore() {
  if (!adminApp) {
    const existing = getApps();
    if (existing.length > 0) {
      adminApp = existing[0] as App;
    } else {
      const cred = process.env.FIREBASE_SERVICE_ACCOUNT_JSON;
      if (cred) {
        try {
          const key = JSON.parse(cred);
          adminApp = initializeApp({ credential: cert(key) });
        } catch {
          console.warn('[firebase-admin] FIREBASE_SERVICE_ACCOUNT_JSON 파싱 실패');
        }
      } else {
        try {
          adminApp = initializeApp();
        } catch {
          console.warn('[firebase-admin] Application Default Credentials 없음');
        }
      }
    }
  }
  return adminApp ? getFirestore(adminApp) : null;
}
