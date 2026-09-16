# ============================================================================
#  TEK SAYFA GİRDİ KÜTÜĞÜ KAPISI   16.09.2026 (Cem "1 ve 2 yap", GM 2)
#
#  NEDEN VAR: motor/sinav-tek-sayfa.ps1'deki $GIRDILER kütüğü her girdi dosyasının "üreticisini" ve "robotunu" söyler.
#  16.09 elle denetimi 19 kayıttan 5'inin YANLIŞ olduğunu buldu; ikisinde kayıtlı üretici koşturulunca güncel dosyayı
#  başka biçimle EZİYORDU (kgk-analiz.json 29 dönem → 0; kopyadan geri yüklendi). Kütük yanlışsa "bayat girdiyi
#  tazele" talimatı veriyi bozar. Bu kapı elle yapılan denetimi her gün tekrarlar.
#
#  KURALLAR (her kayıt için):
#   Ü1  üretici alanında (motor|arac)/x.ps1 yoksa alan "elle" demeli.
#   Ü2  betik dosyası var olmalı.
#   Ü3  çıktı dosyasının adı betikte YA DA betiği çağıran robot iş akışında geçmeli (ortam değişkeniyle verilen çıktı).
#   Ü4  (JSON) güncel dosyanın üst düzey alan adlarının hepsi betikte geçmeli — yoksa betik dosyayı başka biçimle EZER.
#       Dinamik alanlı dosya için kütükte bicimDenetimi=$false.
#   R1  robot alanındaki her .yml dosyası var olmalı.
#   R2  robot alanı "yok" ya da "yan ürün" ile başlamıyorsa: ilk .yml üretici betiği çağırmalı VE çıktıyı commit'lemeli
#       (dosya adı ya da git add -A/./veri geçmeli).
#   R3  robot alanı "her gün" diyorsa iş akışında cron olmalı.
#  Çıkış: 0 temiz · 1 ihlal · 2 kütük okunamadı. Ağ yok, bedel 0. Öz-sınav: -Sinama (sahte kayıtlarla).
# ============================================================================
param([switch]$Sinama, [string]$TekSayfaYolu = '')   # TekSayfaYolu: başka bir sürümü denetlemek için (ör. git show ile alınmış eski kütük)
$ErrorActionPreference = 'Stop'
$depoKok = Split-Path -Parent $PSScriptRoot

function KayitDenetle($kayit){
  $bulgular = New-Object System.Collections.Generic.List[string]
  $yaprak = Split-Path ("$($kayit.yol)" -replace '\\','/') -Leaf
  $uretici = [regex]::Match("$($kayit.uretici)",'(motor|arac)/[\w\-]+\.ps1').Value
  $akislar = @([regex]::Matches("$($kayit.robot)",'[\w\-]+\.yml') | ForEach-Object { $_.Value })
  $akisMetinleri = @{}
  foreach($akis in $akislar){
    $akisYolu = Join-Path (Join-Path (Join-Path $depoKok '.github') 'workflows') $akis
    if(Test-Path $akisYolu){ $akisMetinleri[$akis] = [IO.File]::ReadAllText($akisYolu,[Text.Encoding]::UTF8) }
    else { $bulgular.Add("R1 robot iş akışı yok: $akis") }
  }
  if(-not $uretici){
    if("$($kayit.uretici)" -notmatch '(?i)elle'){ $bulgular.Add("Ü1 üretici betik yolu yok ve 'elle' denmemiş: '$($kayit.uretici)'") }
  } else {
    $betikYolu = Join-Path $depoKok $uretici
    if(-not (Test-Path $betikYolu)){ $bulgular.Add("Ü2 üretici betik yok: $uretici") }
    else {
      $betikMetni = [IO.File]::ReadAllText($betikYolu,[Text.Encoding]::UTF8)
      $akistaAdVar = @($akisMetinleri.Values | Where-Object { $_.Contains($yaprak) -and $_.Contains((Split-Path $uretici -Leaf)) }).Count -gt 0
      if(-not $betikMetni.Contains($yaprak) -and -not $akistaAdVar){ $bulgular.Add("Ü3 $uretici '$yaprak' dosyasını anmıyor (ne betikte ne onu çağıran iş akışında)") }
      # Ü4 BİÇİM: güncel JSON'un üst düzey alan adlarının HEPSİ betikte geçmeli. Geçmiyorsa betik dosyayı bu biçimde üretmiyordur
      #   ve koşturulursa EZER (16.09: kgk-siklik-derle → kgk-analiz 'donemler' yok; cikmis-soru-karnesi → 'komisyonCevabiBelgesi' yok).
      $dosyaYolu = Join-Path $depoKok ("$($kayit.yol)" -replace '\\','/')
      if($yaprak -like '*.json' -and (Test-Path $dosyaYolu) -and -not ($kayit.PSObject.Properties['bicimDenetimi'] -and -not $kayit.bicimDenetimi)){
        try {
          $icerik = Get-Content $dosyaYolu -Raw -Encoding UTF8 | ConvertFrom-Json
          if($icerik -and -not ($icerik -is [array])){
            $eksikAlan = @($icerik.PSObject.Properties.Name | Where-Object { $betikMetni -notmatch ('\b' + [regex]::Escape($_) + '\b') })
            if($eksikAlan.Count){ $bulgular.Add("Ü4 $uretici güncel dosyanın alanlarını üretmiyor ($($eksikAlan -join ', ')) — koşturulursa dosyayı başka biçimle ezer") }
          }
        } catch { $bulgular.Add("Ü4 '$yaprak' okunamadı: $($_.Exception.Message)") }
      }
    }
  }
  $robotMetni = "$($kayit.robot)".Trim()
  if($akislar.Count -and $robotMetni -notmatch '^(?i)(yok|yan ürün)' -and $akisMetinleri.ContainsKey($akislar[0])){
    $ilk = $akisMetinleri[$akislar[0]]
    if($uretici -and -not $ilk.Contains((Split-Path $uretici -Leaf))){ $bulgular.Add("R2 $($akislar[0]) üreticiyi ($uretici) çağırmıyor") }
    if(-not ($ilk.Contains($yaprak) -or $ilk -match 'git add (-A|\.|veri/?\s|veri/\*)')){ $bulgular.Add("R2 $($akislar[0]) '$yaprak' dosyasını commit'lemiyor") }
    if($robotMetni -match '(?i)her gün' -and $ilk -notmatch '(?m)^\s*-\s*cron:'){ $bulgular.Add("R3 '$robotMetni' diyor ama $($akislar[0]) zamanlanmamış") }
  }
  return $bulgular.ToArray()
}

if($Sinama){
  # sahte kayıtlar: her biri TAM OLARAK bir kuralı çiğner; temiz kayıt bulgu üretmemeli
  $vakalar = @(
    @{ beklenen='';   k=@{ ad='temiz';  yol='veri\kasa-sayim.json';  uretici='motor/kasa-sayim.ps1'; robot='kasa-sayim.yml · her gün 03:41 TR' } }
    @{ beklenen='Ü1'; k=@{ ad='u1';     yol='veri\x.json';           uretici='bilinmiyor';            robot='yok' } }
    @{ beklenen='Ü2'; k=@{ ad='u2';     yol='veri\x.json';           uretici='motor/boyle-betik-yok.ps1'; robot='yok' } }
    @{ beklenen='Ü3'; k=@{ ad='u3';     yol='veri\kgk-analiz.json';  uretici='motor/kasa-sayim.ps1';  robot='yok' } }
    @{ beklenen='R1'; k=@{ ad='r1';     yol='veri\kasa-sayim.json';  uretici='motor/kasa-sayim.ps1';  robot='boyle-akis-yok.yml' } }
    @{ beklenen='R2'; k=@{ ad='r2';     yol='veri\kasa-sayim.json';  uretici='motor/kasa-sayim.ps1';  robot='karne.yml' } }
    @{ beklenen='';   k=@{ ad='elle';   yol='veri\kgk-analiz.json';  uretici='elle etiket';           robot='yok — haberci: kgk-sinav-nobeti.yml' } }
  )
  $dusen = 0
  foreach($v in $vakalar){
    $b = @(KayitDenetle ([pscustomobject]$v.k))
    $tamam = if($v.beklenen){ @($b | Where-Object { $_ -like "$($v.beklenen) *" }).Count -ge 1 } else { $b.Count -eq 0 }
    if(-not $tamam){ $dusen++; Write-Host "ÖZ-SINAV DÜŞTÜ: $($v.k.ad) beklenen '$($v.beklenen)' · bulunan: $($b -join ' | ')" }
  }
  if($dusen){ exit 1 }
  Write-Host "ÖZ-SINAV YEŞİL ($($vakalar.Count) vaka)"; exit 0
}

# --- kütüğü AST ile oku (betik koşturulmaz)
$tekSayfa = if($TekSayfaYolu){ $TekSayfaYolu } else { Join-Path (Join-Path $depoKok 'motor') 'sinav-tek-sayfa.ps1' }
$tok = $null; $err = $null
$agac = [System.Management.Automation.Language.Parser]::ParseFile($tekSayfa,[ref]$tok,[ref]$err)
$atama = $agac.Find({ param($d) $d -is [System.Management.Automation.Language.AssignmentStatementAst] -and "$($d.Left)" -eq '$GIRDILER' }, $true)
if(-not $atama){ Write-Host 'KÖR: $GIRDILER kütüğü bulunamadı.'; exit 2 }
$kutuk = @(& ([scriptblock]::Create($atama.Right.Extent.Text)))
if($kutuk.Count -lt 5){ Write-Host "KÖR: kütükte yalnız $($kutuk.Count) kayıt okundu."; exit 2 }
$ihlal = 0
foreach($kayit in $kutuk){
  $b = @(KayitDenetle ([pscustomobject]$kayit))
  if($b.Count){ $ihlal += $b.Count; foreach($x in $b){ Write-Host ("  ✗ {0,-22} {1}" -f $kayit.ad,$x) } }
}
Write-Host ("TEK SAYFA KÜTÜĞÜ: {0} kayıt · ihlal {1}" -f $kutuk.Count,$ihlal)
if($ihlal){ exit 1 }
exit 0
