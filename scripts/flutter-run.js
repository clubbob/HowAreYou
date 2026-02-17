/**
 * Flutter 실행 - legal 동기화 후 flutter run
 * 사용법: npm run flutter-run [-- flutter run 인자...]
 * 예: npm run flutter-run
 *     npm run flutter-run -- --web
 */
const { execSync } = require('child_process');
const path = require('path');

const root = path.join(__dirname, '..');

// 1. legal → assets 동기화
execSync('node scripts/sync-legal.js', { cwd: root, stdio: 'inherit' });

// 2. flutter run (인자 전달: npm run flutter-run -- --web 등)
const args = process.argv.slice(2);
const flutterArgs = args.length ? `run ${args.join(' ')}` : 'run';
execSync(`flutter ${flutterArgs}`, { cwd: root, stdio: 'inherit' });
