# ============================================================================
#  KAYNAK DAMGASI (19.08.2026 - Cem karari: "yap")
#
#  SORUN: kartlar.yml'de BUGUN her kosuda yeniden isleniyordu. Gerekcesi
#  dogruydu (ogleden sonra cikan mukerrer sayilar kacmasin) ama yan etkisi
#  19.08'de canli goruldu: ayni teblig her kosuda modele yeniden okutuldu,
#  BASLIK her seferinde baska kelimelerle yazildi ve vitrin oynadi
#  (ayni okul karti bir kosuda 'Ihale Yonetmeliginde...' olup vitrine cikti,
#  sonraki kosuda baska baslikla dustu). Ustelik her kosu bosuna API harciyor.
#
#  COZUM: gunun INDIRILMIS teblig dosyalarindan icerik damgasi (SHA256)
#  uretilir ve kart klasorune yazilir. Bugun aday olmaya devam eder, ama
#  uretim yalniz damga DEGISTIYSE kosar. Ogleden sonra mukerrer teblig
#  inince dosya listesi degisir -> damga degisir -> uretim yine tetiklenir.
#  Kapsama aynen korunur, oynama ve bosuna maliyet biter.
#
#  Damga yoksa (bu degisiklikten onceki gunler) DEGISMIS sayilir: gun bir
#  kez daha islenir ve damgasini yazar - kendi kendini onarir.
# ============================================================================

# PS TUZAGI: [System.IO.File] goreli yolu PowerShell'in dizinine gore DEGIL,
# .NET surecinin calisma dizinine gore cozer (Set-Location ikisini ayirir).
# Cagiranlar bazen goreli yol veriyor (workflow: motor/kartlar/<gun>), bu yuzden
# her yol burada mutlaklastirilir - yoksa dosya yanlis yere yazilir/okunamaz.
function DamgaTamYol([string]$y){
  if(-not $y){ return $y }
  if([System.IO.Path]::IsPathRooted($y)){ return $y }
  return (Join-Path (Get-Location).Path $y)
}

# Gunun arsiv klasorundeki .htm dosyalarinin ADI+ICERIGI uzerinden damga.
# Icerik hash'lenir: RG ayni adla farkli icerik yayimlarsa da yakalanir.
function KaynakDamgasi([string]$arsivKlasoru){
  $arsivKlasoru = DamgaTamYol $arsivKlasoru
  if(-not (Test-Path $arsivKlasoru)){ return "" }
  $dosyalar = @(Get-ChildItem $arsivKlasoru -Filter *.htm -ErrorAction SilentlyContinue | Sort-Object Name)
  if(-not $dosyalar.Count){ return "" }
  $ms = New-Object System.IO.MemoryStream
  try {
    foreach($d in $dosyalar){
      $ad = [System.Text.Encoding]::UTF8.GetBytes($d.Name + "|")
      $ms.Write($ad, 0, $ad.Length)
      $ic = [System.IO.File]::ReadAllBytes($d.FullName)
      $ms.Write($ic, 0, $ic.Length)
    }
    $ms.Position = 0
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try { $h = $sha.ComputeHash($ms) } finally { $sha.Dispose() }
  } finally { $ms.Dispose() }
  return (([BitConverter]::ToString($h)) -replace '-','').ToLowerInvariant()
}

function KaynakDamgaYolu([string]$kartKlasoru){ return (Join-Path (DamgaTamYol $kartKlasoru) 'kaynak-damga.json') }

function KaynakDamgaOku([string]$kartKlasoru){
  $y = KaynakDamgaYolu $kartKlasoru
  if(-not (Test-Path $y)){ return "" }
  try {
    $o = ConvertFrom-Json -InputObject ([System.IO.File]::ReadAllText($y, [System.Text.Encoding]::UTF8))
    return "$($o.damga)"
  } catch { return "" }
}

function KaynakDamgaYaz([string]$kartKlasoru, [string]$damga, [int]$dosyaSayisi){
  if(-not $damga){ return }
  $y = KaynakDamgaYolu $kartKlasoru
  $o = [ordered]@{
    damga        = $damga
    dosya_sayisi = $dosyaSayisi
    yazildi      = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
    aciklama     = 'Bu gun bu teblig dosyalariyla uretildi. Damga degismedikce yeniden uretilmez.'
  }
  [System.IO.File]::WriteAllText($y, ($o | ConvertTo-Json), (New-Object System.Text.UTF8Encoding($true)))
}

# Gun yeniden islenmeli mi? (arsivde teblig varsa ve damga tutmuyorsa EVET)
function KaynakDegistiMi([string]$arsivKlasoru, [string]$kartKlasoru){
  $simdi = KaynakDamgasi $arsivKlasoru
  if(-not $simdi){ return $false }          # islenecek teblig yok
  return ($simdi -ne (KaynakDamgaOku $kartKlasoru))
}
