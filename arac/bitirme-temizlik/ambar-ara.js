// Ambardaki (Supabase dokumanlar) resmî metni SALT OKUMA ile arar. Bedel 0.
// node ambar-ara.js ad "<kaynak_ad deseni, ör. %KDVK% m.29% ya da %Katma Deger%>"     → eşleşen kaynak adları (en çok 40)
// node ambar-ara.js metin "<kaynak_ad tam adı>"                                        → o kaydın metni
// node ambar-ara.js icinde "<kaynak_ad deseni>" "<metinde geçen kelime>"                → desene uyan ve metninde kelime geçen kayıtlar (ad + 300 kr)
// İPUCU: Türkçe harf/İ eşleşmeyebilir → harfsiz parçayla ara (ör. %Bagimsiz Denetim%). Desen her yerde % kullan.
const KEY = process.env.SUPABASE_SERVICE_KEY; if (!KEY) { console.error('SUPABASE_SERVICE_KEY yok'); process.exit(2); }
const SB = 'https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/dokumanlar';
const h = { apikey: KEY, Authorization: 'Bearer ' + KEY };
const [kip, a, b] = process.argv.slice(2);
(async () => {
  if (kip === 'ad') { const r = await fetch(`${SB}?select=kaynak_ad&kaynak_ad=ilike.${encodeURIComponent(a)}&limit=40`, { headers: h }).then(r => r.json()); console.log([...new Set(r.map(x => x.kaynak_ad))].join('\n')); }
  else if (kip === 'metin') { const r = await fetch(`${SB}?select=kaynak_ad,metin&kaynak_ad=eq.${encodeURIComponent(a)}&limit=3`, { headers: h }).then(r => r.json()); for (const x of r) console.log(`== ${x.kaynak_ad}\n${x.metin}`); }
  else if (kip === 'icinde') { const r = await fetch(`${SB}?select=kaynak_ad,metin&kaynak_ad=ilike.${encodeURIComponent(a)}&metin=ilike.${encodeURIComponent('%' + b + '%')}&limit=15`, { headers: h }).then(r => r.json()); for (const x of r) { const i = x.metin.toLowerCase().indexOf(String(b).toLowerCase()); console.log(`== ${x.kaynak_ad}\n…${x.metin.slice(Math.max(0, i - 150), i + 300)}…\n`); } }
  else console.log('kip: ad | metin | icinde');
})();
