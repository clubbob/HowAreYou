export function ProblemSection() {
  const items = [
    ['혼자 사는 부모님이', '걱정될 때'],
    ['내가 혼자 사는데', '연락할 보호자가 필요할 때'],
    ['타지에 있는 가족 또는 지인의', '안부가 궁금할 때'],
  ];

  return (
    <section className="bg-white px-6 py-20 md:py-24" style={{ paddingTop: '5rem', paddingBottom: '5rem' }}>
      <div className="mx-auto max-w-4xl">
        <h2 className="mb-14 text-center text-[1.75rem] font-bold leading-[1.4] text-navy-900">
          이런 분들께 필요합니다
        </h2>

        <div className="grid gap-6 sm:grid-cols-3">
          {items.map((lines, i) => (
            <div
              key={i}
              data-mobile-hover-card
              className="group relative overflow-hidden rounded-2xl border border-navy-100/80 border-l-4 border-l-transparent bg-gradient-to-b from-white to-navy-50/30 p-7 shadow-[0_2px_16px_rgba(31,42,68,0.06)] transition-all duration-300 hover:border-primary-200/60 hover:border-l-primary-500 hover:shadow-[0_8px_32px_rgba(74,144,226,0.12)] active:scale-[0.99]"
            >
              <div
                data-mobile-hover-blur
                className="absolute right-0 top-0 h-24 w-24 translate-x-4 -translate-y-4 rounded-full bg-primary-50/50 blur-2xl transition-opacity group-hover:opacity-80"
              />
              <div className="relative">
                <span className="mb-4 inline-flex h-9 w-9 items-center justify-center rounded-lg bg-primary-500 text-sm font-bold text-white shadow-sm">
                  {i + 1}
                </span>
                <p className="text-[17px] font-medium leading-[1.6] text-navy-800">
                  {lines[0]}
                  <br />
                  {lines[1]}
                </p>
              </div>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
