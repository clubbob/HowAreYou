const COMPARE_ROWS = [
  { kakao: '먼저 연락해야 합니다', ours: '버튼 한 번이면 충분합니다' },
  { kakao: '답장이 늦으면 괜히 걱정됩니다', ours: '기록이 없으면 자동으로 알려줍니다' },
  { kakao: '대화가 길어지기도 합니다', ours: '3초면 끝납니다' },
  { kakao: '계속 확인하게 됩니다', ours: '부담 없이 이어집니다' },
];

export function KakaoCompareSection() {
  return (
    <section className="bg-white px-4 py-14 sm:px-6 sm:py-16 md:py-24">
      <div className="mx-auto max-w-3xl">
        <h2 className="mb-10 text-center text-[1.375rem] font-bold leading-[1.4] text-navy-900 sm:mb-12 sm:text-[1.75rem]">
          카카오톡으로는 부족할 때가 있습니다
        </h2>

        <div className="mb-10 border-l-4 border-primary-300 bg-primary-50/50 pl-5 py-4 sm:pl-6">
          <p className="text-[15px] leading-[1.7] text-navy-700 sm:text-[16px]">
            먼저 연락하기는 망설여지고,
          </p>
          <p className="mt-1 text-[15px] leading-[1.7] text-navy-700 sm:text-[16px]">
            답장이 없으면 괜히 걱정됩니다.
          </p>
        </div>

        <div className="mb-10 overflow-hidden rounded-2xl border border-navy-100 shadow-[0_2px_16px_rgba(31,42,68,0.06)]">
          <div className="grid grid-cols-2 border-b border-navy-100 bg-navy-50/50">
            <div className="px-5 py-4 text-center sm:px-6 sm:py-5">
              <span className="text-[15px] font-bold text-navy-700 sm:text-[16px]">카카오톡</span>
            </div>
            <div className="border-l border-navy-100 px-5 py-4 text-center sm:px-6 sm:py-5">
              <span className="text-[15px] font-bold text-primary-600 sm:text-[16px]">오늘어때</span>
            </div>
          </div>
          {COMPARE_ROWS.map((row, i) => (
            <div
              key={i}
              className={`grid grid-cols-2 ${i < COMPARE_ROWS.length - 1 ? 'border-b border-navy-100' : ''}`}
            >
              <div className="px-5 py-4 sm:px-6 sm:py-5">
                <p className="text-[14px] leading-[1.6] text-navy-600 sm:text-[15px]">{row.kakao}</p>
              </div>
              <div className="border-l border-navy-100 bg-primary-50/30 px-5 py-4 sm:px-6 sm:py-5">
                <p className="text-[14px] font-medium leading-[1.6] text-navy-800 sm:text-[15px]">{row.ours}</p>
              </div>
            </div>
          ))}
        </div>

        <div className="border-l-4 border-primary-400 bg-primary-50/60 pl-5 py-3 sm:pl-6">
          <p className="text-[15px] font-bold leading-[1.6] text-navy-900 sm:text-[16px]">
            그래서, 안부는 더 간단해야 합니다.
          </p>
        </div>
      </div>
    </section>
  );
}
