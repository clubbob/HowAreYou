/**
 * Firebase Admin 서비스 계정 JSON을 .env.local에 추가하는 스크립트
 *
 * 사용법:
 * 1. Firebase Console → 프로젝트 설정 → 서비스 계정 → "새 비공개 키 생성" 클릭
 * 2. 다운로드된 JSON 파일을 homepage/service-account.json 으로 저장
 * 3. node scripts/setup-firebase-admin.js 실행
 * 4. 완료 후 service-account.json 삭제 (보안)
 */

const fs = require('fs');
const path = require('path');

const PROJECT_ROOT = path.resolve(__dirname, '..');
const SERVICE_ACCOUNT_PATH = path.join(PROJECT_ROOT, 'service-account.json');
const ENV_LOCAL_PATH = path.join(PROJECT_ROOT, '.env.local');

function main() {
  if (!fs.existsSync(SERVICE_ACCOUNT_PATH)) {
    console.error('service-account.json 파일을 찾을 수 없습니다.');
    console.error('');
    console.error('다음 단계를 따르세요:');
    console.error('1. https://console.firebase.google.com 접속');
    console.error('2. howareyou-1c5de 프로젝트 선택');
    console.error('3. 프로젝트 설정(톱니바퀴) → 서비스 계정 탭');
    console.error('4. "새 비공개 키 생성" 클릭 후 JSON 다운로드');
    console.error(`5. 다운로드한 파일을 ${path.relative(PROJECT_ROOT, SERVICE_ACCOUNT_PATH)} 로 저장`);
    console.error(`6. node scripts/setup-firebase-admin.js 다시 실행`);
    process.exit(1);
  }

  const json = fs.readFileSync(SERVICE_ACCOUNT_PATH, 'utf8');
  const parsed = JSON.parse(json);

  if (!parsed.type || parsed.type !== 'service_account') {
    console.error('유효한 Firebase 서비스 계정 JSON이 아닙니다.');
    process.exit(1);
  }

  const oneLiner = JSON.stringify(JSON.parse(json));
  const envLine = `FIREBASE_SERVICE_ACCOUNT_JSON=${oneLiner}`;

  let envContent = '';
  if (fs.existsSync(ENV_LOCAL_PATH)) {
    envContent = fs.readFileSync(ENV_LOCAL_PATH, 'utf8');
    if (envContent.includes('FIREBASE_SERVICE_ACCOUNT_JSON=')) {
      envContent = envContent.replace(
        /FIREBASE_SERVICE_ACCOUNT_JSON=.*/,
        envLine
      );
      console.log('기존 FIREBASE_SERVICE_ACCOUNT_JSON 값을 업데이트했습니다.');
    } else {
      envContent = envContent.trimEnd() + '\n\n# Firebase Admin SDK\n' + envLine + '\n';
      console.log('FIREBASE_SERVICE_ACCOUNT_JSON을 .env.local에 추가했습니다.');
    }
  } else {
    envContent = '# Firebase Admin SDK\n' + envLine + '\n';
    console.log('.env.local을 생성하고 FIREBASE_SERVICE_ACCOUNT_JSON을 추가했습니다.');
  }

  fs.writeFileSync(ENV_LOCAL_PATH, envContent);

  console.log('');
  console.log('완료! 이제 service-account.json 파일을 삭제하세요 (보안):');
  console.log(`  del ${path.relative(PROJECT_ROOT, SERVICE_ACCOUNT_PATH)}`);
  console.log('');
}

main();
