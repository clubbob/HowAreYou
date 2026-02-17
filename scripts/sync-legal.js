/**
 * 이용약관·개인정보처리방침 동기화
 * legal/, homepage, Flutter assets 간 내용을 일치시킵니다.
 *
 * 사용법:
 *   node scripts/sync-legal.js              # legal/ → 웹, 앱 (legal이 소스)
 *   node scripts/sync-legal.js from-assets  # assets/ → legal → 웹 (Flutter에서 수정했을 때)
 *   node scripts/sync-legal.js from-web     # 웹 legal-content.ts → legal → 앱 (웹에서 수정했을 때)
 */

const fs = require('fs');
const path = require('path');

const ROOT = path.join(__dirname, '..');
const LEGAL_DIR = path.join(ROOT, 'legal');
const TERMS_SRC = path.join(LEGAL_DIR, 'terms.txt');
const PRIVACY_SRC = path.join(LEGAL_DIR, 'privacy.txt');
const WEB_OUTPUT = path.join(ROOT, 'homepage', 'lib', 'legal-content.ts');
const ASSETS_TERMS = path.join(ROOT, 'assets', 'terms_content.txt');
const ASSETS_PRIVACY = path.join(ROOT, 'assets', 'privacy_content.txt');

function readFile(p) {
  try {
    return fs.readFileSync(p, 'utf8').trimEnd();
  } catch (e) {
    return null;
  }
}

function writeFile(p, content) {
  fs.mkdirSync(path.dirname(p), { recursive: true });
  fs.writeFileSync(p, content, 'utf8');
}

function syncFromLegal(terms, privacy) {
  const tsContent = `// 이용약관 및 개인정보처리방침 - legal/ 폴더에서 자동 생성 (npm run sync-legal)
// 이 파일을 직접 수정하지 마세요. legal/terms.txt, legal/privacy.txt를 수정한 뒤 sync-legal을 실행하세요.

export const TERMS_CONTENT = \`${terms.replace(/`/g, '\\`')}\`;

export const PRIVACY_CONTENT = \`${privacy.replace(/`/g, '\\`')}\`;
`;

  writeFile(WEB_OUTPUT, tsContent);
  writeFile(ASSETS_TERMS, terms);
  writeFile(ASSETS_PRIVACY, privacy);
  console.log('[sync-legal] legal/ → homepage, assets 반영 완료');
}

function extractFromWeb() {
  const content = readFile(WEB_OUTPUT);
  if (!content) {
    console.error('[sync-legal] homepage/lib/legal-content.ts를 찾을 수 없습니다.');
    process.exit(1);
  }
  const termsMatch = content.match(/TERMS_CONTENT\s*=\s*`([\s\S]*?)`;/);
  const privacyMatch = content.match(/PRIVACY_CONTENT\s*=\s*`([\s\S]*?)`;/);
  if (!termsMatch || !privacyMatch) {
    console.error('[sync-legal] legal-content.ts 형식을 파싱할 수 없습니다.');
    process.exit(1);
  }
  return {
    terms: termsMatch[1].replace(/\\`/g, '`'),
    privacy: privacyMatch[1].replace(/\\`/g, '`'),
  };
}

const mode = process.argv[2] || 'from-legal';

if (mode === 'from-assets') {
  const terms = readFile(ASSETS_TERMS);
  const privacy = readFile(ASSETS_PRIVACY);
  if (!terms || !privacy) {
    console.error('[sync-legal] assets/terms_content.txt 또는 privacy_content.txt를 찾을 수 없습니다.');
    process.exit(1);
  }
  writeFile(TERMS_SRC, terms);
  writeFile(PRIVACY_SRC, privacy);
  console.log('[sync-legal] assets/ → legal/ 반영 완료');
  syncFromLegal(terms, privacy);
} else if (mode === 'from-web') {
  const { terms, privacy } = extractFromWeb();
  writeFile(TERMS_SRC, terms);
  writeFile(PRIVACY_SRC, privacy);
  console.log('[sync-legal] homepage → legal/ 반영 완료');
  syncFromLegal(terms, privacy);
} else {
  const terms = readFile(TERMS_SRC);
  const privacy = readFile(PRIVACY_SRC);
  if (!terms || !privacy) {
    console.error('[sync-legal] legal/terms.txt 또는 legal/privacy.txt를 찾을 수 없습니다.');
    process.exit(1);
  }
  syncFromLegal(terms, privacy);
}
