// ============================================================================
//  DENEME SET ARŞİVİ (11.10.2026, Cem: "sitede soru çözen çözdüğü yerde kalıyordu … tekrar ordan başlıyordu")
//
//  SORUN (ölçüldü 11.10): sinav-gibi.html yarım denemeyi tarayıcıda set SÜRÜMÜNE bağlı anahtarla tutar
//  (sg_<sınav>[_<tür>]_<no>_<sürüm>). Basıcı setleri yeniden kurunca sürüm değişir, eski set dosyası ezilir →
//  öğrencinin yarım denemesi listede görünmez, "Devam et" kaybolur (11.10 12:00 Yeterlilik konu setleri).
//  ÇÖZÜM: set yeniden kurulmadan ÖNCE eski setler veri/deneme/arsiv/<onek>-<sürüm>/set-NN.json olarak saklanır
//  (YALNIZ KİMLİK, set dosyasının aynısı). Sayfa eski sürümde yarım kalmış denemeyi arşivdeki setle açar.
//  Sıra veri/deneme/arsiv/sira.json'da (en yeni önce; dosya tarihine GÜVENİLMEZ: bulutta checkout hepsini aynı yapar).
//  Her onek için en yeni ARSIV_TAVAN sürüm tutulur; daha eskisi silinir.
//  🚫 GÖRMEZ: tavanın gerisinde kalan çok eski yarım deneme (arşivden silinmişse sayfa onu listelemez).
// ============================================================================
const fs = require('fs');
const path = require('path');
const ARSIV_TAVAN = 4;

function jsonOku(y) { return JSON.parse(fs.readFileSync(y, 'utf8').replace(/^﻿/, '')); }

// cikis = veri/deneme · onek = 'sgs' | 'sgs-sik' | 'smmm-sik' | 'smmm-ders' (dizin: <onek>-dizin.json)
// Eski dizin varsa ve sürümü yeniSurum'dan farklıysa eski setleri arşive kopyalar. Dönüş: kopyalanan set sayısı.
function arsivle(cikis, onek, yeniSurum, kuru) {
  let eski = null; try { eski = jsonOku(path.join(cikis, `${onek}-dizin.json`)); } catch (e) { return 0; }
  if (!eski || !eski.surum || eski.surum === yeniSurum || kuru) return 0;
  const kok = path.join(cikis, '..', '..');
  const dosyalar = (eski.setler || []).map(s => ({ no: s.no, yol: path.join(kok, s.dosya) })).filter(x => fs.existsSync(x.yol));
  return arsiveYaz(cikis, onek, eski.surum, dosyalar);
}
// dosyalar: [{no, yol}] — geçmişten doldurma (arac/deneme-arsiv-doldur.js) da bunu kullanır
function arsiveYaz(cikis, onek, surum, dosyalar, enEskiyeEkle) {
  const hedef = path.join(cikis, 'arsiv', `${onek}-${surum}`);
  if (!dosyalar.length || fs.existsSync(hedef)) return 0;
  fs.mkdirSync(hedef, { recursive: true });
  for (const d of dosyalar) {
    if (d.icerik != null) fs.writeFileSync(path.join(hedef, `set-${String(d.no).padStart(2, '0')}.json`), d.icerik, 'utf8');
    else fs.copyFileSync(d.yol, path.join(hedef, `set-${String(d.no).padStart(2, '0')}.json`));
  }
  const siraYol = path.join(cikis, 'arsiv', 'sira.json');
  let sira = {}; try { sira = jsonOku(siraYol); } catch (e) {}
  const L = (sira[onek] || []).filter(s => s !== surum);
  if (enEskiyeEkle) L.push(surum); else L.unshift(surum);
  for (const s of L.slice(ARSIV_TAVAN)) fs.rmSync(path.join(cikis, 'arsiv', `${onek}-${s}`), { recursive: true, force: true });
  sira[onek] = L.slice(0, ARSIV_TAVAN);
  fs.writeFileSync(siraYol, JSON.stringify(sira, null, 1) + '\n', 'utf8');
  return dosyalar.length;
}
module.exports = { arsivle, arsiveYaz, ARSIV_TAVAN };
