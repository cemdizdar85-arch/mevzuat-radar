// node inen-kontrol2.js <ret json (kimlik -> gerekçe)> : kimlikler sitede (paket_soru) hâlâ duruyor mu? Salt okuma.
const fs = require('fs');
const ids = Object.keys(JSON.parse(fs.readFileSync(process.argv[2], 'utf8')));
const K = process.env.SUPABASE_SERVICE_KEY, h = { apikey: K, Authorization: 'Bearer ' + K };
(async () => {
  const kalan = [];
  for (const id of ids) { const r = await fetch(`https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/paket_soru?select=id&sinav=eq.smmm&id=eq.${encodeURIComponent(id)}`, { headers: h }).then(r => r.json()); if (!Array.isArray(r)) { console.log('HATA', JSON.stringify(r).slice(0, 120)); continue; } if (r.length) kalan.push(id); }
  console.log(`${ids.length} kimlikten sitede hâlâ duran: ${kalan.length}`, kalan);
})();
