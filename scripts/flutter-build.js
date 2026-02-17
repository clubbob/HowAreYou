/**
 * Flutter 빌드 전 이용약관·개인정보처리방침 동기화 후 빌드 실행
 * 사용법: node scripts/flutter-build.js [flutter build 인자...]
 * 예: node scripts/flutter-build.js apk
 *     node scripts/flutter-build.js ios
 */
const { execSync } = require('child_process');
const path = require('path');

const root = path.join(__dirname, '..');

execSync('node scripts/sync-legal.js', { cwd: root, stdio: 'inherit' });
const args = process.argv.slice(2).length ? process.argv.slice(2).join(' ') : 'build apk';
execSync(`flutter ${args}`, {
  cwd: root,
  stdio: 'inherit',
});
