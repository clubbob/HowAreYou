const sharp = require('sharp');
const path = require('path');
const fs = require('fs');

const src = process.argv[2] || path.join(__dirname, '../../assets/images/logo.png');

// 하늘색과 어울리는 하모니 팔레트
const PALETTE = {
  skyBg: [0xA8, 0xD4, 0xEC],      // 부드러운 하늘색
  logoGreen: [0x4A, 0x9B, 0x8C],   // 하늘과 조화되는 틸-세이지
  outline: [0x6B, 0x8A, 0x9E],     // 블루그레이 아웃라인
  whiteArea: [0xF5, 0xFA, 0xFC],   // 은은한 블루 틴트 화이트
};

function isNear(c, ref, tol = 40) {
  return Math.abs(c[0] - ref[0]) < tol && Math.abs(c[1] - ref[1]) < tol && Math.abs(c[2] - ref[2]) < tol;
}

async function run() {
  const img = await sharp(src).ensureAlpha().raw().toBuffer({ resolveWithObject: true });
  const { data, info } = img;
  const { width, height, channels } = info;

  for (let i = 0; i < data.length; i += channels) {
    const r = data[i], g = data[i + 1], b = data[i + 2];
    
    // 기존 하늘색 배경 → 조화로운 하늘색
    if (r > 120 && g > 180 && b > 220 && r < 180 && b > g) {
      [data[i], data[i + 1], data[i + 2]] = PALETTE.skyBg;
      continue;
    }
    
    // 검정/진한 아웃라인 → 블루그레이
    if (r < 80 && g < 80 && b < 80) {
      [data[i], data[i + 1], data[i + 2]] = PALETTE.outline;
      continue;
    }
    
    // 세이지 그린 (로고) → 틸-세이지
    if (g > r && g > b && r > 60 && b > 80 && g < 200) {
      [data[i], data[i + 1], data[i + 2]] = PALETTE.logoGreen;
      continue;
    }
    
    // 화이트 영역 → 은은한 블루 틴트
    if (r > 240 && g > 240 && b > 240) {
      [data[i], data[i + 1], data[i + 2]] = PALETTE.whiteArea;
      continue;
    }
  }

  const result = await sharp(Buffer.from(data), { raw: info })
    .png()
    .toBuffer();

  const dests = [
    path.join(__dirname, '../../assets/images/logo.png'),
    path.join(__dirname, '../../assets/icon/icon.png'),
    path.join(__dirname, '../public/logo.png'),
  ];
  for (const dest of dests) {
    fs.writeFileSync(dest, result);
    console.log('Saved:', dest);
  }
}

run().catch(console.error);
