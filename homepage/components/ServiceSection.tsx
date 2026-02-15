export function ServiceSection() {
  const steps = [
    { num: 1, title: '하루 한 번 상태 기록' },
    { num: 2, title: '최근 7일 기록 공유' },
    { num: 3, title: '3일 무응답 시 보호자에게 알림 1회 발송' },
  ];

  return (
    <section className="relative bg-primary-50/50 px-6 py-20 md:py-28">
      <div className="mx-auto max-w-2xl">
        <h2 className="mb-12 text-center text-2xl font-bold tracking-tight text-primary-900 md:text-3xl">
          지금 어때는 이렇게 작동합니다
        </h2>

        <div className="space-y-4">
          {steps.map((s) => (
            <div
              key={s.num}
              className="flex items-center gap-5 rounded-2xl bg-white/90 px-6 py-5 shadow-soft backdrop-blur-sm transition-all duration-200 hover:shadow-card"
            >
              <span className="flex h-12 w-12 shrink-0 items-center justify-center rounded-xl bg-primary-600 text-lg font-bold text-white shadow-soft">
                {s.num}
              </span>
              <span className="text-base font-medium text-primary-800 md:text-lg">
                {s.title}
              </span>
            </div>
          ))}
        </div>

        <p className="mt-10 text-center text-sm font-medium text-primary-700/80">
          감시하지 않습니다 · 평가하지 않습니다 · 일상 확인만을 위한 구조입니다
        </p>
      </div>
    </section>
  );
}
