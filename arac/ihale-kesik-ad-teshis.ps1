# ============================================================================
#  KESİK FİRMA ADI TEŞHİSİ — "onarım nereden başlar?"
#
#  NEDEN VAR (30.08.2026): Kasada 107 yüklenici adı JENERİK bir şirket ekiyle
#  BAŞLIYOR ("Ticaret Limited Şirketi", "Sanayi ve Ticaret Anonim Şirketi").
#  Firmanın ÖZEL ADI kayıp — sitede 1.380 ihalenin yüklenicisi yanlış görünüyor.
#
#  ONARIM İÇİN HAM METİN LAZIM ve kasada YOK: `ihale_dokum` yalnız ayrıştırılmış
#  alanları tutuyor (yuklenici, ikn, bulten_tarih...). Ham blok bültenin
#  kendisinde. Yani onarım = ilgili bültenleri yeniden indirip yeniden ayrıştırmak.
#
#  BU BETİK ONARMAZ. Onarımın MALİYETİNİ ölçer:
#    · kaç ayrı bülten indirilecek (tarih başına bir indirme)
#    · hangi yıllara yayılıyor (eski bülten hâlâ iniyor mu?)
#    · kesik adların IKN'leri hangi bültende
#  Çıktı, onarım turunun iş listesidir.
#
#  ⚠ USER-AGENT ZORUNLU: yeni biçim gizli anahtarda Supabase, PowerShell'in
#  varsayılan "Mozilla/..." UA'sını TARAYICI sayıp 401 döndürüyor
#  ("Forbidden use of secret API key in browser"). 30.08'de bu 401 yanlışlıkla
#  "anahtarın yetkisi yok" diye okundu. Yetki değil, başlık eksikliğiymiş.
# ============================================================================
param([switch]$Yaz)

$ErrorActionPreference = 'Continue'
$KOK = Split-Path $PSScriptRoot -Parent
. (Join-Path $PSScriptRoot 'rapor-yaz.ps1')
$SB_URL = 'https://bjrleanjpyujtajmazxn.supabase.co'

function Katla([string]$s){
  if(-not $s){ return '' }
  return $s.Replace([char]0x0130,'I').Replace([char]0x0131,'i').Replace([char]0x015E,'S').Replace([char]0x015F,'s').
           Replace([char]0x011E,'G').Replace([char]0x011F,'g').Replace([char]0x00DC,'U').Replace([char]0x00FC,'u').
           Replace([char]0x00D6,'O').Replace([char]0x00F6,'o').Replace([char]0x00C7,'C').Replace([char]0x00E7,'c')
}

# Jenerik şirket eki: ad BUNUNLA BAŞLIYORSA özel adı kayıptır.
# "Mehmet Yılmaz" gibi şahıs firmaları kısa olabilir - kısalık kusur DEĞİLDİR.
$JENERIK = '^(ticaret|sanayi|ithalat|ihracat|insaat|danismanlik|limited|anonim|nakliyat|turizm|otomotiv|elektrik|gida|tekstil|saglik|temizlik|guvenlik|bilgisayar|muhendislik|mimarlik|proje|taahhut|pazarlama|dagitim|lojistik|enerji|madencilik|tarim|hayvancilik|orman|egitim|yayincilik|reklam|organizasyon|yemek|catering|akaryakit|petrol|kimya|plastik|metal|demir|celik|makina|makine|hizmetleri|ve )'

function KesikMi([string]$ad){
  $a = (Katla "$ad").ToLowerInvariant().Trim()
  if(-not $a){ return $false }
  return [bool]($a -match $JENERIK)
}

# --- ÖZ-SINAV (93 kapı kuralı): ölçmeden önce kendini sına ---------------
$SINAV = @(
  @{ ad='Ticaret Limited Şirketi';                     b=$true  },
  @{ ad='Sanayi ve Ticaret Anonim Şirketi';            b=$true  },
  @{ ad='İren Makina Sanayi Limited Şirketi';          b=$false },
  @{ ad='Mehmet Yılmaz';                               b=$false },
  @{ ad='Öz Anadolu Nakliyat Limited Şirketi';         b=$false },
  @{ ad='İthalat İhracat Limited Şirketi';             b=$true  }
)
$kotu = @($SINAV | Where-Object { (KesikMi $_.ad) -ne $_.b })
if($kotu.Count){
  Write-Host "OZ-SINAV DUSTU - olcum YAPILMADI:" -ForegroundColor Red
  $kotu | ForEach-Object { Write-Host ("  '{0}' -> beklenen {1}" -f $_.ad, $_.b) -ForegroundColor Red }
  exit 2
}
Write-Host ("OZ-SINAV: {0}/{0} gecti." -f $SINAV.Count) -ForegroundColor Green

# --- kasadan oku ---------------------------------------------------------
$anahtar = "$($env:SUPABASE_SERVICE_KEY)".Trim()
if(-not $anahtar){ Write-Host "SUPABASE_SERVICE_KEY yok - olcum yapilamaz." -ForegroundColor Red; exit 1 }
$H = @{ apikey=$anahtar; Authorization="Bearer $anahtar"; 'Content-Type'='application/json'
        Accept='application/json'; 'User-Agent'='MevzuatRadar-KesikAdTeshis' }

# 🔴 30.08 KUSURU (kendi uzerimde goruldu): bu dongu okuma koptugunda
# `break` deyip DEVAM EDIYORDU. 56.268 kaydin 23.000'i okunmus, betik
# "KESIK: 692" yazmisti - dogru sayi 1.972 idi. Yani yarim okuma TAM
# okuma gibi rapor ediliyordu. Artik: her sayfa 3 kez denenir, yine
# kopuyorsa olcum YAPILMAMIS sayilir, rapor YAZILMAZ.
$hepsi = New-Object Collections.ArrayList
$offset = 0
$kirik = $false
while($true){
  $govde = @{ p_offset=$offset; p_limit=1000 } | ConvertTo-Json -Compress
  $cevap = $null; $sonHata = ''
  for($deneme=1; $deneme -le 3; $deneme++){
    try {
      $cevap = Invoke-RestMethod -Method Post -Uri "$SB_URL/rest/v1/rpc/ihale_dokum" `
                 -Headers $H -Body ([Text.Encoding]::UTF8.GetBytes($govde)) -TimeoutSec 300
      break
    } catch { $sonHata = $_.Exception.Message; Start-Sleep -Seconds (2*$deneme) }
  }
  if($null -eq $cevap){
    Write-Host ("`n  KOPTU (offset {0}, 3 deneme): {1}" -f $offset, $sonHata) -ForegroundColor Red
    $kirik = $true; break
  }
  # TUZAK: Invoke-RestMethod diziyi TEK OGEYE sariyor - bir kat duzlestir.
  $duz = @(); foreach($z in @($cevap)){ if($z -is [Array]){ $duz += $z } else { $duz += $z } }
  if(-not $duz.Count){ break }
  [void]$hepsi.AddRange($duz)
  $offset += 1000
  Write-Host ("`r  okunan: {0:N0}" -f $hepsi.Count) -NoNewline
}
Write-Host ""
if($kirik -or -not $hepsi.Count){
  Write-Host ("  OLCUM YAPILAMADI - kasa TAM okunamadi ({0:N0} kayitta koptu)." -f $hepsi.Count) -ForegroundColor Red
  Write-Host "  Rapor YAZILMADI - yarim okumadan 'kusur sayisi' cikarilmaz." -ForegroundColor Yellow
  exit 1
}
Write-Host ("KASA: {0:N0} kayit okundu." -f $hepsi.Count) -ForegroundColor Green

# --- kesik adlari ayikla -------------------------------------------------
$kesik = @($hepsi | Where-Object { $_.yuklenici -and (KesikMi $_.yuklenici) })
Write-Host ("KESIK AD: {0:N0} ihale kaydi" -f $kesik.Count) -ForegroundColor $(if($kesik.Count){'Yellow'}else{'Green'})

$adlar = @($kesik | Group-Object yuklenici | Sort-Object Count -Descending)
Write-Host ("TEKIL KESIK AD: {0}" -f $adlar.Count)

# --- onarim maliyeti: kac ayri bulten? -----------------------------------
$bultenli   = @($kesik | Where-Object { $_.bulten_tarih })
$bultensiz  = $kesik.Count - $bultenli.Count
$bultenler  = @($bultenli | Group-Object bulten_tarih | Sort-Object Name)
$yillar     = @($bultenli | Group-Object { "$($_.bulten_tarih)".Substring(0,4) } | Sort-Object Name)

Write-Host ""
Write-Host "=== ONARIM MALIYETI ===" -ForegroundColor Cyan
Write-Host ("  indirilecek AYRI bulten : {0}" -f $bultenler.Count)
Write-Host ("  bulten tarihi OLMAYAN   : {0}  (bunlar bultenden onarilamaz)" -f $bultensiz) -ForegroundColor $(if($bultensiz){'Yellow'}else{'Green'})
Write-Host "  yil dagilimi:"
$yillar | ForEach-Object { Write-Host ("    {0} : {1,5} kayit" -f $_.Name, $_.Count) }

Write-Host ""
Write-Host "=== EN COK GECEN 10 KESIK AD ===" -ForegroundColor Cyan
$adlar | Select-Object -First 10 | ForEach-Object { Write-Host ("  {0,5}  {1}" -f $_.Count, $_.Name) }

# --- ONARIM KOMUTU -------------------------------------------------------
# Onarim AYRI bir cikariciyla YAPILMAZ. 30.08'de denendi ve dustu: KISIMLI
# ihalede bir IKN'nin BIRDEN COK yuklenicisi var (her kisma bir sozlesme),
# "IKN -> tek ad" modeli 1.295 kaydi yanlis eslestirdi. Dogru anahtar
# IKN+sozlesme; onu zaten uretimdeki ayristirici cikariyor. Bu yuzden onarim
# = ayni gunu backfill'e yeniden isletmek.
if($bultenler.Count){
  $liste = (@($bultenler | ForEach-Object { $_.Name }) -join ',')
  Write-Host ""
  Write-Host "=== ONARIM KOMUTU (bu gunler bugunun ayristiricisiyla yeniden islenir) ===" -ForegroundColor Cyan
  Write-Host ("  ./motor/ihale-sonuc-backfill.ps1 -Gunler '{0}'" -f $liste) -ForegroundColor Green
  Write-Host "  (once -Olc ile kuru kosu yapilabilir: hicbir sey yazilmaz)" -ForegroundColor DarkGray
}

$cikti = [pscustomobject]@{
  olcum    = (Get-Date -Format 'dd.MM.yyyy HH:mm')
  aciklama = "Kesik yuklenici adlarinin ONARIM MALIYETI. Kasa ham metni tutmuyor; onarim, ilgili bultenin yeniden indirilip yeniden ayristirilmasini gerektirir. Bu rapor o is listesidir. Olcut: ad JENERIK bir sirket ekiyle BASLIYOR - kisalik tek basina kusur degildir."
  kaynak   = "rpc/ihale_dokum"
  taranan  = $hepsi.Count
  kesik_kayit = $kesik.Count
  tekil_kesik_ad = $adlar.Count
  indirilecek_bulten = $bultenler.Count
  bulten_tarihi_olmayan = $bultensiz
  yil_dagilimi = @($yillar | ForEach-Object { [pscustomobject]@{ yil=$_.Name; kayit=$_.Count } })
  bulten_listesi = @($bultenler | ForEach-Object { [pscustomobject]@{ tarih=$_.Name; kayit=$_.Count; ikn=@($_.Group | ForEach-Object { $_.ikn }) } })
  adlar = @($adlar | ForEach-Object { [pscustomobject]@{ ad=$_.Name; kayit=$_.Count } })
}
if($Yaz){
  RaporYaz -Hedef (Join-Path $KOK 'veri\ihale-kesik-ad-teshis.json') -Nesne $cikti -Derinlik 6 | Out-Null
} else {
  Write-Host ""
  Write-Host "(olcum modu - rapor yazilmadi; yazmak icin -Yaz)" -ForegroundColor DarkGray
}
exit 0
