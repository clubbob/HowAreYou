import { randomBytes, scryptSync } from 'crypto';

const SALT_LEN = 16;
const KEY_LEN = 64;
// 문의 비밀번호용: N=4096 (기본 16384 대비 ~4배 빠름)
const SCRYPT_FAST = { N: 4096, r: 8, p: 1 } as const;

export function hashPassword(password: string): string {
  const salt = randomBytes(SALT_LEN).toString('hex');
  const hash = scryptSync(password, salt, KEY_LEN, SCRYPT_FAST).toString('hex');
  return `2:${salt}:${hash}`;
}

export function verifyPassword(password: string, stored: string): boolean {
  const parts = stored.split(':');
  if (parts.length === 2) {
    const [salt, hash] = parts;
    if (!salt || !hash) return false;
    const computed = scryptSync(password, salt, KEY_LEN).toString('hex');
    return computed === hash;
  }
  if (parts.length === 3 && parts[0] === '2') {
    const [, salt, hash] = parts;
    if (!salt || !hash) return false;
    const computed = scryptSync(password, salt, KEY_LEN, SCRYPT_FAST).toString('hex');
    return computed === hash;
  }
  return false;
}

const CODE_CHARS = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // 혼동 가능 문자 제외

export function generateInquiryCode(): string {
  let code = '';
  for (let i = 0; i < 6; i++) {
    code += CODE_CHARS[Math.floor(Math.random() * CODE_CHARS.length)];
  }
  return code;
}
