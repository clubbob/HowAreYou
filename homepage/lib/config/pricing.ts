/** 과금 정책 상수 - 보호자 연 구독 (보호대상자 무제한) */
export const PRICING = {
  yearly: 12000,
} as const;

export function formatPrice(n: number): string {
  return n.toLocaleString('ko-KR') + '원';
}
