export type WaitlistResult =
  | { status: 'success' }
  | { status: 'already_registered' }
  | { status: 'full' };

/**
 * 베타 대기 등록 - Next.js API 사용 (연락처 포함 저장, Cloud Function 배포 불필요)
 */
export async function addToWaitlist(email: string, phone?: string): Promise<WaitlistResult> {
  const res = await fetch('/api/waitlist', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      email: email.trim(),
      phone: phone?.trim() || undefined,
    }),
  });

  const data = await res.json().catch(() => ({}));

  if (res.ok && (data.status === 'success' || data.status === 'already_registered' || data.status === 'full')) {
    return data as WaitlistResult;
  }

  if (res.status === 400 || res.status === 500) {
    throw new Error(data.error || '등록에 실패했습니다. 다시 시도해 주세요.');
  }

  throw new Error('등록에 실패했습니다. 다시 시도해 주세요.');
}
