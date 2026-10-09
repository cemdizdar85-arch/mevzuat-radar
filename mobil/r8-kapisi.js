// ============================================================================
//  R8 KAPISI (09.10.2026) - mobil-android.yml "AAB derle" sonrasi kosar.
//  R8 bir sinifi atarsa ya da adini degistirirse, onu ADIYLA arayan kod (Class.forName)
//  cihazda sessizce kirilir. Bu kapi mapping.txt'de su siniflarin AYNI ADLA durdugunu olcer:
//    - capacitor.plugins.json'daki her eklenti sinifi (PluginManager Class.forName ile yukler)
//    - social-login DependencyAvailabilityChecker'in Class.forName ile aradigi Google/CustomTabs siniflari
//    - ana etkinlik + social-login arayuzu
//  GORMEZ: cihazda calismayi (dahili testte telefonla denenir), JS tarafini, kaynak kucultmeyi.
//
//  Kullanim:  node r8-kapisi.js <mapping.txt> <capacitor.plugins.json>
//             node r8-kapisi.js --sinav      (oz-sinav: bilerek bozuk mapping'i yakaliyor mu)
// ============================================================================
const fs = require('fs');

const SABIT = [
  'com.tetikte.app.MainActivity',
  'ee.forgr.capacitor.social.login.ModifiedMainActivityForSocialLoginPlugin',
  // DependencyAvailabilityChecker.java (social-login 8.5.11) satir 107-113 + 198-201
  'com.google.android.gms.auth.api.identity.AuthorizationRequest',
  'com.google.android.gms.auth.api.identity.AuthorizationResult',
  'com.google.android.gms.auth.api.identity.Identity',
  'com.google.android.gms.common.api.ApiException',
  'com.google.android.libraries.identity.googleid.GetGoogleIdOption',
  'com.google.android.libraries.identity.googleid.GetSignInWithGoogleOption',
  'com.google.android.libraries.identity.googleid.GoogleIdTokenCredential',
  'androidx.browser.customtabs.CustomTabsSession',
  'androidx.browser.customtabs.CustomTabsServiceConnection',
  'androidx.browser.customtabs.CustomTabsClient',
  'androidx.browser.customtabs.CustomTabsIntent',
];

// mapping.txt'de sinif satiri: "a.b.C -> x.y:"  (girintisiz). Ayni adla kalan = korunmus.
function korunanlar(mappingMetni) {
  const ayni = new Set();
  for (const satir of mappingMetni.split('\n')) {
    const m = /^(\S+) -> (\S+):\s*$/.exec(satir);
    if (m && m[1] === m[2]) ayni.add(m[1]);
  }
  return ayni;
}

function denetle(mappingMetni, eklentiler) {
  const ayni = korunanlar(mappingMetni);
  const istenen = [...eklentiler, ...SABIT];
  return { istenen, eksik: istenen.filter((s) => !ayni.has(s)) };
}

if (process.argv[2] === '--sinav') {
  const iyi = SABIT.concat(['com.capacitorjs.plugins.app.AppPlugin']).map((s) => `${s} -> ${s}:`).join('\n');
  const vakalar = [
    ['tam korunmus', iyi, 0],
    ['adi degismis', iyi.replace('com.google.android.gms.common.api.ApiException -> com.google.android.gms.common.api.ApiException:', 'com.google.android.gms.common.api.ApiException -> a.b.c:'), 1],
    ['atilmis eklenti', iyi.replace(/^com\.capacitorjs\.plugins\.app\.AppPlugin.*$/m, ''), 1],
    ['uye satiri sinif sanilmaz', iyi.replace(/^com\.tetikte\.app\.MainActivity.*$/m, '    com.tetikte.app.MainActivity -> com.tetikte.app.MainActivity:'), 1],
  ];
  let dus = 0;
  for (const [ad, metin, beklenen] of vakalar) {
    const n = denetle(metin, ['com.capacitorjs.plugins.app.AppPlugin']).eksik.length;
    const tamam = beklenen === 0 ? n === 0 : n >= beklenen;
    console.log(`${tamam ? 'GECTI' : 'DUSTU'}  ${ad}  (eksik=${n})`);
    if (!tamam) dus++;
  }
  process.exit(dus ? 1 : 0);
}

const [mappingYolu, eklentiYolu] = process.argv.slice(2);
if (!mappingYolu || !eklentiYolu) {
  console.error('kullanim: node r8-kapisi.js <mapping.txt> <capacitor.plugins.json>');
  process.exit(2);
}
if (!fs.existsSync(mappingYolu)) {
  console.error(`::error title=R8 kapisi::mapping.txt yok (${mappingYolu}) - R8 calismadi mi?`);
  process.exit(1);
}
const eklentiler = JSON.parse(fs.readFileSync(eklentiYolu, 'utf8')).map((e) => e.classpath);
const { istenen, eksik } = denetle(fs.readFileSync(mappingYolu, 'utf8'), eklentiler);
console.log(`R8 kapisi: ${istenen.length} sinif soruldu (${eklentiler.length} eklenti + ${SABIT.length} sabit), eksik/yeniden adli: ${eksik.length}`);
for (const s of eksik) console.log(`::error title=R8 kapisi::${s} mapping'de ayni adla YOK - cihazda Class.forName ile bulunamaz`);
process.exit(eksik.length ? 1 : 0);
