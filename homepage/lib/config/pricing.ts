/** 과금 정책 상수 (PRD v3.0) */
export const PRICING = {
  baseMonthly: 1000,
  baseYearly: 12000,
  extraMonthly: 200,
  extraYearly: 2400,
} as const;

export function formatPrice(n: number): string {
  return n.toLocaleString('ko-KR') + '원';
}
