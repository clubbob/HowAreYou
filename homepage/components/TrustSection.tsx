const ITEMS = [
  {
    text: '위치 추적하지 않습니다.',
    icon: (
      <svg className="h-6 w-6" fill="none" stroke="currentColor" strokeWidth={2} viewBox="0 0 24 24">
        <path strokeLinecap="round" strokeLinejoin="round" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z" />
        <path strokeLinecap="round" strokeLinejoin="round" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z" />
        <line x1="3" y1="3" x2="21" y2="21" strokeLinecap="round" strokeWidth={2.5} />
      </svg>
    ),
  },
  {
    text: '감시하지 않습니다.',
    icon: (
      <svg className="h-6 w-6" fill="none" stroke="currentColor" strokeWidth={2} viewBox="0 0 24 24">
        <path strokeLinecap="round" strokeLinejoin="round" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
        <path strokeLinecap="round" strokeLinejoin="round" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
        <line x1="3" y1="3" x2="21" y2="21" strokeLinecap="round" strokeWidth={2.5} />
      </svg>
    ),
  },
  {
    text: '평가하거나 점수화하지 않습니다.',
    icon: (
      <svg className="h-6 w-6" fill="none" stroke="currentColor" strokeWidth={2} viewBox="0 0 24 24">
        <path strokeLinecap="round" strokeLinejoin="round" d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z" />
        <line x1="3" y1="3" x2="21" y2="21" strokeLinecap="round" strokeWidth={2.5} />
      </svg>
    ),
  },
];

export function TrustSection() {
  return (
    <section className="bg-navy-50 px-4 py-14 sm:px-6 sm:py-16 md:py-24">
      <div className="mx-auto max-w-4xl">
        <h2 className="mb-4 text-center text-[1.375rem] font-bold leading-[1.4] text-navy-900 sm:text-[1.75rem]">
          우리가 하지 않는 것
        </h2>
        <p className="mb-12 text-center text-[17px] text-navy-600">
          프라이버시를 지키기 위한 우리의 약속입니다.
        </p>

        <div className="grid gap-6 sm:grid-cols-3">
          {ITEMS.map((item, i) => (
            <div
              key={i}
              className="group relative overflow-hidden rounded-2xl border border-navy-100 bg-white p-6 shadow-[0_2px_16px_rgba(31,42,68,0.06)] transition-all duration-300 hover:shadow-[0_8px_28px_rgba(31,42,68,0.1)]"
            >
              <div className="absolute right-0 top-0 h-20 w-20 translate-x-4 -translate-y-4 rounded-full bg-navy-100/40 blur-xl" />
              <div className="relative flex items-start gap-4">
                <span className="flex h-14 w-14 shrink-0 items-center justify-center rounded-2xl bg-navy-100 text-navy-500 transition-colors group-hover:bg-navy-200/80 group-hover:text-navy-600">
                  {item.icon}
                </span>
                <p className="pt-1 text-[17px] font-medium leading-[1.6] text-navy-800">{item.text}</p>
              </div>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
