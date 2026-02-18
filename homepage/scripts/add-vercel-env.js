/**
 * Vercel에 FIREBASE_SERVICE_ACCOUNT_JSON, ADMIN_USERNAME, ADMIN_PASSWORD 추가
 *
 * 사용법:
 * 1. https://vercel.com/account/tokens 에서 토큰 생성
 * 2. VERCEL_TOKEN=xxx node scripts/add-vercel-env.js
 *    또는 (Windows PowerShell) $env:VERCEL_TOKEN="xxx"; node scripts/add-vercel-env.js
 */

const fs = require('fs');
const path = require('path');

const PROJECT_ROOT = path.resolve(__dirname, '..');
const PROJECT_NAME = 'how-are-you'; // Vercel 프로젝트 이름
const API = 'https://api.vercel.com/v10/projects';

async function addEnv(token, key, value, target = ['production', 'preview', 'development']) {
  const res = await fetch(`${API}/${encodeURIComponent(PROJECT_NAME)}/env?upsert=true`, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${token}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      key,
      value,
      type: key.includes('PASSWORD') || key.includes('JSON') ? 'secret' : 'plain',
      target,
    }),
  });

  if (!res.ok) {
    const err = await res.text();
    throw new Error(`API 오류 (${res.status}): ${err}`);
  }
  return res.json();
}

async function main() {
  const token = process.env.VERCEL_TOKEN;
  if (!token) {
    console.error('VERCEL_TOKEN 환경 변수를 설정하세요.');
    console.error('https://vercel.com/account/tokens 에서 토큰을 생성한 뒤:');
    console.error('  PowerShell: $env:VERCEL_TOKEN="발급받은토큰"; node scripts/add-vercel-env.js');
    console.error('  CMD: set VERCEL_TOKEN=발급받은토큰 && node scripts/add-vercel-env.js');
    process.exit(1);
  }

  const jsonPath = path.join(PROJECT_ROOT, 'vercel-firebase-json.txt');
  if (!fs.existsSync(jsonPath)) {
    console.error('vercel-firebase-json.txt 파일을 찾을 수 없습니다.');
    process.exit(1);
  }

  const firebaseJson = fs.readFileSync(jsonPath, 'utf8').trim();

  // .env.local에서 관리자 정보 읽기 (없으면 환경 변수 사용)
  let adminUsername = process.env.ADMIN_USERNAME;
  let adminPassword = process.env.ADMIN_PASSWORD || process.env.ADMIN_PASS;
  const envPath = path.join(PROJECT_ROOT, '.env.local');
  if (fs.existsSync(envPath)) {
    const env = fs.readFileSync(envPath, 'utf8');
    const m1 = env.match(/ADMIN_USERNAME=(.+)/);
    const m2 = env.match(/ADMIN_PASSWORD="?(.+?)"?\s*$/m);
    if (m1) adminUsername = adminUsername || m1[1].trim();
    if (m2) adminPassword = adminPassword || m2[1].replace(/^"|"$/g, '').trim();
  }
  adminUsername = adminUsername || 'clubbob';

  if (!adminPassword) {
    console.error('ADMIN_PASSWORD를 .env.local에 설정했거나 환경 변수로 전달하세요.');
    process.exit(1);
  }

  console.log('Vercel 환경 변수 추가 중...\n');

  try {
    await addEnv(token, 'FIREBASE_SERVICE_ACCOUNT_JSON', firebaseJson);
    console.log('✓ FIREBASE_SERVICE_ACCOUNT_JSON');
  } catch (e) {
    console.error('✗ FIREBASE_SERVICE_ACCOUNT_JSON:', e.message);
  }

  try {
    await addEnv(token, 'ADMIN_USERNAME', adminUsername);
    console.log('✓ ADMIN_USERNAME');
  } catch (e) {
    console.error('✗ ADMIN_USERNAME:', e.message);
  }

  try {
    await addEnv(token, 'ADMIN_PASSWORD', adminPassword);
    console.log('✓ ADMIN_PASSWORD');
  } catch (e) {
    console.error('✗ ADMIN_PASSWORD:', e.message);
  }

  console.log('\n완료. Vercel 대시보드에서 Redeploy 해주세요.');
}

main();
