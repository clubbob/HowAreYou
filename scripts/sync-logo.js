/**
 * 앱 아이콘(원형)을 홈페이지 로고로 복사
 */
const fs = require('fs');
const path = require('path');

const ROOT = path.join(__dirname, '..');
const src = path.join(ROOT, 'assets', 'icon', 'icon.png');
const dest = path.join(ROOT, 'homepage', 'public', 'logo.png');

if (!fs.existsSync(src)) {
  console.error('[sync-logo] assets/icon/icon.png 를 찾을 수 없습니다.');
  process.exit(1);
}

fs.copyFileSync(src, dest);
console.log('[sync-logo] homepage/public/logo.png 업데이트 완료');
