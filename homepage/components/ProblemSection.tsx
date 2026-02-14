export function ProblemSection() {
  const items = [
    '혼자 사는 가족과 연락이 며칠 끊긴 경우',
    '갑작스러운 사고',
    '평소에는 괜찮지만, 혹시 모를 상황',
  ];

  return (
    <section className="px-6 py-16 md:py-20">
      <div className="mx-auto max-w-3xl">
        <h2 className="mb-10 text-center text-xl font-bold text-gray-900 md:text-2xl">
          이런 상황이 걱정되시나요?
        </h2>
        <ul className="space-y-4">
          {items.map((text, i) => (
            <li
              key={i}
              className="flex items-start gap-3 rounded-xl border border-gray-200 bg-white p-4 shadow-sm"
            >
              <span className="flex h-8 w-8 shrink-0 items-center justify-center rounded-full bg-primary-100 text-sm font-bold text-primary-600">
                {i + 1}
              </span>
              <span className="pt-0.5 text-gray-700">{text}</span>
            </li>
          ))}
        </ul>
      </div>
    </section>
  );
}
