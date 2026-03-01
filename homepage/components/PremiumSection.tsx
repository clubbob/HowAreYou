'use client';

const COMPARE_ROWS = [
  { feature: '하루 한 번 안부', basic: '✓', premium: '✓', premiumBold: false, featureBold: false },
  { feature: '자동 알림 안내', basic: '✓', premium: '✓', premiumBold: false, featureBold: false },
  { feature: '3일 이상 미기록 알림', basic: '✓', premium: '✓', premiumBold: false, featureBold: false },
  { feature: '보호대상자 등록', basic: '2명까지', premium: '무제한', premiumBold: true, featureBold: true },
  { feature: '위험 신호 조기 감지 알림', basic: '–', premium: '✓', premiumBold: false, featureBold: true },
];

export function PremiumSection() {
  return (
    <section className="bg-white px-4 py-14 sm:px-6 sm:py-16 md:py-24">
      <div className="mx-auto max-w-3xl">
        <h2 className="mb-10 text-center text-[1.375rem] font-bold leading-[1.4] text-navy-900 sm:mb-12 sm:text-[1.75rem]">
          더 안심하고 싶다면
        </h2>

        {/* 감성 설명 1~2줄 */}
        <p className="mb-8 text-center text-[16px] leading-[1.7] text-navy-600 sm:text-[17px]">
          기본 안부 기능만으로도 충분히 이용할 수 있습니다.
          <br />
          더 많은 가족을 함께 관리하려면 프리미엄을 선택할 수 있습니다.
        </p>

        {/* 기능 비교 테이블 */}
        <div className="mb-8 overflow-hidden rounded-2xl border border-navy-100 shadow-[0_2px_16px_rgba(31,42,68,0.06)]">
          <div className="grid grid-cols-3 border-b border-navy-100 bg-navy-50/50">
            <div className="px-4 py-3 sm:px-5 sm:py-4">
              <span className="text-[14px] font-bold text-navy-700 sm:text-[15px]">기능</span>
            </div>
            <div className="border-l border-navy-100 px-4 py-3 text-center sm:px-5 sm:py-4">
              <span className="text-[14px] font-bold text-navy-700 sm:text-[15px]">기본 (무료)</span>
            </div>
            <div className="border-l border-navy-100 px-4 py-3 text-center sm:px-5 sm:py-4">
              <span className="text-[14px] font-bold text-primary-500 sm:text-[15px]">프리미엄</span>
            </div>
          </div>
          {COMPARE_ROWS.map((row, i) => (
            <div
              key={i}
              className={`grid grid-cols-3 ${i < COMPARE_ROWS.length - 1 ? 'border-b border-navy-100' : ''}`}
            >
              <div className="px-4 py-3 sm:px-5 sm:py-4">
                <p className={`text-[14px] leading-[1.5] sm:text-[15px] ${row.featureBold ? 'font-bold text-navy-800' : 'text-navy-600'}`}>{row.feature}</p>
              </div>
              <div className="border-l border-navy-100 px-4 py-3 text-center sm:px-5 sm:py-4">
                <p className="text-[14px] leading-[1.5] text-navy-600 sm:text-[15px]">{row.basic}</p>
              </div>
              <div className="border-l border-navy-100 bg-primary-50/30 px-4 py-3 text-center sm:px-5 sm:py-4">
                <p
                  className={`text-[14px] leading-[1.5] sm:text-[15px] ${
                    row.premium === '✓'
                      ? 'font-semibold text-primary-600'
                      : row.premiumBold
                        ? 'font-bold text-navy-800'
                        : 'font-medium text-navy-800'
                  }`}
                >
                  {row.premium}
                </p>
              </div>
            </div>
          ))}
        </div>

        {/* 가격 */}
        <div className="mb-8 rounded-xl border border-navy-100 bg-navy-50/30 px-5 py-4 text-center sm:px-6 sm:py-5">
          <p className="text-[17px] font-semibold text-navy-800 sm:text-[18px]">
            프리미엄 월 1,500원
          </p>
          <p className="mt-1.5 text-[15px] text-navy-600 sm:text-[16px]">
            연 15,000원 (약 17% 할인)
          </p>
          <p className="mt-3 text-[13px] text-navy-500 sm:text-[14px]">
            보호자만 결제합니다.
            <br />
            보호대상자는 무료입니다.
          </p>
        </div>

        {/* 마무리 문구 */}
        <p className="text-center text-[15px] leading-[1.6] text-navy-600 sm:text-[16px]">
          기본 기능은 무료로 이용할 수 있으며, 프리미엄은 필요할 때 언제든지 선택하실 수 있습니다.
        </p>
      </div>
    </section>
  );
}
