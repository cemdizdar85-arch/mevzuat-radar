#!/usr/bin/env node
/* YALNIZ PROVA: www/ altındaki her HTML'in <head>'inin en başına prova-kumanda.js'i ekler; CSP'si olan sayfada
 * connect-src'ye prova sunucusunu, script-src'ye 'unsafe-eval' ekler. mobil-ios-prova.yml hazirla.js'ten SONRA koşar;
 * mobil-ios.yml / mobil-android.yml ÇAĞIRMAZ → mağaza derlemesine girmez. */
'use strict';
const fs = require('fs');
const path = require('path');
const WWW = path.join(__dirname, 'www');
fs.copyFileSync(path.join(__dirname, 'prova-kumanda.js'), path.join(WWW, 'prova-kumanda.js'));
let say = 0, csp = 0;
(function gez(d) {
  for (const a of fs.readdirSync(d, { withFileTypes: true })) {
    const p = path.join(d, a.name);
    if (a.isDirectory()) { gez(p); continue; }
    if (!/\.html$/.test(a.name)) continue;
    let t = fs.readFileSync(p, 'utf8');
    const m = t.match(/<head[^>]*>/i);
    if (!m) continue;
    const rel = path.relative(path.dirname(p), path.join(WWW, 'prova-kumanda.js')).split(path.sep).join('/');
    t = t.replace(m[0], m[0] + '<script src="' + rel + '"></script>');
    if (/Content-Security-Policy/i.test(t)) {
      t = t.replace(/connect-src /, 'connect-src http://127.0.0.1:8777 ').replace(/script-src /, "script-src 'unsafe-eval' ");
      csp++;
    }
    fs.writeFileSync(p, t); say++;
  }
})(WWW);
console.log('prova kumandasi: ' + say + ' sayfa · CSP genisletilen ' + csp);
if (!say) { console.error('HIC SAYFA YOK'); process.exit(1); }
