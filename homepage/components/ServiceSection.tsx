export function ServiceSection() {
  const steps = [
    { num: 1, title: '하루 한 번 간단히 기록' },
    { num: 2, title: '보호자에게 알림 전달' },
    { num: 3, title: '3일 무응답 시 1회 추가 알림' },
  ];

  return (
    <section className="bg-primary-50/50 px-6 py-20 md:py-24" style={{ paddingTop: '5rem', paddingBottom: '5rem' }}>
      <div className="mx-auto max-w-3xl">
        <h2 className="mb-12 text-center text-[1.75rem] font-bold leading-[1.4] text-navy-900">
          어떻게 작동하나요?
        </h2>

        <div className="space-y-5">
          {steps.map((s) => (
            <div
              key={s.num}
              className="flex items-center gap-6 rounded-[1rem] border border-primary-100 bg-white p-6 shadow-[0_2px_12px_rgba(0,0,0,0.04)]"
            >
              <span className="flex h-14 w-14 shrink-0 items-center justify-center rounded-[14px] bg-primary-400 text-xl font-bold text-white">
                {s.num}
              </span>
              <span className="text-[18px] font-medium text-navy-800">{s.title}</span>
            </div>
          ))}
        </div>

        <p className="mt-10 text-center text-sm leading-relaxed text-navy-600">
          ※ 본 서비스는 의료·응급 구조 서비스가 아닙니다.
          <br />
          통신 환경 및 기기 설정에 따라 알림이 지연되거나 수신되지 않을 수 있습니다.
        </p>
      </div>
    </section>
  );
}
