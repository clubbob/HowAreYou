import { HeroSection } from '@/components/HeroSection';
import { ProblemSection } from '@/components/ProblemSection';
import { ServiceSection } from '@/components/ServiceSection';
import { PricingSection } from '@/components/PricingSection';
import { RecommendSection } from '@/components/RecommendSection';
import { TrustSection } from '@/components/TrustSection';
import { FaqSection } from '@/components/FaqSection';
import { AnnouncementsSection } from '@/components/AnnouncementsSection';
import { CtaSection } from '@/components/CtaSection';
import { Footer } from '@/components/Footer';
import { FadeInSection } from '@/components/FadeInSection';

export default function HomePage() {
  return (
    <main className="min-h-screen bg-[#F7F8FA]">
      <HeroSection />
      <FadeInSection>
        <ProblemSection />
      </FadeInSection>
      <ServiceSection />
      <FadeInSection>
        <PricingSection />
      </FadeInSection>
      <FadeInSection>
        <RecommendSection />
      </FadeInSection>
      <FadeInSection>
        <TrustSection />
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
    </main>
  );
}
