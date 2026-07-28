# ============================================================================
#  DERS ETIKETI DUZELTICISI — 29.07.2026   (PARA HARCAMAZ)
#
#  SORUN: kasa sayimi ETIKET KAYMASI gosterdi. Ayni sinavin icinde ayni ders
#  IKI FARKLI ADLA duruyor:
#     SGS|Finansal Muhasebe 656  +  SGS|Muhasebe 93
#     SGS|Matematik-Istatistik 56 +  SGS|Matematik 16
#     SMMM|Finansal Muhasebe 30   +  SMMM|Muhasebe 18
#  Quiz motoru bunlari AYRI DERS sanar: ogrenci 'Muhasebe' secer, 93 soru
#  gorur, 656'yi HIC GORMEZ. Yani parasi odenmis sorularin bir kismi
#  ogrenciye ulasmiyor - kayip degil ama erisilmez.
#
#  DOGRU AD NEREDEN: kafadan degil, resmi kaynaktan.
#  SGS  -> TESMER Uygulama Yonergesi m.6.2 tablosu (veri/sgs-sinav-yapisi.json)
#  SMMM -> Sinav Yonetmeligi m.14 ders listesi (ayni dosya, 'yeterlilik')
#
#  YALNIZ KESIN OLANLAR: bir etiketi kortlemesine baska bir derse tasimak,
#  sorunun konusunu degistirmek olur. Bu betik SADECE ayni dersin iki adi
#  oldugu kesin vakalari birlestirir. Belirsiz olanlar (SGS|Hukuk 130,
#  SGS|Genel Kultur-Genel Yetenek 131) ELLENMEZ - onlar soru soru
#  siniflandirilmali, ayri is.
# ============================================================================
param(
  [switch]$yaz   # varsayilan: yalniz olcum
)
$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$SB_URL = "https://bjrleanjpyujtajmazxn.supabase.co"

$KEY = $env:SUPABASE_SERVICE_KEY
if(-not $KEY){ Write-Host "SUPABASE_SERVICE_KEY yok - atlandi."; exit 0 }
$H  = @{ apikey=$KEY; Authorization="Bearer $KEY" }
$HW = $H + @{ Prefer="return=minimal" }

# --- KURALLAR: sinav | eski ders adi -> resmi ders adi
$KURAL = @(
  @{ sinav='SGS';  eski='Muhasebe';             yeni='Finansal Muhasebe'
     dayanak='TESMER Uygulama Yonergesi m.6.2: Alan Bilgisi bolumunde ders adi "Finansal Muhasebe" (26 soru). "Muhasebe" ayri bir ders degil.' }
  @{ sinav='SGS';  eski='Matematik-Istatistik'; yeni='Matematik'
     dayanak='TESMER Uygulama Yonergesi m.6.2: Genel Kultur ve Yetenek bolumunde ders adi "Matematik" (8 soru).' }
  @{ sinav='SMMM'; eski='Muhasebe';             yeni='Finansal Muhasebe'
     dayanak='Sinav Yonetmeligi m.14: Yeterlilik derslerinden biri "Finansal Muhasebe". "Muhasebe" diye ayri ders yok.' }
)

function Say($sinav,$ders){
  $u = "$SB_URL/rest/v1/soru_havuzu?select=id&sinav=eq." + [uri]::EscapeDataString($sinav) + "&ders=eq." + [uri]::EscapeDataString($ders) + "&limit=1"
  try { $r = Invoke-WebRequest -UseBasicParsing -Uri $u -Headers ($H + @{Prefer='count=exact'}) -TimeoutSec 60 } catch { return -1 }
  return [int](($r.Headers['Content-Range'] -split '/')[-1])
}

Write-Host "DERS ETIKETI DUZELTICISI"
$rapor = New-Object System.Collections.Generic.List[object]
$toplamTasinan = 0
foreach($k in $KURAL){
  $once   = Say $k.sinav $k.eski
  $hedefO = Say $k.sinav $k.yeni
  Write-Host ""
  Write-Host ("  {0} | '{1}' -> '{2}'" -f $k.sinav, $k.eski, $k.yeni)
  Write-Host ("     {0}" -f $k.dayanak)
  Write-Host ("     tasinacak: {0}   hedefte simdi: {1}" -f $once, $hedefO)
  if($once -le 0){ Write-Host "     (yapilacak is yok)"; continue }

  if($yaz){
    $u = "$SB_URL/rest/v1/soru_havuzu?sinav=eq." + [uri]::EscapeDataString($k.sinav) + "&ders=eq." + [uri]::EscapeDataString($k.eski)
    $govde = @{ ders = $k.yeni } | ConvertTo-Json -Compress
    try {
      Invoke-RestMethod -Method Patch -Uri $u -Headers $HW -ContentType "application/json; charset=utf-8" `
        -Body ([Text.Encoding]::UTF8.GetBytes($govde)) -TimeoutSec 120 | Out-Null
    } catch { Write-Host ("     HATA: {0}" -f $_.Exception.Message); continue }

    # MUTABAKAT: eski etiket sifirlandi mi, hedef tam o kadar artti mi?
    # Depodaki ders: yesil kosu tam veri demek DEGIL. Sayarak bak.
    $sonra   = Say $k.sinav $k.eski
    $hedefS  = Say $k.sinav $k.yeni
    Write-Host ("     sonra: eski={0}  hedef={1} (beklenen {2})" -f $sonra, $hedefS, ($hedefO + $once))
    if($sonra -ne 0 -or $hedefS -ne ($hedefO + $once)){
      Write-Host "     KIRMIZI: mutabakat tutmadi."
      $rapor.Add([pscustomobject]@{ sinav=$k.sinav; eski=$k.eski; yeni=$k.yeni; tasinan=$once; durum='MUTABAKATSIZ' })
      continue
    }
    $toplamTasinan += $once
    $rapor.Add([pscustomobject]@{ sinav=$k.sinav; eski=$k.eski; yeni=$k.yeni; tasinan=$once; durum='tamam'; dayanak=$k.dayanak })
  } else {
    $rapor.Add([pscustomobject]@{ sinav=$k.sinav; eski=$k.eski; yeni=$k.yeni; tasinan=$once; durum='olcum' })
  }
}

Write-Host ""
Write-Host ("TOPLAM TASINAN: {0}" -f $toplamTasinan)
if(-not $yaz){ Write-Host "OLCUM MODU - kasaya yazilmadi. Yazmak icin -yaz." }

# --- ELLENMEYENLER: bunlar soru soru siniflandirilmali, kortlemesine tasinamaz
Write-Host ""
Write-Host "--- ELLENMEDI (soru soru siniflandirma gerektirir)"
foreach($x in @(@{s='SGS';d='Hukuk'}, @{s='SGS';d='Genel Kultur-Genel Yetenek'})){
  $n = Say $x.s $x.d
  Write-Host ("   {0}|{1}: {2} soru" -f $x.s, $x.d, $n)
}
Write-Host "   SGS'de 'Hukuk' diye tek bir ders YOK: Ticaret / Borclar / Is-SGK / Vergi / Meslek"
Write-Host "   olarak ayrilir. 'Genel Kultur-Genel Yetenek' de bir BOLUM adidir; icinde"
Write-Host "   Turkce, Matematik ve Ataturk Ilkeleri dersleri vardir. Bunlari kortlemesine"
Write-Host "   tek derse tasimak sorunun konusunu degistirir - yapilmaz."

[IO.File]::WriteAllText((Join-Path $kok 'veri/etiket-duzeltme.json'), ([ordered]@{
  tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); yazildi=[bool]$yaz; toplam_tasinan=$toplamTasinan; kurallar=$rapor
} | ConvertTo-Json -Depth 5), (New-Object Text.UTF8Encoding($false)))
Write-Host "-> veri/etiket-duzeltme.json"
exit 0
