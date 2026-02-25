import { initializeApp, getApps, cert, App } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { getFirestore } from 'firebase-admin/firestore';
import { getMessaging } from 'firebase-admin/messaging';

let adminApp: App | null = null;
let _firestore: ReturnType<typeof getFirestore> | null = null;

export function getAdminApp(): App | null {
  if (adminApp) return adminApp;
  const existing = getApps();
  if (existing.length > 0) {
    adminApp = existing[0] as App;
    return adminApp;
  }
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
  return adminApp;
}

export function getAdminAuth() {
  const app = getAdminApp();
  return app ? getAuth(app) : null;
}

export function getAdminMessaging() {
  const app = getAdminApp();
  return app ? getMessaging(app) : null;
}

export function getAdminFirestore() {
  if (_firestore) return _firestore;
  const app = getAdminApp();
  if (app) _firestore = getFirestore(app);
  return _firestore;
}

// API 라우트 로드 시 사전 초기화 (첫 요청 지연 완화)
if (typeof process !== 'undefined' && process.env.FIREBASE_SERVICE_ACCOUNT_JSON) {
  getAdminFirestore();
}
