/**
 * IP 기반 rate limit (in-memory)
 * 웹 문의 조회(brute-force 방어)용. 서버리스에서 인스턴스별 메모리 사용.
 */

type Entry = { count: number; failCount: number; resetAt: number };

const store = new Map<string, Entry>();

const WINDOW_MS = 60 * 1000; // 1분
const MAX_ATTEMPTS_PER_WINDOW = 15; // 분당 최대 시도
const MAX_FAILS_PER_WINDOW = 5; // 분당 5번 실패 시 차단

function getKey(ip: string): string {
  return `inquiry_check:${ip}`;
}

function now(): number {
  return Date.now();
}

function cleanup(): void {
  const n = now();
  for (const [k, v] of store.entries()) {
    if (v.resetAt < n) store.delete(k);
  }
}

/**
 * 시도 가능 여부 확인. 초과 시 false.
 */
export function checkInquiryLimit(ip: string): { ok: boolean; retryAfterSec?: number } {
  cleanup();
  const key = getKey(ip);
  const entry = store.get(key);
  const n = now();

  if (!entry) return { ok: true };
  if (entry.resetAt < n) return { ok: true };

  if (entry.count >= MAX_ATTEMPTS_PER_WINDOW) {
    return { ok: false, retryAfterSec: Math.ceil((entry.resetAt - n) / 1000) };
  }
  if (entry.failCount >= MAX_FAILS_PER_WINDOW) {
    return { ok: false, retryAfterSec: Math.ceil((entry.resetAt - n) / 1000) };
  }
  return { ok: true };
}

/**
 * 시도 기록 (성공/실패 구분)
 */
export function recordInquiryAttempt(ip: string, success: boolean): void {
  const key = getKey(ip);
  const n = now();
  let entry = store.get(key);

  if (!entry || entry.resetAt < n) {
    entry = { count: 0, failCount: 0, resetAt: n + WINDOW_MS };
    store.set(key, entry);
  }

  entry.count += 1;
  if (!success) entry.failCount += 1;
}

export function getClientIp(request: Request): string {
  const forwarded = request.headers.get('x-forwarded-for');
  if (forwarded) return forwarded.split(',')[0]?.trim() ?? '0.0.0.0';
  const real = request.headers.get('x-real-ip');
  if (real) return real.trim();
  return '0.0.0.0';
}
