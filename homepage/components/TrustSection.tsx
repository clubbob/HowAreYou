export function TrustSection() {
  const items = [
    '위치 추적 없음',
    '통화 기록 접근 없음',
    '최소한의 상태 정보만 공유',
    '사용자가 직접 기록',
  ];

  return (
    <section className="px-6 py-16 md:py-20">
      <div className="mx-auto max-w-3xl">
        <h2 className="mb-10 text-center text-xl font-bold text-gray-900 md:text-2xl">
          우리는 감시 앱이 아닙니다
        </h2>
        <ul className="space-y-3">
          {items.map((text, i) => (
            <li key={i} className="flex items-center gap-3">
              <svg
                className="h-5 w-5 shrink-0 text-primary-500"
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
              >
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
              </svg>
              <span className="text-gray-700">{text}</span>
            </li>
          ))}
        </ul>
      </div>
    </section>
  );
}
