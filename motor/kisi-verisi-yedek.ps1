#requires -Version 5.1
<#
  KİŞİ VERİSİ YEREL YEDEĞİ — zamanlanmış görev sarmalayıcısı (30.09.2026, Cem "1 yap")

  Görev: TETIKTE-KisiVerisiYedek (her gün 03:30, kaçırılırsa açılışta; pilde de koşar).
  Üye / ödeme / marka müşteri tabloları (liste: soru-ambar-yedek.ps1 $KISI) buluta
  GİRMEZ (CLAUDE.md bulut güvenliği m.4) → yalnız bu makinede, OneDrive DIŞINDA:
  C:\TETIKTE-YEDEK\kisi-verisi\  (90 gün saklanır; budama yalnız TAM yedekten sonra).

  ⚠ Bu yedek ana veriyle AYNI diskte. Makine giderse bu da gider; tek başına felaket
     kurtarma DEĞİLDİR. Supabase'in 7 günlük fiziksel yedeğiyle birlikte düşünülür.
  Her koşu yedek-log.txt'ye bir satır yazar; sessiz düşme olmasın diye hata da yazılır.
#>
$ErrorActionPreference = 'Stop'
$KISI_YEDEK_KOK = 'C:\TETIKTE-YEDEK\kisi-verisi'
$KISI_GUNLUK = Join-Path $KISI_YEDEK_KOK 'yedek-log.txt'
New-Item -ItemType Directory -Force $KISI_YEDEK_KOK | Out-Null
function GunlukYaz([string]$satir){ Add-Content -Path $KISI_GUNLUK -Value ("{0}  {1}" -f (Get-Date -Format 'dd.MM.yyyy HH:mm'), $satir) -Encoding UTF8 }

GunlukYaz ("basladi (kullanici={0})" -f $env:USERNAME)
try {
  $cikti = & (Join-Path $PSScriptRoot 'soru-ambar-yedek.ps1') -Kume Kisi -Kok $KISI_YEDEK_KOK -SaklaGun 90 *>&1
  $ozet = @($cikti | ForEach-Object { "$_" } | Where-Object { $_ -match 'TOPLAM:|budandi' })
  foreach($o in $ozet){ GunlukYaz $o.Trim() }
} catch {
  GunlukYaz ("HATA: " + $_.Exception.Message)
  exit 1
}
