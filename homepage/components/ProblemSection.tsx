export function ProblemSection() {
  const items = [
    '혼자 사는 가족과 연락이 며칠 끊긴 경우',
    '갑작스러운 사고',
    '평소에는 괜찮지만, 혹시 모를 상황',
  ];

  return (
    <section className="relative px-6 py-20 md:py-28">
      <div className="mx-auto max-w-2xl">
        <h2 className="mb-12 text-center text-2xl font-bold tracking-tight text-primary-900 md:text-3xl">
          이런 상황이 걱정되시나요?
        </h2>

        <ul className="space-y-4">
          {items.map((text, i) => (
            <li
              key={i}
              className="group flex items-start gap-4 rounded-2xl border border-primary-100/80 bg-white p-5 shadow-soft transition-all duration-200 hover:border-primary-200/60 hover:shadow-card"
            >
              <span className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-primary-100 text-sm font-bold text-primary-700">
                {i + 1}
              </span>
              <span className="pt-1.5 text-base leading-relaxed text-primary-800/90">
                {text}
              </span>
            </li>
          ))}
        </ul>
      </div>
    </section>
  );
}
