const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

const rootDir = path.join(__dirname, '..');
const projectRoot = path.join(rootDir, '..');

// 0. 이용약관·개인정보처리방침 동기화 (legal/ → assets/, legal-content.ts)
try {
  execSync('node scripts/sync-legal.js', { cwd: projectRoot, stdio: 'pipe' });
  // legal/ 감시 (저장 시 자동 동기화) - 백그라운드 실행
  require('child_process').spawn('node', ['scripts/watch-legal.js'], {
    cwd: projectRoot,
    stdio: 'ignore',
    detached: true,
  }).unref();
} catch (e) { /* legal 폴더 없으면 무시 */ }

// 1. 포트 3000~3005 사용 프로세스 종료 (Next.js가 다른 포트 쓴 경우 대비)
const ports = [3000, 3001, 3002, 3003, 3004, 3005];
const pids = new Set();

try {
  const result = execSync('netstat -ano', { encoding: 'utf8' });
  result.split('\n').forEach((line) => {
    ports.forEach((port) => {
      const match = line.match(new RegExp(`:${port}\\s`));
      if (match) {
        const parts = line.trim().split(/\s+/);
        const pid = parts[parts.length - 1];
        if (pid && pid !== '0') pids.add(pid);
      }
    });
  });
  pids.forEach((pid) => {
    try {
      execSync(`taskkill /PID ${pid} /F`, { stdio: 'ignore' });
      console.log(`포트 사용 프로세스 종료 (PID: ${pid})`);
    } catch (e) { /* 이미 종료됨 */ }
  });
  if (pids.size > 0) {
    execSync('timeout /t 3 /nobreak >nul', { stdio: 'ignore' });
  }
} catch (e) { /* 무시 */ }

// 2. build, .next 폴더 삭제
[path.join(rootDir, 'build'), path.join(rootDir, '.next')].forEach((dir) => {
  try {
    fs.rmSync(dir, { recursive: true, force: true });
    console.log(path.basename(dir) + ' 폴더 삭제 완료');
  } catch (e) { /* 무시 */ }
});

// 3. .next 폴더 및 trace 파일 선생성 (Windows EPERM 회피)
const nextDir = path.join(rootDir, '.next');
const tracePath = path.join(nextDir, 'trace');
try {
  fs.mkdirSync(nextDir, { recursive: true });
  fs.writeFileSync(tracePath, '', 'utf8');
  console.log('.next/trace 파일 선생성 완료');
} catch (e) { /* 무시 */ }
