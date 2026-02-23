export function StatsSection() {
  const items = [
    { value: '350만', label: '혼자 사는 노인' },
    { value: '700만+', label: '1인 가구' },
    { value: '수십만', label: '자취·기숙 학생' },
  ];

  return (
    <section className="bg-white px-4 py-12 sm:px-6 sm:py-14 md:py-20">
      <div className="mx-auto max-w-4xl">
        <p className="mb-10 text-center text-[1rem] font-medium text-navy-600 sm:mb-12 sm:text-[1.0625rem] md:text-[1.125rem]">
          우리는 점점 혼자 살고 있습니다.
        </p>

        <div className="grid grid-cols-1 gap-6 sm:gap-8 md:grid-cols-3 md:gap-6">
          {items.map((item, i) => (
            <div
              key={i}
              className="rounded-2xl border border-navy-100/80 bg-gradient-to-b from-navy-50/40 to-white px-6 py-5 text-center"
            >
              <p className="text-[1.25rem] font-semibold text-navy-800 sm:text-[1.375rem]">
                {item.value}
              </p>
              <p className="mt-1.5 text-[15px] font-medium text-navy-600">{item.label}</p>
            </div>
          ))}
        </div>

        <p className="mt-10 text-center text-[1.0625rem] leading-[1.7] text-navy-700 sm:mt-12 sm:text-[1.125rem] md:text-[1.1875rem]">
          우리는 점점 따로 살고 있습니다.
          <br className="sm:hidden" />
          <span className="sm:ml-1">그래서 안부를 전하는 방식도 달라져야 합니다.</span>
        </p>

        <p className="mt-4 text-center text-[12px] text-navy-400">
          출처: 통계청 인구총조사, 2020년
        </p>
      </div>
    </section>
  );
}
