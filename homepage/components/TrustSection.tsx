export function TrustSection() {
  const items = [
    '위치 추적하지 않습니다.',
    '감시하지 않습니다.',
    '평가하거나 점수화하지 않습니다.',
  ];

  return (
    <section className="bg-primary-50 px-6 py-20 md:py-24" style={{ paddingTop: '5rem', paddingBottom: '5rem' }}>
      <div className="mx-auto max-w-3xl">
        <h2 className="mb-12 text-center text-[1.75rem] font-bold leading-[1.4] text-navy-900">
          우리가 하지 않는 것
        </h2>

        <ul className="space-y-6">
          {items.map((text, i) => (
            <li key={i} className="flex items-center gap-5">
              <span className="flex h-12 w-12 shrink-0 items-center justify-center rounded-full bg-white shadow-[0_2px_8px_rgba(0,0,0,0.06)]">
                <svg className="h-6 w-6 text-primary-400" fill="none" stroke="currentColor" strokeWidth={2.5} viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" d="M5 13l4 4L19 7" />
                </svg>
              </span>
              <span className="text-[18px] font-medium text-navy-800">{text}</span>
            </li>
          ))}
        </ul>
      </div>
    </section>
  );
}
