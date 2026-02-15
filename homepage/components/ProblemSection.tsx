export function ProblemSection() {
  const items = [
    '혼자 사는 부모님이 걱정될 때',
    '연락이 뜸한 배우자가 있을 때',
    '타지에 있는 가족의 안부가 궁금할 때',
  ];

  return (
    <section className="px-6 py-20 md:py-24" style={{ paddingTop: '5rem', paddingBottom: '5rem' }}>
      <div className="mx-auto max-w-3xl">
        <h2 className="mb-12 text-center text-[1.75rem] font-bold leading-[1.4] text-navy-900">
          이런 분들께 필요합니다
        </h2>

        <div className="grid gap-5 sm:grid-cols-3">
          {items.map((text, i) => (
            <div
              key={i}
              className="rounded-[1rem] border border-navy-100 bg-white p-6 shadow-[0_2px_12px_rgba(0,0,0,0.04)]"
            >
              <span className="mb-4 flex h-12 w-12 items-center justify-center rounded-[12px] bg-primary-50 text-lg font-bold text-primary-400">
                {i + 1}
              </span>
              <p className="text-[17px] leading-[1.6] text-navy-700">{text}</p>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
