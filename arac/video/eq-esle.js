// eq-esle.js <hedef.wav> <kaynak.wav> <cikti.wav> [tur]
// Kaynak sesin (temiz TTS cumlesi) 24 bantlik tini profilini hedefe (klibin ses rengi) esitler.
// Olcu ses-olc.js ile AYNI: 16 kHz, 512 FFT, 24 dogrusal bant (0-8 kHz), yalniz sesli kareler.
// Her turda: olc -> bant farki (dB) -> firequalizer kazancina ekle -> kaynaga uygula -> tekrar olc.
const fs = require('fs'), { execFileSync } = require('child_process'), path = require('path');
const [hedef, kaynak, cikti, turStr] = process.argv.slice(2);
const TUR = parseInt(turStr || '3', 10);
const tmp = path.join(path.dirname(cikti), '_eq16.wav');

function oku(f) {
  const b = fs.readFileSync(f); let o = 12, veri = null, sr = 16000;
  while (o < b.length) { const id = b.toString('ascii', o, o + 4), n = b.readUInt32LE(o + 4);
    if (id === 'fmt ') sr = b.readUInt32LE(o + 12); if (id === 'data') { veri = b.subarray(o + 8, o + 8 + n); break; } o += 8 + n + (n % 2); }
  const x = new Float32Array(veri.length / 2); for (let i = 0; i < x.length; i++) x[i] = veri.readInt16LE(i * 2) / 32768; return { x, sr };
}
function fft(re, im) { const n = re.length; for (let i = 1, j = 0; i < n; i++) { let bit = n >> 1; for (; j & bit; bit >>= 1) j ^= bit; j ^= bit; if (i < j) { [re[i], re[j]] = [re[j], re[i]]; [im[i], im[j]] = [im[j], im[i]]; } }
  for (let len = 2; len <= n; len <<= 1) { const a = -2 * Math.PI / len, wr = Math.cos(a), wi = Math.sin(a);
    for (let i = 0; i < n; i += len) { let cr = 1, ci = 0; for (let k = 0; k < len / 2; k++) { const ur = re[i + k], ui = im[i + k], vr = re[i + k + len / 2] * cr - im[i + k + len / 2] * ci, vi = re[i + k + len / 2] * ci + im[i + k + len / 2] * cr;
      re[i + k] = ur + vr; im[i + k] = ui + vi; re[i + k + len / 2] = ur - vr; im[i + k + len / 2] = ui - vi; const t = cr * wr - ci * wi; ci = cr * wi + ci * wr; cr = t; } } } }
function profil(f16) {
  const { x } = oku(f16); const W = 640, H = 160, N = 512; const bant = new Float64Array(24);
  for (let s = 0; s + W < x.length; s += H) {
    let e = 0; for (let i = 0; i < W; i++) e += x[s + i] * x[s + i]; e /= W; if (e < 0.002) continue;
    const re = new Float64Array(N), im = new Float64Array(N);
    for (let i = 0; i < N; i++) re[i] = x[s + i] * (0.5 - 0.5 * Math.cos(2 * Math.PI * i / (N - 1))); fft(re, im);
    for (let k = 1; k < N / 2; k++) bant[Math.min(23, Math.floor(k / (N / 2) * 24))] += Math.hypot(re[k], im[k]);
  }
  const t = bant.reduce((a, b) => a + b, 0); return Array.from(bant, v => v / t + 1e-9);
}
const to16 = (src, dst) => execFileSync('ffmpeg', ['-nostdin', '-y', '-v', 'error', '-i', src, '-ar', '16000', '-ac', '1', '-c:a', 'pcm_s16le', dst]);
const mesafe = (a, b) => Math.sqrt(a.reduce((s, v, k) => s + (Math.log(v) - Math.log(b[k])) ** 2, 0));

to16(hedef, tmp); const P_hedef = profil(tmp);
to16(kaynak, tmp); let P = profil(tmp);
console.log('tur 0  tini farki: ' + mesafe(P, P_hedef).toFixed(2));
const kazanc = new Array(24).fill(0);          // dB, birikimli
const ORTA = k => Math.round((k + 0.5) * 8000 / 24);
let filtre = '';
for (let tur = 1; tur <= TUR; tur++) {
  for (let k = 0; k < 24; k++) {
    const fark = 10 * Math.log10(P_hedef[k] / P[k]);   // enerji orani -> dB (genlik profili; yumusak adim)
    kazanc[k] = Math.max(-12, Math.min(12, kazanc[k] + 0.8 * fark));
  }
  const girdi = ['entry(0,' + kazanc[0].toFixed(2) + ')']
    .concat(kazanc.map((g, k) => 'entry(' + ORTA(k) + ',' + g.toFixed(2) + ')'))
    .concat(['entry(9000,' + kazanc[23].toFixed(2) + ')', 'entry(24000,' + kazanc[23].toFixed(2) + ')']);
  filtre = "firequalizer=gain_entry='" + girdi.join(';') + "'";
  execFileSync('ffmpeg', ['-nostdin', '-y', '-v', 'error', '-i', kaynak, '-af', filtre, '-ar', '48000', '-ac', '2', cikti]);
  to16(cikti, tmp); P = profil(tmp);
  console.log('tur ' + tur + '  tini farki: ' + mesafe(P, P_hedef).toFixed(2));
}
fs.writeFileSync(cikti + '.filtre.txt', filtre);
fs.unlinkSync(tmp);
console.log('kazanc (dB): ' + kazanc.map(g => g.toFixed(1)).join(' '));
