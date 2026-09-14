// motor/hesap-sil.js — "HESABIMI SİL" BAŞVURUSU (14.09.2026)
//
// kvkk.html sözü: "hesabın kapatılmasından sonra 30 gün içinde silinir" + "kayıtlı e-posta
// adresinizden info@dizdardenetim.com'a 'hesabımı sil' yazmanız yeterlidir". Bu betik o sözü
// tek komuta indirir. Başvuru KAYITLI adresten gelmediyse ÇALIŞTIRMA (kimlik teyidi yok demektir).
//
//   node motor/hesap-sil.js --eposta ad@ornek.com          KURU: hesap + her tablodaki satır sayısı
//   node motor/hesap-sil.js --eposta ad@ornek.com --yaz    siler, sonra yeniden sayar (hepsi 0 olmalı)
//
// Silme sırası: e-postayla bağlı satırlar (form_kayit, kurulus_nobet, leadler) -> auth kullanıcısı.
// user_id taşıyan tablolar (firmalar, firma_uyarilari, paket_uyeler, abonelikler, ogrenci_sonuc)
// auth.users'a "on delete cascade" bağlı (radar-app/schema.sql, sql/2026-07-23, 08-19, 09-13):
// kullanıcı silinince kendiliğinden gider. Son sayım bunu ÖLÇER; 0 değilse "elle bak" der.
// Yedekler: haftalık şifreli yedek (yedek.yml) 90 günde kendiliğinden düşer — kvkk.html bunu yazar.
// Anahtar: SUPABASE_SERVICE_KEY (UA açık verilir; tarayıcı benzeri UA reddedilir).
'use strict';

const KOK = 'https://bjrleanjpyujtajmazxn.supabase.co';
const UA = 'tetikte-hesap-sil/1.0';

function arg(ad) { const i = process.argv.indexOf(ad); return i > -1 ? process.argv[i + 1] : null; }

async function istek(yol, secenek) {
  const K = process.env.SUPABASE_SERVICE_KEY;
  const h = Object.assign({ apikey: K, Authorization: `Bearer ${K}`, 'User-Agent': UA }, (secenek && secenek.headers) || {});
  const r = await fetch(KOK + yol, Object.assign({}, secenek, { headers: h }));
  if (!r.ok) throw new Error(`${(secenek && secenek.method) || 'GET'} ${yol.split('?')[0]} -> ${r.status} ${(await r.text()).slice(0, 200)}`);
  return r;
}

async function kullaniciBul(eposta) {
  for (let sayfa = 1; sayfa <= 100; sayfa++) {
    const j = await (await istek(`/auth/v1/admin/users?page=${sayfa}&per_page=1000`)).json();
    const liste = j.users || [];
    const u = liste.find(x => (x.email || '').toLowerCase() === eposta);
    if (u) return u;
    if (liste.length < 1000) return null;
  }
  return null;
}

async function say(tablo, filtre) {
  try {
    const r = await istek(`/rest/v1/${tablo}?select=*&${filtre}`, { method: 'HEAD', headers: { Prefer: 'count=exact', Range: '0-0' } });
    return Number((r.headers.get('content-range') || '').split('/')[1]);
  } catch (e) { return 'ölçülemedi (' + e.message.slice(0, 60) + ')'; }
}

(async () => {
  if (!process.env.SUPABASE_SERVICE_KEY) throw new Error('SUPABASE_SERVICE_KEY yok');
  const eposta = (arg('--eposta') || '').trim().toLowerCase();
  if (!/^[^\s@*%,()]+@[^\s@*%,()]+\.[a-z]{2,}$/.test(eposta)) throw new Error('geçerli --eposta ver');
  const yaz = process.argv.includes('--yaz');
  const e = encodeURIComponent(eposta);

  const u = await kullaniciBul(eposta);
  console.log(`HESAP SİL · ${yaz ? 'YAZ' : 'KURU'} · ${eposta}`);
  console.log(u ? `  auth kullanıcısı: ${u.id} · açılış ${u.created_at} · tür ${(u.user_metadata || {}).hesap_turu || 'isletme'}` : '  auth kullanıcısı: YOK');

  const epostaTablolari = [['form_kayit', `eposta=ilike.${e}`], ['kurulus_nobet', `eposta=ilike.${e}`], ['leadler', `eposta=ilike.${e}`]];
  const kimlikTablolari = u ? [['firmalar', `user_id=eq.${u.id}`], ['firma_uyarilari', `user_id=eq.${u.id}`], ['paket_uyeler', `user_id=eq.${u.id}`],
    ['abonelikler', `user_id=eq.${u.id}`], ['ogrenci_sonuc', `user_id=eq.${u.id}`]] : [];
  const tum = epostaTablolari.concat(kimlikTablolari);
  for (const [t, f] of tum) console.log(`  ${t}: ${await say(t, f)}`);

  if (!yaz) { console.log('KURU koşu — hiçbir şey silinmedi. Uygulamak için --yaz.'); return; }

  for (const [t, f] of epostaTablolari) {
    const r = await istek(`/rest/v1/${t}?${f}`, { method: 'DELETE', headers: { Prefer: 'return=minimal,count=exact' } });
    console.log(`  silindi ${t}: ${(r.headers.get('content-range') || '').split('/')[1]}`);
  }
  if (u) { await istek(`/auth/v1/admin/users/${u.id}`, { method: 'DELETE' }); console.log('  silindi auth kullanıcısı'); }

  let temiz = true;
  for (const [t, f] of tum) { const n = await say(t, f); if (n !== 0) temiz = false; console.log(`  son sayım ${t}: ${n}`); }
  if (u && await kullaniciBul(eposta)) temiz = false;
  console.log(temiz ? 'TAMAM — başvurana "verileriniz silindi" yanıtı verilebilir (30 gün sınırı).' : 'ELLE BAK — sıfırlanmayan satır var, yanıt vermeden önce incele.');
  if (!temiz) process.exit(2);
})().catch(err => { console.error('HESAP SİL DÜŞTÜ: ' + err.message); process.exit(1); });
