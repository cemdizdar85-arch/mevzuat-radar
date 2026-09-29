// meta-olay.ts doğrulama öz-sınavı (29.09.2026). Koşu: node --experimental-strip-types arac/meta-olay-sinavi.mjs
import { dogrula, metaGovde } from '../radar-app/edge/meta-olay.ts';
let h = 0; const t = (ok, m) => { console.log((ok ? 'GEÇTİ ' : 'KALDI ') + m); if (!ok) h++; };
const iyi = { olay: 'Lead', event_id: 'abcd1234-ef', url: 'https://tetikte.com/seviye-testi.html', em: 'a'.repeat(64), content_name: 'seviye-testi' };
t(dogrula(iyi).ok, 'geçerli Lead kabul');
t(!dogrula({ ...iyi, olay: 'Hack' }).ok, 'beyaz liste dışı olay ret');
t(!dogrula({ ...iyi, em: 'x@y.com' }).ok, 'açık e-posta ret');
t(!dogrula({ ...iyi, url: 'https://kotu.com/' }).ok, 'yabancı url ret');
t(!dogrula({ ...iyi, value: 100, currency: 'USD' }).ok, 'USD ret');
t(!dogrula({ ...iyi, value: -5, currency: 'TRY' }).ok, 'negatif tutar ret');
const d = dogrula({ ...iyi, olay: 'InitiateCheckout', value: 1234.5, currency: 'TRY' });
const g = d.ok && metaGovde(d.olay, '1.2.3.4', 'UA', '');
t(g && g.data[0].custom_data.value === 1234.5 && g.data[0].user_data.em[0] === 'a'.repeat(64) && g.data[0].action_source === 'website' && !('test_event_code' in g), 'Meta gövdesi doğru');
t(metaGovde(dogrula(iyi).olay, '', '', 'TEST1').test_event_code === 'TEST1', 'test kodu geçiyor');
console.log(h ? `SONUÇ: ${h} KALDI` : 'SONUÇ: HEPSİ GEÇTİ'); process.exit(h ? 1 : 0);
