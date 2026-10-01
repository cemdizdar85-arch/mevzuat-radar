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
  01.10: + üye hesapları (auth.users, Admin API, ŞİFRE ÖZETSİZ) → auth-users-<damga>.ndjson, 90 gün.
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

  # ── ÜYE HESAPLARI (auth.users) — 01.10.2026, Cem "yol A ekle" ──────────────────────
  # auth şeması PostgREST'te yok; Supabase Auth Admin API'den okunur (servis anahtarı).
  # ⚠ ŞİFRE ÖZETİ GELMEZ (01.10 ölçüldü: alanlar id, email, tarihler, app/user_metadata,
  #   identities — password YOK). Felaket günü üyeler geri kurulur ama şifre yenilemesi gerekir.
  # 🚫 GÖRMEZ: şifre özetleri (tam döküm = Yol B, Supabase CLI + DB şifresi, ayrı iş) ·
  #   geri kurarken AYNI kimlik numarasının verilip verilemeyeceği (belgeden doğrulanmadı).
  $AUTH_ANAHTAR = "$($env:SUPABASE_SERVICE_KEY)".Trim()
  if(-not $AUTH_ANAHTAR){ $AUTH_ANAHTAR = "$([Environment]::GetEnvironmentVariable('SUPABASE_SERVICE_KEY','User'))".Trim() }
  # PS 5.1 varsayılan User-Agent "Mozilla" → sb_secret anahtar 401 (30.09 ölçüldü)
  $AUTH_BASLIK = @{ apikey=$AUTH_ANAHTAR; Authorization="Bearer $AUTH_ANAHTAR"; 'User-Agent'='mevzuat-radar-robot/1.0' }
  $authDamga = Get-Date -Format 'yyyyMMdd-HHmm'
  $authHedef = Join-Path $KISI_YEDEK_KOK "auth-users-$authDamga.ndjson"
  $authYazici = New-Object System.IO.StreamWriter($authHedef, $false, (New-Object Text.UTF8Encoding $false))
  $authSayac = 0; $authSayfa = 1; $AUTH_SAYFA_BOYU = 500
  try {
    while($true){
      $yanit = Invoke-RestMethod -Uri ("https://bjrleanjpyujtajmazxn.supabase.co/auth/v1/admin/users?page={0}&per_page={1}" -f $authSayfa, $AUTH_SAYFA_BOYU) -Headers $AUTH_BASLIK -TimeoutSec 120
      # ⛔ PS 5.1 dizi sarma tuzağı: ForEach-Object ile aç (01.10 yedek-geri-yazma-provasi dersi)
      $uyeler = @($yanit.users | ForEach-Object { $_ })
      foreach($u in $uyeler){ $authYazici.WriteLine(($u | ConvertTo-Json -Depth 20 -Compress)); $authSayac++ }
      if($uyeler.Count -lt $AUTH_SAYFA_BOYU){ break }
      $authSayfa++
    }
  } finally { $authYazici.Close(); $authYazici.Dispose() }
  # Boş üye listesi = sessiz arıza sayılır (01.10'da 8 üye vardı); dosya yazıldı ama alarm düşülür.
  if($authSayac -eq 0){ GunlukYaz "UYARI: auth.users 0 uye dondu - Admin API ya da anahtar sorunlu olabilir" }
  GunlukYaz ("UYE HESAPLARI: {0} uye -> {1}" -f $authSayac, (Split-Path $authHedef -Leaf))
  $authEsik = (Get-Date).AddDays(-90)
  @(Get-ChildItem $KISI_YEDEK_KOK -File -Filter 'auth-users-*.ndjson' | Where-Object { $_.LastWriteTime -lt $authEsik }) | ForEach-Object { Remove-Item $_.FullName -Force }
} catch {
  GunlukYaz ("HATA: " + $_.Exception.Message)
  exit 1
}
