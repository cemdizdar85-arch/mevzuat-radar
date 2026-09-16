# ============================================================================
#  KGK SINAV NÖBETÇİSİ — yeni çıkmış soru kitapçığı yayımlandı mı?   16.09.2026
#  Cem "1.2.3 üçünüde yap" (GM 2).
#
#  NEDEN VAR: çıkmış sınav karnesinde KGK "evren"i resmî liste değil DİSKTEKİ dosya sayısıydı; resmî bağlantı listesi
#  (veri/kgk-arsiv/pdf-links.tsv) 08.05.2026'dan beri tazelenmedi, 27.06.2026 kitapçığı elle eklendi. Kasım 2026 sınavı
#  yayımlandığında bunu bize söyleyen hiçbir şey yoktu — en yeni sınav kalıbı en değerli veridir.
#
#  NE YAPAR (bedel 0, model yok):
#   - KGK Soru Arşivi sayfasını okur (https://kgk.gov.tr/DynamicContentDetail/5237/Soru-Arşivi); her girdi
#     data-href='/DynamicContentDetail/<kod>/…' ya da '/ContentAssignmentDetail/<kod>/…' (bizde "ca<kod>") taşır.
#   - Bilinen küme = AMBAR: tur='cikmis-soru' ve adı "CIKMIS SINAV - KGK…" olan belgelerin parantezindeki dosya kökünün kodu
#     ("(10202_A_KİTAPÇIĞI…)" → 10202, "(ca4695_…)" → ca4695). Yani kitapçık AMBARA YUTULANA kadar "YENİ" kalır.
#   - Sonuç: YEŞİL (yeni yok) · KIRMIZI (yeni kitapçık var → çıkış 1, iş akışı Cem'e mail atar) ·
#     KÖR (sayfa inmedi / hiç girdi ayrıştırılamadı / ambar okunamadı → çıkış 2; sessiz yeşil YOK).
#   - Rapor: veri/kgk-sinav-nobeti.json (RaporYaz; içerik aynıysa dokunmaz).
#  Yeni kitapçık çıkınca (yerelde): powershell -NoProfile -File arac/kgk-yeni-sinav-yut.ps1 -Yaz  (indir → ayrıştır → ambara yut → ölçümler).
#  Kullanım: pwsh ./motor/kgk-sinav-nobeti.ps1   (yerelde: powershell -NoProfile -File motor/kgk-sinav-nobeti.ps1)
# ============================================================================
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$depoKok = Split-Path -Parent $PSScriptRoot
. (Join-Path (Join-Path $depoKok 'arac') 'rapor-yaz.ps1')
$raporYolu = Join-Path (Join-Path $depoKok 'veri') 'kgk-sinav-nobeti.json'
$sayfaAdresi = 'https://kgk.gov.tr/DynamicContentDetail/5237/Soru-Ars%CC%A7ivi'

function RaporuYaz([string]$durum, [string]$neden, $girdiler, $yeniler, [int]$bilinenSayisi){
  $girdiDizisi = @(); foreach($g in $girdiler){ $girdiDizisi += $g }   # List[object] @() ile sarılmaz (K3)
  $yeniDizisi = @(); foreach($g in $yeniler){ $yeniDizisi += $g }
  $rapor = [ordered]@{
    olcum = (Get-Date).ToUniversalTime().AddHours(3).ToString('dd.MM.yyyy HH:mm')
    durum = $durum
    neden = $neden
    sayfa = $sayfaAdresi
    kural = 'YENİ = sayfada olup ambarda (tur=cikmis-soru, "CIKMIS SINAV - KGK …") dosya kökü kodu bulunmayan sınav girdisi. KÖR = sayfa/ambar okunamadı ya da girdi ayrıştırılamadı.'
    sayfadaki_sinav = $girdiDizisi.Count
    ambarda_bilinen_kod = $bilinenSayisi
    yeni = @($yeniDizisi | ForEach-Object { [ordered]@{ kod=$_.kod; ad=$_.ad; adres=$_.adres } })
    sayfadakiler = @($girdiDizisi | ForEach-Object { [ordered]@{ kod=$_.kod; ad=$_.ad; adres=$_.adres } })
  }
  [void](RaporYaz -Hedef $raporYolu -Nesne $rapor -Sessiz)
}

# --- 1) sayfa
$html = ''
foreach($deneme in 1..3){
  try {
    $yanit = Invoke-WebRequest -UseBasicParsing -Uri $sayfaAdresi -UserAgent 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)' -TimeoutSec 90
    $html = "$($yanit.Content)"; break
  } catch { Write-Host "  sayfa denemesi $deneme düştü: $($_.Exception.Message)"; Start-Sleep -Seconds (5 * $deneme) }
}
if(-not $html){ Write-Host 'KÖR: KGK Soru Arşivi sayfası inmedi.'; RaporuYaz 'KÖR' 'sayfa inmedi' @() @() 0; exit 2 }

$girdiler = New-Object System.Collections.Generic.List[object]
$gorulen = @{}
foreach($es in [regex]::Matches($html,"data-href='/(DynamicContent|ContentAssignment)Detail/(\w+)/[^']*'.*?link-title'>([^<]+)<", [Text.RegularExpressions.RegexOptions]::Singleline)){
  $ad = [Net.WebUtility]::HtmlDecode($es.Groups[3].Value).Trim()
  if($ad -notmatch '(?i)s[ıi]nav'){ continue }
  $kod = if($es.Groups[1].Value -eq 'ContentAssignment'){ 'ca' + $es.Groups[2].Value } else { $es.Groups[2].Value }
  if($gorulen.ContainsKey($kod)){ continue }; $gorulen[$kod] = 1
  # 16.09: sayfa adresi BAŞLIK KISMIYLA (slug) tutulur — başlıksız adres KGK'da hata sayfası döndürür (arac/kgk-yeni-sinav-yut.ps1 bu adresi okur)
  $tamYol = [regex]::Match($es.Value,"data-href='(/[^']+)'").Groups[1].Value
  $girdiler.Add([pscustomobject]@{ kod=$kod; ad=$ad; adres=('https://kgk.gov.tr' + $tamYol) })
}
# Beklenen alt sınır: 16.09.2026'da sayfada 21 sınav girdisi vardı. Bir anda çok azalırsa sayfa düzeni değişmiştir → KÖR.
if($girdiler.Count -lt 10){ Write-Host "KÖR: sayfada yalnız $($girdiler.Count) sınav girdisi ayrıştırıldı (düzen değişmiş olabilir)."; RaporuYaz 'KÖR' "ayrıştırılan girdi $($girdiler.Count) (<10)" $girdiler @() 0; exit 2 }

# --- 2) ambar
$sbAnahtar = $env:SUPABASE_SERVICE_KEY
if(-not $sbAnahtar){ $sbAnahtar = [Environment]::GetEnvironmentVariable('SUPABASE_SERVICE_KEY','User') }
if(-not $sbAnahtar){ Write-Host 'KÖR: SUPABASE_SERVICE_KEY yok.'; RaporuYaz 'KÖR' 'ambar anahtarı yok' $girdiler @() 0; exit 2 }
$sbBasliklar = @{ apikey=$sbAnahtar; Authorization="Bearer $sbAnahtar"; 'User-Agent'='mevzuat-radar-robot/1.0' }
$bilinen = New-Object System.Collections.Generic.HashSet[string]
try {
  $adres = 'https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/dokumanlar?select=kaynak_ad&tur=eq.cikmis-soru&kaynak_ad=like.' + [uri]::EscapeDataString('CIKMIS SINAV - KGK*') + '&order=kaynak_ad&limit=1000'
  foreach($kayit in (Invoke-RestMethod -Uri $adres -Headers $sbBasliklar -TimeoutSec 120)){
    $kokEs = [regex]::Match("$($kayit.kaynak_ad)",'\((\w+?)_')
    if($kokEs.Success){ [void]$bilinen.Add($kokEs.Groups[1].Value) }
  }
} catch { Write-Host "KÖR: ambar okunamadı: $($_.Exception.Message)"; RaporuYaz 'KÖR' 'ambar okunamadı' $girdiler @() 0; exit 2 }
# Sınama: KGK_NOBET_SINAMA_DISLA='12103' verilirse o kod bilinmiyor sayılır (KIRMIZI yolunun provası; üretimde boş)
if($env:KGK_NOBET_SINAMA_DISLA){ foreach($dislanan in ($env:KGK_NOBET_SINAMA_DISLA -split ',')){ [void]$bilinen.Remove($dislanan.Trim()) } }
if($bilinen.Count -lt 10){ Write-Host "KÖR: ambarda yalnız $($bilinen.Count) KGK kodu bulundu."; RaporuYaz 'KÖR' "ambarda kod $($bilinen.Count) (<10)" $girdiler @() $bilinen.Count; exit 2 }

# --- 3) karar
$yeniler = @($girdiler | Where-Object { -not $bilinen.Contains($_.kod) })
Write-Host ("KGK Soru Arşivi: {0} sınav girdisi · ambarda bilinen kod {1} · YENİ {2}" -f $girdiler.Count,$bilinen.Count,$yeniler.Count)
if($yeniler.Count){
  foreach($y in $yeniler){ Write-Host "  YENİ: $($y.kod) · $($y.ad) · $($y.adres)" }
  RaporuYaz 'KIRMIZI' "yeni kitapçık: $(@($yeniler | ForEach-Object { $_.ad }) -join ' | ')" $girdiler $yeniler $bilinen.Count
  exit 1
}
RaporuYaz 'YEŞİL' 'sayfadaki bütün sınavlar ambarda' $girdiler @() $bilinen.Count
Write-Host 'YEŞİL'
exit 0
