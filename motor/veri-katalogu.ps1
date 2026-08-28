# ============================================================================
#  VERİ KATALOĞU — SİTE ALANLARI (28.08.2026 gece, Cem: "LinkedIn... bir şey
#  öner; gizlilik bozulmasın; sana sorduğumda en iyi/hızlı cevap")
#
#  KARAR (GM): LinkedIn DataHub'ın FİKRİ alınır, aracı alınmaz. Katalog =
#  veri hakkında veri (alan, ambar/tablo, tek yazarı, canlı kayıt sayısı,
#  sağlık ölçümü tarihi). İÇERİK ASLA KATALOGA GİRMEZ.
#  GİZLİLİK: bu çıktı veri/fabrika altındadır (gitignore duvarının içi) —
#  kayıt SAYILARI bile rakip istihbaratıdır (19.08 gizli-kasa dersi).
#  Mevzuat/standart envanteri ayrı ve kamuya açıktır (AMBAR-ENVANTERI.md).
#
#  KEŞİF: tablo listesi Supabase PostgREST OpenAPI kökünden çekilir — elle
#  liste değil; yeni tablo açılırsa katalog kendiliğinden görür ve sahibi
#  bilinmiyorsa dürüstçe '?' yazar.
#  Günlük 06:45 görevi 3. halka olarak bunu da koşar. 0 USD, model yok.
# ============================================================================
$ErrorActionPreference='Stop'
[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12
$here=Split-Path -Parent $MyInvocation.MyCommand.Path
$kok=Split-Path -Parent $here
$KEY=[Environment]::GetEnvironmentVariable('SUPABASE_SERVICE_KEY','User')
if(-not $KEY){ $KEY=$env:SUPABASE_SERVICE_KEY }
$H=@{apikey=$KEY;Authorization="Bearer $KEY"}
$KOKU='https://bjrleanjpyujtajmazxn.supabase.co/rest/v1'

# --- alan/sahip eşlemesi (bilinenler; bilinmeyen tablo '?' ile listelenir) ---
$ALANMAP=@{
  'dokumanlar'      =@('Mevzuat ambarı + çıkmış arşiv','mevzuat-yut / standart-yut (tek yazar)')
  'soru_havuzu'     =@('Sınav soru kasası','soru-uret hatları + onarım robotları')
  'alacak_ilan'     =@('Alacak Radarı havuzu (GİZLİ KASA)','alacak-supabase-yukle.ps1')
  'alacak_abone'    =@('Alacak Radarı aboneleri','site (RLS) / robot')
  'canli_sonuc'     =@('Canlı deneme sonuçları','site (anon insert-only)')
  'hata_bildirim'   =@('Site hata bildirimleri','site (anon insert)')
  # --- 28.08 gece: 16 sahipsizin kimligi KOLON ADLARINDAN cikarildi (ornek satir CEKILMEDI - kisisel veri okunmadi) ---
  'belgeler'        =@('Evrak Radarı — belge kayıtları','site (RLS) / evrak robotu')
  'cevap_kaydi'     =@('Deneme motoru çözüm kayıtları (adaptif/istatistik hammaddesi)','site (üye, RLS insert)')
  'firma_uyarilari' =@('Radar SaaS firma uyarıları','nöbetçi robotlar')
  'firmalar'        =@('Radar SaaS firma profilleri (KİŞİSEL VERİ - yalnız sayı)','site (RLS)')
  'istekler'        =@('Evrak Radarı istek/talep hattı','site (RLS)')
  'konu_karti'      =@('Konu kartı katmanı (hat 25.08 döşendi, henüz kart basılmadı)','konu-karti hattı (tek yazar)')
  'konu_ortalama'   =@('Konu bazlı çözüm istatistiği','site istatistik robotu')
  'konu_semasi'     =@('Konu şeması (şema mühürlenirse doğal ev)','şema hattı (tek yazar)')
  'kullanim_delilleri'=@('Marka Radarı kullanım delilleri','site (RLS)')
  'leadler'         =@('Pazarlama leadleri (KİŞİSEL VERİ - yalnız sayı)','site formu')
  'mukellefler'     =@('Evrak Radarı mükellefleri (KİŞİSEL VERİ - yalnız sayı)','site (RLS)')
  'paket_uyeler'    =@('Üyelik paketleri','Cem/site (elle+RLS)')
  'rate_log'        =@('Hız sınırı günlüğü (AI uçları)','edge fonksiyonları')
  'soru_bildirim'   =@('Soru hata bildirimleri (karantina beslemesi)','site (üye insert)')
  'soru_istatistik' =@('Soru bazlı çözüm istatistiği','site istatistik robotu')
  'sorular'         =@('Evrak Radarı soru-cevapları','site (RLS)')
}
# ihale/marka/destek tablo adlari kesfifte gelir; taniyorsak asagida yakala
$ALANDESEN=@(
  @('^ihale','İhale Radarı (GİZLİ KASA)','ihale robotları'),
  @('^marka','Marka Radarı','marka nöbetçileri'),
  @('^destek|^cagri','Destek/Çağrı Radarı','destek-takip nöbeti'),
  @('^gozetim|^gtip','Gümrük/GTİP katmanları','gözetim nöbetçisi'),
  @('^uye|^abone|^kayit','Üyelik/kayıt (KİŞİSEL VERİ - yalnız sayı)','site (RLS)')
)

Write-Host 'Tablo listesi (OpenAPI kokunden)...'
$w=Invoke-WebRequest -Uri "$KOKU/" -Headers $H -UserAgent 'mevzuat-radar-robot/1.0' -UseBasicParsing -TimeoutSec 120
$ham=[Text.Encoding]::UTF8.GetString($w.RawContentStream.ToArray())
# PS5.1 ConvertFrom-Json OpenAPI'ye takiliyor (bos/harf-cakisan anahtar) ->
# tablo adlarini paths bolumunden desenle cek: "/tablo" (rpc haric)
$tset=@{}
foreach($m in [regex]::Matches($ham,'"/([A-Za-z0-9_]+)"')){ $tset[$m.Groups[1].Value]=$true }
$tablolar=@($tset.Keys | ? { $_ -ne 'rpc' } | Sort-Object)
Write-Host "  bulunan tablo/görünüm: $($tablolar.Count)"

$satirlar=New-Object System.Collections.Generic.List[object]
$Hc=$H+@{Prefer='count=exact'}
foreach($t in $tablolar){
  $sayi='ÖLÇÜLEMEDİ'
  try{
    $r=Invoke-WebRequest -Uri "$KOKU/$t`?select=*&limit=1" -Headers $Hc -UserAgent 'mevzuat-radar-robot/1.0' -UseBasicParsing -TimeoutSec 60
    $cr="$($r.Headers['Content-Range'])"
    if($cr -match '/(\d+)$'){ $sayi=[int]$Matches[1] }
  }catch{}
  $alan='?'; $sahip='? (tek-yazar ATANMAMIŞ — atanana dek robotlar bu tabloya yazamaz sayılır)'
  if($ALANMAP.ContainsKey($t)){ $alan=$ALANMAP[$t][0]; $sahip=$ALANMAP[$t][1] }
  else{
    foreach($d in $ALANDESEN){ if($t -match $d[0]){ $alan=$d[1]; $sahip=$d[2]; break } }
  }
  $satirlar.Add([pscustomobject]@{tablo=$t;alan=$alan;sahip=$sahip;kayit=$sayi})
  Write-Host ("  {0,-28} {1,10}  {2}" -f $t,$sayi,$alan)
}

$ozet=[ordered]@{
  uretim=(Get-Date -Format 'dd.MM.yyyy HH:mm')
  tablo_sayisi=$tablolar.Count
  sahipsiz=@($satirlar | ? { $_.alan -eq '?' }).Count
  gizlilik='Bu dosya SADECE metadata tasir (sayi/tarih/durum); icerik asla. Dosya gitignore duvari icindedir - repoya/dis dunyaya CIKMAZ. Mevzuat katmani ayri ve kamuya aciktir (veri/AMBAR-ENVANTERI.md).'
  kural='Site alanlariyla ilgili VAR/YOK-SAYI sorusunun cevabi bu katalogdan verilir; SAGLIK kolonu nobetci baglanana dek OLCULMEDI okunur.'
  satirlar=$satirlar.ToArray()
}
[IO.File]::WriteAllText((Join-Path $kok 'veri\fabrika\veri-katalogu.json'),(ConvertTo-Json -InputObject $ozet -Depth 4),[Text.UTF8Encoding]::new($false))

$sb=[Text.StringBuilder]::new()
[void]$sb.AppendLine('# VERİ KATALOĞU — SİTE ALANLARI (GİZLİ KATMAN)')
[void]$sb.AppendLine('')
[void]$sb.AppendLine("> Üretim: **$($ozet.uretim)** (makine: `motor/veri-katalogu.ps1`; günlük görev tazeler). İçerik değil METADATA — yine de kayıt sayıları rakip istihbaratıdır: bu dosya gitignore duvarının içindedir, DIŞARI ÇIKMAZ. Mevzuat/standart katmanı ayrı ve kamuya açık: `veri/AMBAR-ENVANTERI.md`.")
[void]$sb.AppendLine('')
[void]$sb.AppendLine('| Tablo | Alan | Tek yazarı | Kayıt (canlı) | Sağlık |')
[void]$sb.AppendLine('|---|---|---|---:|---|')
foreach($x in $satirlar){
  [void]$sb.AppendLine("| $($x.tablo) | $($x.alan) | $($x.sahip) | $($x.kayit) | ÖLÇÜLMEDİ (nöbetçi bağlanacak) |")
}
[IO.File]::WriteAllText((Join-Path $kok 'veri\fabrika\VERI-KATALOGU.md'),$sb.ToString(),[Text.UTF8Encoding]::new($false))
""
"KATALOG: $($tablolar.Count) tablo | sahipsiz: $($ozet.sahipsiz) -> veri/fabrika/VERI-KATALOGU.md + veri-katalogu.json"
