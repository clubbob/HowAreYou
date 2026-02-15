import { HeroSection } from '@/components/HeroSection';
import { ProblemSection } from '@/components/ProblemSection';
import { ServiceSection } from '@/components/ServiceSection';
import { TrustSection } from '@/components/TrustSection';
import { FaqSection } from '@/components/FaqSection';
import { AnnouncementsSection } from '@/components/AnnouncementsSection';
import { CtaSection } from '@/components/CtaSection';
import { Footer } from '@/components/Footer';

export default function HomePage() {
  return (
    <main className="min-h-screen bg-[#F7F8FA]">
      <HeroSection />
      <ProblemSection />
      <ServiceSection />
      <TrustSection />
      <FaqSection />
      <AnnouncementsSection />
      <CtaSection />
      <Footer />
    </main>
  );
}
