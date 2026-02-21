export type WaitlistResult =
  | { status: 'success' }
  | { status: 'already_registered' }
  | { status: 'full' };

/**
 * 베타 대기 등록 - Next.js API 사용 (휴대폰 번호로 문자 안내)
 */
export async function addToWaitlist(phone: string): Promise<WaitlistResult> {
  let res: Response;
  try {
    res = await fetch('/api/waitlist', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ phone: phone.trim() }),
    });
  } catch (e) {
    if (e instanceof TypeError && (e.message?.includes('fetch') || e.message?.includes('Failed to fetch'))) {
      throw new Error('네트워크 연결을 확인한 후 다시 시도해 주세요.');
    }
    throw new Error('등록에 실패했습니다. 잠시 후 다시 시도해 주세요.');
  }

  const data = await res.json().catch(() => ({}));

  if (res.ok && (data.status === 'success' || data.status === 'already_registered' || data.status === 'full')) {
    return data as WaitlistResult;
  }

  if (res.status === 400 || res.status === 500) {
    throw new Error(data.error || '등록에 실패했습니다. 잠시 후 다시 시도해 주세요.');
  }

  throw new Error('등록에 실패했습니다. 잠시 후 다시 시도해 주세요.');
}
