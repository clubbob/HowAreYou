export function TrustSection() {
  const items = [
    '위치 추적 없음',
    '통화 기록 접근 없음',
    '최소한의 상태 정보만 공유',
    '사용자가 직접 기록',
  ];

  return (
    <section className="relative px-6 py-20 md:py-28">
      <div className="mx-auto max-w-2xl">
        <h2 className="mb-12 text-center text-2xl font-bold tracking-tight text-primary-900 md:text-3xl">
          우리는 감시 앱이 아닙니다
        </h2>

        <ul className="space-y-5">
          {items.map((text, i) => (
            <li key={i} className="flex items-center gap-4">
              <span className="flex h-10 w-10 shrink-0 items-center justify-center rounded-full bg-primary-100">
                <svg
                  className="h-5 w-5 text-primary-600"
                  fill="none"
                  stroke="currentColor"
                  strokeWidth={2.5}
                  viewBox="0 0 24 24"
                >
                  <path strokeLinecap="round" strokeLinejoin="round" d="M5 13l4 4L19 7" />
                </svg>
              </span>
              <span className="text-base font-medium text-primary-800 md:text-lg">{text}</span>
            </li>
          ))}
        </ul>
      </div>
    </section>
  );
}
