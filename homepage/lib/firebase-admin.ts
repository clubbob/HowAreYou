import { initializeApp, getApps, cert, App } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';

let adminApp: App | null = null;
let _firestore: ReturnType<typeof getFirestore> | null = null;

export function getAdminFirestore() {
  if (_firestore) return _firestore;
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
  if (adminApp) {
    _firestore = getFirestore(adminApp);
  }
  return _firestore;
}

// API 라우트 로드 시 사전 초기화 (첫 요청 지연 완화)
if (typeof process !== 'undefined' && process.env.FIREBASE_SERVICE_ACCOUNT_JSON) {
  getAdminFirestore();
}
