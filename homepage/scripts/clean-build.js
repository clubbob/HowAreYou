const fs = require('fs');
const path = require('path');
const buildDir = path.join(__dirname, '..', 'build');
try {
  fs.rmSync(buildDir, { recursive: true, force: true });
  console.log('build 폴더 삭제 완료');
} catch (e) {
  // 폴더 없거나 삭제 실패 시 무시
}
