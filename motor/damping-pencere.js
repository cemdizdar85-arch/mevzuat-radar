#!/usr/bin/env node
/* ============================================================================
 *  DAMPING PENCERE BEKCISI (30.08.2026)
 *
 *  NE OLCER: yururlukteki kesin onlemlerin 5 yillik suresi (veri/gtip-damping.json
 *  'sd' alani) ve ondan turetilen IKI TARIH:
 *    - BASVURU SON GUNU = sd - 3 ay. Yerli ureticiler nihai gozden gecirme
 *      talebini "yururluk suresinin sona ermesinden EN GEC 3 AY ONCE" vermek
 *      zorunda (Ithalatta Haksiz Rekabetin Onlenmesi Hakkinda Yonetmelik m.35/2).
 *      Bu gun kacarsa onlem kendiliginden kalkar - geri donusu yoktur.
 *    - SURE DOLUMU = sd. Ithalatci icin "vergi kalkabilir" tarihi.
 *
 *  NEDEN ROBOT: bu tarihler bir insanin takvimine yazilmazsa kacar. 30.08 olcumu:
 *  ilk basvuru penceresi 20.10.2026'da kapaniyor (20.01.2027 dolumlu motosiklet/
 *  bisiklet lastigi onlemleri). Kimse hatirlatmazsa o gun sessizce gecer.
 *
 *  UYDURMA YASAGI: 'sd' bos olan kayit (273'un 118'i, cogu etkisiz kilma satiri)
 *  HESABA GIRMEZ; "suresiz" ya da "yakin degil" DENMEZ, "olculmedi" sayilir.
 *
 *  Kullanim:
 *    node motor/damping-pencere.js            # 60 gunluk ufuk
 *    node motor/damping-pencere.js --gun 120  # ufku degistir
 *  Cikti: konsol + motor/cikti/damping-pencere.json
 *  Cikis kodu: 0 (her zaman) - bu bir KAPI degil, TAKVIM. Kirmizi ureten yok.
 * ==========================================================================*/
'use strict';
const fs = require('fs'), path = require('path');

const KOK = path.resolve(__dirname, '..');
const args = process.argv.slice(2);
const gi = args.indexOf('--gun');
const UFUK = gi > -1 ? Math.max(1, parseInt(args[gi + 1], 10) || 60) : 60;

const gunEkle = (d, n) => new Date(d.getTime() + n * 86400000);
const gunFark = (a, b) => Math.round((a - b) / 86400000);
const yaz = s => { const [y, a, g] = s.split('-'); return `${g}.${a}.${y}`; };

const bugunStr = new Date().toISOString().slice(0, 10);
const bugun = new Date(bugunStr + 'T00:00:00Z');

const onlemler = JSON.parse(fs.readFileSync(path.join(KOK, 'veri', 'gtip-damping.json'), 'utf8').replace(/^﻿/, ''));
const tarihli = onlemler.filter(x => x.sd);

// urun + dolum tarihi bazinda topla (ayni onlem birden cok ulke satirinda durur)
const grup = new Map();
for (const o of tarihli) {
  const anahtar = (o.m || '') + '|' + o.sd;
  if (!grup.has(anahtar)) grup.set(anahtar, { urun: o.m, sd: o.sd, teblig: o.tb, ulke: new Set(), kod: new Set() });
  const g = grup.get(anahtar);
  g.ulke.add(o.u);
  String(o.k || '').split(/\s+/).filter(Boolean).forEach(k => g.kod.add(k));
}

const satirlar = [...grup.values()].map(g => {
  const sd = new Date(g.sd + 'T00:00:00Z');
  const sonGun = gunEkle(sd, -90);                 // m.35/2: en gec 3 ay once
  return {
    urun: g.urun, teblig: g.teblig,
    ulkeler: [...g.ulke], kodAdedi: g.kod.size,
    sureDolumu: g.sd, sureDolumunaGun: gunFark(sd, bugun),
    basvuruSonGunu: sonGun.toISOString().slice(0, 10), basvurayaGun: gunFark(sonGun, bugun),
  };
}).sort((a, b) => a.basvuruSonGunu < b.basvuruSonGunu ? -1 : 1);

const acilanPencere = satirlar.filter(s => s.basvurayaGun >= 0 && s.basvurayaGun <= UFUK);
const kacan = satirlar.filter(s => s.basvurayaGun < 0 && s.sureDolumunaGun >= 0);   // basvuru gunu gecti, onlem hala yururlukte
const yakinDolum = satirlar.filter(s => s.sureDolumunaGun >= 0 && s.sureDolumunaGun <= UFUK);

const rapor = {
  ufukGun: UFUK,
  onlemKaydi: onlemler.length,
  tarihiOkunan: tarihli.length,
  tarihiOkunmayan: onlemler.length - tarihli.length,   // "olculmedi" - suresiz DEGIL
  toplamOnlem: satirlar.length,
  basvuruPenceresiAcilan: acilanPencere,
  basvuruGunuGecmis: kacan.slice(0, 20),
  yakinSureDolumu: yakinDolum,
};

fs.mkdirSync(path.join(KOK, 'motor', 'cikti'), { recursive: true });
fs.writeFileSync(path.join(KOK, 'motor', 'cikti', 'damping-pencere.json'), JSON.stringify(rapor, null, 1), 'utf8');

console.log('=== DAMPING PENCERE BEKCISI ===');
console.log(`onlem kaydi ${rapor.onlemKaydi} · sure tarihi okunan ${rapor.tarihiOkunan} · okunmayan ${rapor.tarihiOkunmayan} (olculmedi)`);
console.log(`benzersiz onlem (urun+dolum): ${rapor.toplamOnlem} · ufuk: ${UFUK} gun\n`);

if (acilanPencere.length) {
  console.log(`>> NGGS BASVURU SON GUNU ${UFUK} GUN ICINDE (${acilanPencere.length} onlem):`);
  for (const s of acilanPencere)
    console.log(`   ${yaz(s.basvuruSonGunu)} (${s.basvurayaGun} gun) · ${s.urun} · ${s.ulkeler.join(', ')} · teblig ${s.teblig} · sure dolumu ${yaz(s.sureDolumu)}`);
} else {
  console.log(`>> ${UFUK} gun icinde basvuru son gunu olan onlem yok.`);
}
if (yakinDolum.length) {
  console.log(`\n>> SURESI ${UFUK} GUN ICINDE DOLACAK (${yakinDolum.length} onlem, ithalatci tarafi):`);
  for (const s of yakinDolum) console.log(`   ${yaz(s.sureDolumu)} (${s.sureDolumunaGun} gun) · ${s.urun} · ${s.ulkeler.join(', ')}`);
}
if (kacan.length) console.log(`\n>> basvuru gunu GECMIS ama onlem hala yururlukte: ${kacan.length} (ilk: ${kacan[0] ? kacan[0].urun : '-'})`);
console.log('\nRapor -> motor/cikti/damping-pencere.json');
