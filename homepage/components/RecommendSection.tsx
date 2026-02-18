const ITEMS = [
  '부모님과 떨어져 지내는 분',
  '매일 전화는 어렵지만 안부는 확인하고 싶은 분',
  '조용하게 서로의 안심을 확인하고 싶은 가족',
];

export function RecommendSection() {
  return (
    <section
      className="bg-primary-50 px-6 py-20 md:py-24"
      style={{ paddingTop: '5rem', paddingBottom: '5rem' }}
    >
      <div className="mx-auto max-w-2xl">
        <h2 className="mb-10 text-center text-[1.75rem] font-bold leading-[1.4] text-navy-900">
          이런 분들께 추천합니다
        </h2>
        <ul className="space-y-4">
          {ITEMS.map((item, i) => (
            <li
              key={i}
              className="flex items-center gap-3 rounded-xl border border-primary-100 bg-white px-5 py-4 text-[17px] text-navy-800 shadow-[0_2px_12px_rgba(0,0,0,0.04)]"
            >
              <span className="flex h-8 w-8 shrink-0 items-center justify-center rounded-full bg-primary-100 text-primary-600">
                ✓
              </span>
              {item}
            </li>
          ))}
        </ul>
      </div>
    </section>
  );
}
