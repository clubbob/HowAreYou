/** 휴대폰 번호 정규화 (01012345678 형식) - waitlist 저장/조회 일치용 */
export function normalizePhone(input: string): string {
  const digits = input.trim().replace(/\D/g, '');
  if (digits.startsWith('82') && digits.length >= 11) {
    return '0' + digits.substring(2);
  }
  return digits;
}
