import { cookies } from 'next/headers';
import { createHmac, timingSafeEqual } from 'crypto';

const COOKIE_NAME = 'admin_session';
const SESSION_TTL_MS = 24 * 60 * 60 * 1000; // 24시간

function sign(payload: string, secret: string): string {
  return createHmac('sha256', secret).update(payload).digest('hex');
}

export function createAdminSession(username: string, password: string): string {
  const payload = `${username}|${Date.now()}`;
  const sig = sign(payload, password);
  return Buffer.from(`${payload}.${sig}`).toString('base64url');
}

export async function verifyAdminSession(): Promise<boolean> {
  const username = process.env.ADMIN_USERNAME;
  const password = process.env.ADMIN_PASSWORD;
  if (!username || !password) return false;

  const cookieStore = await cookies();
  const token = cookieStore.get(COOKIE_NAME)?.value;
  if (!token) return false;

  try {
    const decoded = Buffer.from(token, 'base64url').toString('utf8');
    const [payload, sig] = decoded.split('.');
    if (!payload || !sig) return false;

    const expectedSig = sign(payload, password);
    if (expectedSig.length !== sig.length || !timingSafeEqual(Buffer.from(expectedSig), Buffer.from(sig))) {
      return false;
    }

    const [u, ts] = payload.split('|');
    if (u !== username) return false;
    const timestamp = parseInt(ts, 10);
    if (isNaN(timestamp) || Date.now() - timestamp > SESSION_TTL_MS) return false;
    return true;
  } catch {
    return false;
  }
}

export function getAdminSessionCookie(name: string, value: string) {
  return `${name}=${value}; Path=/; HttpOnly; SameSite=Strict; Max-Age=${SESSION_TTL_MS / 1000}`;
}

