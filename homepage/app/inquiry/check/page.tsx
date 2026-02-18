'use client';

import { useEffect } from 'react';
import { useRouter } from 'next/navigation';

export default function InquiryCheckRedirectPage() {
  const router = useRouter();

  useEffect(() => {
    router.replace('/inquiry?tab=check');
  }, [router]);

  return (
    <div className="flex min-h-[200px] items-center justify-center text-navy-600">
      이동 중...
    </div>
  );
}
