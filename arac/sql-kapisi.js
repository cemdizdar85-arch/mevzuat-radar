#!/usr/bin/env node
/* ===========================================================================
   SQL KAPISI — "depoya çalıştırılamaz SQL girmesin"  (01.09.2026)

   Cem: "SQL kapısını kur."

   NEDEN VAR — 01.09'da yaşandı: veri/sql-marka-takip.sql içine
       set search_path = public, extensions as $      <- TEK dolar
   girdi; doğrusu $$ idi. O dosya çalıştırılsa hata verirdi. Fark edilmedi
   çünkü JavaScript'e `node --check`, PowerShell'e parser vardı — SQL'e
   HİÇBİR ŞEY yoktu.

   İLK SÜRÜMÜM YANLIŞTI, o da buraya yazılıyor: dolar tırnağını yalnız "$$"
   sanıp 24 dosyada YANLIŞ ALARM verdi. PostgreSQL adlandırılmış tırnak da
   kullanır: $fn$ ... $fn$ , $ext$ ... $ext$. Gürültülü kapı, insanı kırmızıyı
   yok saymaya alıştırır — kapı olmamasından kötüdür. Bu sürüm tırnakları
   GERÇEKTEN ayrıştırıyor.

   NASIL BAKAR: metni soldan sağa yürür.
     · satır yorumlarını ve blok yorumlarını atlar
     · $tag$ ... $tag$ gövdelerini bir bütün olarak atlar (açılan tırnak,
       AYNI etiketle kapanmalı)
     · gövde dışındaki '...' dizelerini atlar
     · geriye kalanda: kapanmamış tırnak, yalnız duran $, parantez dengesi

   NE BAKMAZ: SQL'in ANLAMI. Bu bir söz dizimi çitidir. "Çalışır" demez,
   "çalıştırılamaz hâlde değil" der.
   =========================================================================== */
'use strict';
const fs = require('fs');
const path = require('path');

const KOK = path.join(__dirname, '..');
const D = '$';
const ETIKET = /^\$([A-Za-z_][A-Za-z0-9_]*)?\$/;   // $$ ya da $fn$

function sqlDosyalari(dizin, biriken) {
  biriken = biriken || [];
  for (const ad of fs.readdirSync(dizin)) {
    if (ad === '.git' || ad === 'node_modules' || ad === '_kaynak') continue;
    const tam = path.join(dizin, ad);
    let st; try { st = fs.statSync(tam); } catch (e) { continue; }
    if (st.isDirectory()) sqlDosyalari(tam, biriken);
    else if (/\.sql$/i.test(ad)) biriken.push(tam);
  }
  return biriken;
}

function incele(m) {
  const kusur = [];
  let i = 0, ac = 0, kapa = 0, tekDolar = [], acikEtiket = null, acikYer = -1;

  while (i < m.length) {
    // --- dolar tırnağı gövdesi içindeyiz ---
    if (acikEtiket !== null) {
      if (m[i] === D) {
        const e = ETIKET.exec(m.slice(i));
        if (e && (e[1] || '') === acikEtiket) { acikEtiket = null; i += e[0].length; continue; }
      }
      i++; continue;                       // gövde içi: hiçbir şey sayılmaz
    }
    // --- satır yorumu ---
    if (m[i] === '-' && m[i + 1] === '-') { while (i < m.length && m[i] !== '\n') i++; continue; }
    // --- blok yorumu ---
    if (m[i] === '/' && m[i + 1] === '*') { i += 2; while (i < m.length && !(m[i] === '*' && m[i + 1] === '/')) i++; i += 2; continue; }
    // --- dolar tırnağı açılışı ---
    if (m[i] === D) {
      const e = ETIKET.exec(m.slice(i));
      if (e) { acikEtiket = e[1] || ''; acikYer = i; i += e[0].length; continue; }
      tekDolar.push(i); i++; continue;     // etiket değil: yalnız duran $
    }
    // --- tek tırnaklı dize ('' kaçışı dahil) ---
    if (m[i] === "'") {
      i++;
      while (i < m.length) {
        if (m[i] === "'" && m[i + 1] === "'") { i += 2; continue; }
        if (m[i] === "'") { i++; break; }
        i++;
      }
      continue;
    }
    if (m[i] === '(') ac++;
    if (m[i] === ')') kapa++;
    i++;
  }

  if (acikEtiket !== null) {
    const cevre = m.slice(Math.max(0, acikYer - 60), acikYer + 6).replace(/\s+/g, ' ').trim();
    kusur.push(`KAPANMAMIS dolar tirnagi ($${acikEtiket}$) - "...${cevre}"`);
  }
  if (tekDolar.length) {
    const c = m.slice(Math.max(0, tekDolar[0] - 50), tekDolar[0] + 5).replace(/\s+/g, ' ').trim();
    kusur.push(`yalniz duran $ (${tekDolar.length} adet) - ilki: "...${c}"`);
  }
  if (ac !== kapa) kusur.push(`parantez dengesiz (govde disi): ${ac} ac / ${kapa} kapa`);
  return kusur;
}

/* --- ÖZ-SINAV: kapı doğru mu? Gerçek dosyalara bakmadan önce bilinen
   örneklerle sınanır. İlk sürüm 24 yanlış alarm vermişti; bu sınav onu
   yakalardı. -------------------------------------------------------------- */
function ozSinav() {
  const ornek = [
    ['saglam $$',        "create function f() returns int language sql as $$ select 1; $$;", 0],
    ['saglam $fn$',      "create function f() returns int language plpgsql as $fn$ begin return 1; end; $fn$;", 0],
    ['ic ice etiket',    "do $ext$ begin execute 'select $$x$$'; end $ext$;", 0],
    ['BOZUK tek dolar',  "create function f() returns int language sql as $ select 1; $$;", 1],
    ['BOZUK kapanmamis', "create function f() returns int language sql as $$ select 1;", 1],
    ['dizede dolar',     "select 'fiyat: 100$ dir';", 0],
    ['yorumda dolar',    "-- burada $ tek basina duruyor ama yorumda\nselect 1;", 0],
    ['parantez eksik',   "select foo(1, 2;", 1]
  ];
  const dusen = [];
  for (const [ad, metin, beklenenKusur] of ornek) {
    const k = incele(metin);
    const var_ = k.length > 0 ? 1 : 0;
    if (var_ !== beklenenKusur) dusen.push(`${ad}: beklenen ${beklenenKusur ? 'KUSUR' : 'temiz'}, cikan ${var_ ? 'KUSUR (' + k[0] + ')' : 'temiz'}`);
  }
  return dusen;
}

const sinavDusen = ozSinav();
if (sinavDusen.length) {
  console.log('!! SQL KAPISI KENDI OZ-SINAVINI GECEMEDI - olcum yapilmadi:');
  sinavDusen.forEach(x => console.log('   ' + x));
  console.log('   Kapinin kendisi bozuksa verdigi hukum de bozuktur.');
  process.exit(1);
}
console.log(`Oz-sinav gecti (8 ornek: saglam/bozuk/adlandirilmis tirnak).`);

const dosyalar = sqlDosyalari(KOK);
let kirmizi = 0;
const bulgular = [];
for (const f of dosyalar) {
  const yol = path.relative(KOK, f).replace(/\\/g, '/');
  const ham = fs.readFileSync(f, 'utf8');
  const kusur = incele(ham);
  if (ham.charCodeAt(0) === 0xFEFF) kusur.push('dosya BOM ile basliyor (gorunmez karakter)');
  if (kusur.length) { kirmizi++; bulgular.push({ yol, kusur }); }
}

console.log(`SQL KAPISI - ${dosyalar.length} dosya bakildi.`);
if (!kirmizi) {
  console.log('YESIL: calistirilamaz hale gelmis SQL yok.');
  console.log('(Bu kapi SOZ DIZIMINE bakar, anlama degil.)');
  process.exit(0);
}
console.log(`\nKIRMIZI: ${kirmizi} dosyada kusur var\n`);
bulgular.forEach(b => {
  console.log('  ' + b.yol);
  b.kusur.forEach(k => console.log('      - ' + k));
});
console.log('\n01.09 dersi: bu kapi olmadigi icin depoya calistirilamaz bir SQL');
console.log('dosyasi girmisti ($$ yerine tek $). Kirmizi ise DUZELTILMEDEN gecilmez.');
process.exit(1);
