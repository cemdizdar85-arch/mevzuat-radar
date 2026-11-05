// D2 KANIT CÜMLESİ ölçüsü (BITIRME-SORU-STANDARDI §7 D2'nin KGK eşi). Bedel 0, salt okuma.
// Her sorunun `dayanak` alanı " · " ile parçalara bölünür; "<ref>: <alıntı>" biçimindeki her parça için ref'e uyan ambar kaydı
// (kaynak_adlar'daki "<ref> - …" adı ya da "<ref>%" deseni) okunur, alıntının "..." ile ayrılmış her dilimi (≥25 kr) normalize edilmiş metinde aranır.
// Sonuç: soru başı BULUNDU (tüm dilimler) / KISMEN / YOK. GÖRMEZ: alıntının doğru şıkkı gerçekten belirleyip belirlemediği (doğrulayıcı okur) ·
//   kayıt adı ambarda farklı yazılmışsa YOK der (yanlış alarm olabilir — elle bakılır) · çok uzun kayıtta yanlış paragraf eşleşmesi.
// node kanit-ara.js <grup>
'use strict';
const fs = require('fs'), cp = require('child_process');
const K = (process.env.SUPABASE_SERVICE_KEY || cp.spawnSync('powershell', ['-NoProfile', '-Command', "[Environment]::GetEnvironmentVariable('SUPABASE_SERVICE_KEY','User')"], { encoding: 'utf8' }).stdout || '').trim();
const B = 'https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/dokumanlar', H = { apikey: K, Authorization: 'Bearer ' + K };
const norm = s => String(s).replace(/[\u2010-\u2015]/g, '-').replace(/[“”"']/g, '').replace(/\s+/g, ' ').trim().toLocaleLowerCase('tr');
const grup = process.argv[2]; const FAB = 'C:/TETIKTE-CALISMA/kgk-basim/veri/fabrika/';
const onbellek = {};
async function kayitlar(ref, adlar) {
  const ad = adlar.filter(a => a === ref || a.startsWith(ref + ' ') || a.startsWith(ref + ' -'));
  // ad eşleşmezse (kısa ad: 'SPK Rehber [5/20]', 'Uzatma Kararı') sorunun kaynak_adlar kayıtlarının hepsi aday
  const desen = ad.length ? ad : (adlar.length ? adlar : [ref + '%']);
  const out = [];
  for (const d of desen) {
    if (!onbellek[d]) { const q = d.includes('%') ? `kaynak_ad=ilike.${encodeURIComponent(d)}` : `kaynak_ad=eq.${encodeURIComponent(d)}`; const r = await fetch(`${B}?select=kaynak_ad,metin&${q}&limit=20`, { headers: H }); onbellek[d] = r.ok ? await r.json() : []; }
    out.push(...onbellek[d]);
  }
  return out;
}
(async () => {
  let bul = 0, kis = 0, yok = 0;
  for (const z of ['kolay', 'zor', 'cokzor']) {
    const f = FAB + `hazir-kgk-t10-${grup}-${z}.json`; if (!fs.existsSync(f)) continue;
    const A = JSON.parse(fs.readFileSync(f, 'utf8').replace(/^\uFEFF/, ''));
    for (let i = 0; i < A.length; i++) {
      const q = A[i], adlar = q.kaynak_adlar || [], parcalar = String(q.dayanak || '').split(/\s·\s/).map(s => s.trim()).filter(Boolean);
      let toplam = 0, tutan = 0; const eksik = [];
      for (const p of parcalar) {
        const m = p.match(/^(.{3,160}?(?:p\.|m\.|madde |paragraf |Ek |bolum |bölüm )[^:]{0,40}):\s*(.+)$/i) || p.match(/^([^:]{3,160}):\s*(.+)$/); if (!m) continue;
        const ref = m[1].trim(), dilimler = m[2].split(/\s*(?:\.\.\.|…)\s*/).map(s => s.replace(/^[(\s]+|[\s)]+$/g, '')).filter(s => s.length >= 25);
        const R = await kayitlar(ref, adlar); const metin = norm(R.map(r => r.metin).join(' '));
        for (const d of dilimler) { toplam++; if (metin && metin.includes(norm(d))) tutan++; else eksik.push(`${ref}: "${d.slice(0, 50)}…"${R.length ? '' : ' (kayıt bulunamadı)'}`); }
      }
      const durum = !toplam ? 'ÖLÇÜLMEDİ (alıntı biçimi okunamadı)' : tutan === toplam ? 'BULUNDU' : tutan ? 'KISMEN' : 'YOK';
      if (durum === 'BULUNDU') bul++; else if (durum === 'KISMEN') kis++; else yok++;
      console.log(`${grup}-${z}[${i}]`.padEnd(22), `${durum} ${tutan}/${toplam}`, eksik.length ? '· ' + eksik.slice(0, 2).join(' | ') : '');
    }
  }
  console.log(`ÖZET ${grup}: BULUNDU ${bul} · KISMEN ${kis} · YOK/ÖLÇÜLMEDİ ${yok}`);
  process.exit(kis || yok ? 1 : 0);
})();
