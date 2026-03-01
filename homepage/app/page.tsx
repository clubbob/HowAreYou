import { HeroSection } from '@/components/HeroSection';
import { StatsSection } from '@/components/StatsSection';
import { ProblemSection } from '@/components/ProblemSection';
import { KakaoCompareSection } from '@/components/KakaoCompareSection';
import { ServiceSection } from '@/components/ServiceSection';
import { PremiumSection } from '@/components/PremiumSection';
import { FaqSection } from '@/components/FaqSection';
import { AnnouncementsSection } from '@/components/AnnouncementsSection';
import { CtaSection } from '@/components/CtaSection';
import { Footer } from '@/components/Footer';
import { FadeInSection } from '@/components/FadeInSection';
import { ScrollToTopButton } from '@/components/ScrollToTopButton';

export default function HomePage() {
  return (
    <main className="min-h-screen overflow-x-hidden bg-[#F7F8FA]">
      <HeroSection />
      <FadeInSection>
        <StatsSection />
      </FadeInSection>
      <FadeInSection>
        <ProblemSection />
      </FadeInSection>
      <FadeInSection>
        <KakaoCompareSection />
      </FadeInSection>
      <ServiceSection />
      <FadeInSection>
        <PremiumSection />
      </FadeInSection>
      <FadeInSection>
        <FaqSection />
      </FadeInSection>
      <FadeInSection>
        <AnnouncementsSection />
      </FadeInSection>
      <FadeInSection>
        <CtaSection />
      </FadeInSection>
      <Footer />
      <ScrollToTopButton />
    </main>
  );
}
