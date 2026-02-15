const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

// 1. 포트 3000 사용 프로세스 종료 (Windows)
try {
  const result = execSync('netstat -ano', { encoding: 'utf8' });
  const pids = new Set();
  result.split('\n').forEach(line => {
    const match = line.match(/:3000\s/);
    if (match) {
      const parts = line.trim().split(/\s+/);
      const pid = parts[parts.length - 1];
      if (pid && pid !== '0') pids.add(pid);
    }
  });
  pids.forEach(pid => {
    try {
      execSync(`taskkill /PID ${pid} /F`, { stdio: 'ignore' });
      console.log(`포트 3000 프로세스 종료 (PID: ${pid})`);
    } catch (e) { /* 이미 종료됨 */ }
  });
} catch (e) { /* netstat 실패 시 무시 */ }

// 2. build 폴더 삭제
const buildDir = path.join(__dirname, '..', 'build');
try {
  fs.rmSync(buildDir, { recursive: true, force: true });
  console.log('build 폴더 삭제 완료');
} catch (e) { /* 무시 */ }
