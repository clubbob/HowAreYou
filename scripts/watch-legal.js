/**
 * legal/ 폴더 감시 - 파일 저장 시 자동으로 sync-legal 실행
 * 사용법: node scripts/watch-legal.js (백그라운드 실행)
 */
const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const ROOT = path.join(__dirname, '..');
const LEGAL_DIR = path.join(ROOT, 'legal');

let debounceTimer = null;
const DEBOUNCE_MS = 300;

function runSync() {
  try {
    execSync('node scripts/sync-legal.js', { cwd: ROOT, stdio: 'inherit' });
    console.log('[watch-legal] 앱/웹/설정에 반영 완료');
  } catch (e) {
    console.error('[watch-legal] 동기화 실패');
  }
}

function onChange(eventType, filename) {
  if (!filename || (!filename.endsWith('.txt') && !filename.endsWith('.md'))) return;
  if (debounceTimer) clearTimeout(debounceTimer);
  debounceTimer = setTimeout(() => {
    debounceTimer = null;
    console.log(`[watch-legal] ${filename} 변경 감지 → 동기화 실행`);
    runSync();
  }, DEBOUNCE_MS);
}

try {
  fs.watch(LEGAL_DIR, { recursive: false }, onChange);
  console.log('[watch-legal] legal/ 폴더 감시 중... (저장 시 자동 동기화)');
  runSync(); // 시작 시 1회 실행
} catch (e) {
  console.error('[watch-legal] 시작 실패:', e.message);
  process.exit(1);
}
