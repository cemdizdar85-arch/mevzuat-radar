// Yerel önizleme sunucusu — yalnız geliştirme içindir, yayına girmez.
// Kullanım: node arac/yerel-sunucu.js   (varsayılan port 5173)
const http = require('http');
const fs = require('fs');
const path = require('path');

const KOK = path.resolve(__dirname, '..');
const PORT = Number(process.env.PORT) || 5173;

const TUR = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'text/javascript; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.svg': 'image/svg+xml',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.pdf': 'application/pdf',
  '.txt': 'text/plain; charset=utf-8'
};

http.createServer((istek, cevap) => {
  let yol = decodeURIComponent(istek.url.split('?')[0]);
  if (yol === '/') yol = '/deneme.html';
  const tam = path.join(KOK, yol);
  // kök dışına çıkışı engelle
  if (!tam.startsWith(KOK)) { cevap.writeHead(403).end('403'); return; }
  fs.readFile(tam, (hata, veri) => {
    if (hata) { cevap.writeHead(404, {'Content-Type':'text/plain; charset=utf-8'}).end('404 — ' + yol); return; }
    cevap.writeHead(200, {
      'Content-Type': TUR[path.extname(tam).toLowerCase()] || 'application/octet-stream',
      'Cache-Control': 'no-store'
    });
    cevap.end(veri);
  });
}).listen(PORT, () => console.log('yerel sunucu hazir: http://localhost:' + PORT));
