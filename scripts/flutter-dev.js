/**
 * Flutter 개발 실행 - legal 동기화 + legal 감시(자동) + flutter run
 * 사용법: npm run flutter-dev
 */
const { execSync, spawn } = require('child_process');
const path = require('path');

const root = path.join(__dirname, '..');

// 1. 동기화
execSync('node scripts/sync-legal.js', { cwd: root, stdio: 'inherit' });

// 2. legal 감시 (백그라운드)
spawn('node', ['scripts/watch-legal.js'], {
  cwd: root,
  stdio: 'ignore',
  detached: true,
}).unref();

// 3. flutter run
execSync('flutter run', { cwd: root, stdio: 'inherit' });
