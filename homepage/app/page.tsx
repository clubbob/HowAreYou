import { HeroSection } from '@/components/HeroSection';
import { ProblemSection } from '@/components/ProblemSection';
import { ServiceSection } from '@/components/ServiceSection';
import { TrustSection } from '@/components/TrustSection';
import { AnnouncementsSection } from '@/components/AnnouncementsSection';
import { CtaSection } from '@/components/CtaSection';
import { Footer } from '@/components/Footer';

export default function HomePage() {
  return (
    <main className="min-h-screen">
      <HeroSection />
      <ProblemSection />
      <ServiceSection />
      <TrustSection />
      <AnnouncementsSection />
      <CtaSection />
      <Footer />
    </main>
  );
}
