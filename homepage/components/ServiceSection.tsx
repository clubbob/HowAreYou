export function ServiceSection() {
  const steps = [
    { num: 1, title: '하루 한 번 상태 기록' },
    { num: 2, title: '최근 7일 기록 공유' },
    { num: 3, title: '3일 무응답 시 보호자에게 알림 1회 발송' },
  ];

  return (
    <section className="bg-primary-50 px-6 py-16 md:py-20">
      <div className="mx-auto max-w-3xl">
        <h2 className="mb-10 text-center text-xl font-bold text-gray-900 md:text-2xl">
          지금 어때는 이렇게 작동합니다
        </h2>
        <div className="space-y-4">
          {steps.map((s) => (
            <div
              key={s.num}
              className="flex items-center gap-4 rounded-xl bg-white p-4 shadow-sm"
            >
              <span className="flex h-10 w-10 shrink-0 items-center justify-center rounded-full bg-primary-500 text-lg font-bold text-white">
                {s.num}
              </span>
              <span className="text-gray-800">{s.title}</span>
            </div>
          ))}
        </div>
        <p className="mt-8 text-center text-sm text-gray-600">
          감시하지 않습니다 · 평가하지 않습니다 · 일상 확인만을 위한 구조입니다
        </p>
      </div>
    </section>
  );
}
