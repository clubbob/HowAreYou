const sharp = require('sharp');
const path = require('path');
const fs = require('fs');

const src = process.argv[2] || path.join(__dirname, '../../assets/images/logo.png');
const blueHex = '#87CEEB'; // 하늘색 - 희망
const [r, g, b] = [0x87, 0xCE, 0xEB];

async function run() {
  const img = await sharp(src).ensureAlpha().raw().toBuffer({ resolveWithObject: true });
  const { data, info } = img;
  const { width, height, channels } = info;

  for (let i = 0; i < data.length; i += channels) {
    const pixelIsBlack = data[i] < 30 && data[i + 1] < 30 && data[i + 2] < 30;
    if (pixelIsBlack) {
      data[i] = r;
      data[i + 1] = g;
      data[i + 2] = b;
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
