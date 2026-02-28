/**
 * E.164 형식으로 통일 (+821012345678)
 * 앱 Firebase Auth, waitlist 저장/조회 모두 E.164 사용 → 문자열 비교로 안전하게 매칭
 */

/** 입력을 E.164 형식으로 변환 (한국 휴대폰: +821012345678) */
export function toE164(input: string): string {
  const digits = input.trim().replace(/\D/g, '');
  if (digits.length < 10) return '';
  // 01012345678 → +821012345678
  if (digits.startsWith('0') && digits.length >= 10) {
    return '+82' + digits.substring(1);
  }
  // 821012345678 → +821012345678
  if (digits.startsWith('82') && digits.length >= 11) {
    return '+' + digits;
  }
  // 1012345678 (10자리) → +821012345678
  if (digits.length === 10 && digits.startsWith('10')) {
    return '+82' + digits;
  }
  return digits ? '+' + digits : '';
}

/**
 * @deprecated E.164 사용 권장. 하위 호환용 유지
 * 휴대폰 번호 정규화 (01012345678 형식)
 */
export function normalizePhone(input: string): string {
  const e164 = toE164(input);
  if (!e164) return input.trim().replace(/\D/g, '');
  // +821012345678 → 01012345678
  return '0' + e164.substring(3);
}
