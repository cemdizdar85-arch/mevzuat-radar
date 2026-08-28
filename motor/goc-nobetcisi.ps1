# ============================================================================
#  GÖÇ NÖBETÇİSİ — 29.08.2026
#  Cem: "1.2 yap" (GM onerisi 2)
#
#  NEDEN VAR: 28.08'de olculdu — alacak-radari.html sayfasi kasadan
#  'secilenGun' / 'turIlk' / 'turGun' okuyordu, ama o alanlari ureten goc
#  (2026-08-28-alacak-kapsam-serhi.sql) Supabase'de BASILMAMISTI.
#
#  ⚠ SAYFA COKMEDI - SUSTU. Kod dogru yazilmisti: alan gelmeyince kapsam
#  serhini basmiyor, uydurmuyor. Yani kusur EKRANDA GORUNMUYORDU. "Iflas
#  ilanlari arsivde yalniz 4,7 aylik" uyarisi hic cikmadi ve iki turun
#  oranlari kiyaslanabilir gibi durdu. Bu haftalarca surebilirdi.
#
#  HICBIR KAPI BUNU GOREMEZ: CI depoyu denetler, kasayi degil. Goc dosyasi
#  depoda DURUYOR - yani "yazildi" ile "basildi" arasindaki bosluk denetimsiz.
#  Bu nobetci tam o bosluga bakar: SAYFANIN OKUDUGU HER ANAHTAR KASADAN
#  GERCEKTEN GELIYOR MU?
#
#  UC DURUM (kalici-sigorta-3katman kurali): YESIL / KIRMIZI / KOR.
#  Uca hic ulasilamadiysa "temiz" DENMEZ - KOR denir.
#
#  SAHTE KIRMIZI URETMEZ: beklenen anahtarlar sayfadan HAM CIKARIMLA
#  bulunmaz. Olculdu (28.08): alacak-radari.html icinde "d.<anahtar>"
#  deseni 10'dan fazla yanlis eslesme veriyor (d.getDate, d.textContent,
#  d.slice...). Bu yuzden beklenen liste MANIFESTODA durur; nobetci de
#  manifestonun cürümesine karsi ters yonde denetler (asagi bak).
#
#  IKI YONLU CURUME DENETIMI:
#    ileri : manifestodaki anahtar kasadan gelmiyor      -> KIRMIZI (goc basilmamis)
#    geri  : manifestodaki anahtar sayfada hic gecmiyor  -> KIRMIZI (manifesto sismis)
#
#  GUVENLIK: yalnizca manifestodaki uclar cagrilir ve YAZAN UC CAGIRILMAZ -
#  yasakli ad listesi civatali (uyari_teyit, marka_talep_ac, alacak_yaz...).
#  Anahtar olarak sayfalarin zaten icinde tasidigi ACIK (publishable) anahtar
#  kullanilir; servis anahtari ISTEMEZ - yani gizli anahtar olmadigi icin
#  KOR'e dusmez.
#
#  Cikti: veri/goc-nobeti-raporu.json  ·  0 USD, model yok
# ============================================================================
param([switch]$sessiz)

$ErrorActionPreference = 'Stop'
$here    = Split-Path -Parent $MyInvocation.MyCommand.Path
$depoKok = Split-Path -Parent $here
$manifestoYolu = Join-Path $depoKok 'radar-app/sql/goc-manifesto.json'
$raporYolu     = Join-Path $depoKok 'veri/goc-nobeti-raporu.json'

# Sayfalarin HTML'inde zaten acikca duran anahtar; gizli degil, gizli olmasi da gerekmiyor.
$SB_URL = 'https://bjrleanjpyujtajmazxn.supabase.co'
$SB_KEY = 'sb_publishable_kTZpYwrL7skw8Ryj5Vs8_Q_-5_Fhkcg'

function GN_Rapor($nesne){
  $dizin = Split-Path -Parent $raporYolu
  if(-not (Test-Path $dizin)){ New-Item -ItemType Directory -Force $dizin | Out-Null }
  [IO.File]::WriteAllText($raporYolu,(ConvertTo-Json -InputObject $nesne -Depth 8),(New-Object Text.UTF8Encoding($false)))
}

# ---------------------------------------------------------------- KARAR MANTIGI
# Bu iki fonksiyon nobetcinin BEYNI. Oz-sinav tam bunlari sinar.

function GN_EksikAnahtar($nesne, $beklenen){
  # DONUS: @{ okundu=$true; eksik=@(...) }  ·  okunamadiysa @{ okundu=$false }
  #
  # ⚠ NEDEN DIZI DEGIL DE KUTU DONDURUYOR (29.08, oz-sinav yakaladi):
  # Ilk surum "return ,$eksik" yaziyordu. PowerShell dizi donusunu ACAR;
  # virgul numarasi da bos diziyi tek elemanli diziye cevirip sayimi
  # bozuyordu -> "2 eksik" beklenen yerde 1 cikti, bos liste "System.Object[]"
  # diye basildi. Yani nobetci EKSIGI YANLIS SAYIYORDU. Kutu (hashtable)
  # dondurmek bu belirsizligi tamamen kaldirir: "okunamadi" ile "eksik yok"
  # ayri alanlarda durur, hicbiri digerine benzemez.
  if($null -eq $nesne){ return @{ okundu = $false; eksik = @() } }
  $mevcut = @()
  if($nesne -is [hashtable]){ $mevcut = @($nesne.Keys) }
  else { $mevcut = @($nesne.PSObject.Properties.Name) }
  $eksik = @()
  foreach($b in @($beklenen)){
    # DEGERE DEGIL VARLIGA bakilir: kasa alani null dondurebilir (o tur icin
    # kayit yoksa min(tarih) null'dur) - anahtar YINE DE gelmistir, goc basilidir.
    if($mevcut -notcontains $b){ $eksik += $b }
  }
  return @{ okundu = $true; eksik = @($eksik) }
}

function GN_SayfadaGecmeyen($sayfaMetni, $beklenen){
  # GERI YON: manifestoda yazip da sayfanin artik okumadigi anahtar.
  # Boyle bir anahtar nobetciyi olmayan bir seyi kollar hale getirir.
  # Donus sekli GN_EksikAnahtar ile ayni sebepten kutudur.
  if($null -eq $sayfaMetni){ return @{ okundu = $false; yok = @() } }
  $yok = @()
  foreach($b in @($beklenen)){ if($sayfaMetni.IndexOf($b, [StringComparison]::Ordinal) -lt 0){ $yok += $b } }
  return @{ okundu = $true; yok = @($yok) }
}

function GN_OzSinav {
  # GOREMEDIGINI ARAYAN NOBETCI GUVENILMEZ. Bu sinav dusmeden ola koşu yapilmaz.
  $dusen = @()

  # 1) Eksik anahtar YAKALANMALI
  $n1 = ConvertFrom-Json -InputObject '{"a":1,"b":2}'
  $s1 = GN_EksikAnahtar $n1 @('a','b','c')
  $e1 = @($s1.eksik)
  if(-not $s1.okundu){ $dusen += "OKUNAN nesne okunamadi sayildi" }
  if($e1.Count -ne 1 -or $e1[0] -ne 'c'){ $dusen += "EKSIK ANAHTAR yakalanmadi (beklenen 'c', cikan '$($e1 -join ",")')" }

  # 2) Tam nesne TEMIZ cikmali
  $e2 = @((GN_EksikAnahtar $n1 @('a','b')).eksik)
  if($e2.Count -ne 0){ $dusen += "TAM nesne yanlis isaretlendi: '$($e2 -join ",")'" }

  # 3) NULL DEGERLI anahtar VAR sayilmali (en kritik tuzak: kasa alani bos
  #    donebilir - o zaman bile goc BASILIDIR, kirmizi yakmak yalan olur)
  $n3 = ConvertFrom-Json -InputObject '{"secilenIlk":null,"adet":0}'
  $e3 = @((GN_EksikAnahtar $n3 @('secilenIlk','adet')).eksik)
  if($e3.Count -ne 0){ $dusen += "NULL degerli anahtar EKSIK sayildi: '$($e3 -join ",")'" }

  # 4) Bos nesne: hepsi eksik
  $n4 = ConvertFrom-Json -InputObject '{}'
  $e4 = @((GN_EksikAnahtar $n4 @('x','y')).eksik)
  if($e4.Count -ne 2){ $dusen += "BOS nesnede 2 eksik beklenirken $($e4.Count) cikti" }

  # 5) OKUNAMAYAN nesne, "eksik yok"tan AYRILMALI - karisirsa KOR, YESIL gorunur
  $s5 = GN_EksikAnahtar $null @('x')
  if($s5.okundu){ $dusen += "OKUNAMAYAN nesne okundu sayildi (KOR, YESIL gorunurdu)" }

  # 6) GERI YON: sayfada gecmeyen anahtar yakalanmali
  $sahteSayfa = 'var x = d.adet; var y = d.turIlk;'
  $g6 = @((GN_SayfadaGecmeyen $sahteSayfa @('adet','turIlk','olmayanAnahtar')).yok)
  if($g6.Count -ne 1 -or $g6[0] -ne 'olmayanAnahtar'){ $dusen += "SAYFADA-YOK yakalanmadi (cikan '$($g6 -join ",")')" }

  # 7) GERI YON: hepsi sayfada varsa temiz
  $g7 = @((GN_SayfadaGecmeyen $sahteSayfa @('adet','turIlk')).yok)
  if($g7.Count -ne 0){ $dusen += "SAYFADA-VAR yanlis isaretlendi: '$($g7 -join ",")'" }

  # 8) SAYFA OKUNAMADI hali, "hepsi var"dan ayrilmali
  $s8 = GN_SayfadaGecmeyen $null @('x')
  if($s8.okundu){ $dusen += "OKUNAMAYAN sayfa okundu sayildi" }

  return $dusen
}

# --- 1) OZ-SINAV
$sinavDusen = @(GN_OzSinav)
if($sinavDusen.Count){
  if(-not $sessiz){
    Write-Host '!! GOC NOBETCISI KENDI SINAVINDAN DUSTU:' -ForegroundColor Red
    foreach($d in $sinavDusen){ Write-Host "   $d" }
  }
  GN_Rapor ([ordered]@{ tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); durum='KOR'; sebep='oz-sinav dustu'; dusen=$sinavDusen })
  exit 1
}
if(-not $sessiz){
  Write-Host 'Oz-sinav: 8/8 vaka gecti (4 ileri yon + 2 okunamadi ayrimi + 2 geri yon)'
  Write-Host '  SINANMAYAN DALLAR: HTTP cagrisi · manifesto okuma · rapor yazimi' -ForegroundColor DarkGray
}

# --- 2) MANIFESTO
if(-not (Test-Path $manifestoYolu)){
  if(-not $sessiz){ Write-Host "KOR: manifesto yok - $manifestoYolu" -ForegroundColor Yellow }
  GN_Rapor ([ordered]@{ tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); durum='KOR'; sebep='manifesto bulunamadi' })
  exit 1
}
$ham = [IO.File]::ReadAllText($manifestoYolu)
$manifesto = $ham | ConvertFrom-Json
$yasak = @($manifesto.yasakUclar)

# --- 3) UCLARI SINA
# PS 5.1 (Windows) TLS 1.2'yi kendiliginden secmez; PS 7 (CI, Linux) bu ayari
# gereksiz kilar ve bazi surumlerde atar. Ikisinde de kosabilmesi icin sarmalli.
try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 } catch {}
$basliklar = @{ apikey=$SB_KEY; Authorization="Bearer $SB_KEY"; 'Content-Type'='application/json' }
$sonuclar = @()
$sayfaOnbellek = @{}

foreach($k in @($manifesto.kontroller)){
  $satir = [ordered]@{ ad=$k.ad; uc=$k.uc; goc=$k.goc; durum='?'; eksik=@(); sayfadaYok=@(); sebep='' }

  # GUVENLIK CIVATASI: yazan uc asla cagrilmaz.
  if($yasak -contains $k.uc){
    $satir.durum='KOR'; $satir.sebep='YASAKLI UC (yazan uc cagirilmaz)'
    $sonuclar += $satir; continue
  }

  $govde = ConvertTo-Json -InputObject $k.govde -Depth 6 -Compress
  if([string]::IsNullOrWhiteSpace($govde) -or $govde -eq 'null'){ $govde = '{}' }

  $nesne = $null
  try {
    $yanit = Invoke-WebRequest -UseBasicParsing -Method Post -Uri ($SB_URL + '/rest/v1/rpc/' + $k.uc) `
             -Headers $basliklar -Body $govde -TimeoutSec 60
    $metin = $yanit.Content
    # PS 5.1: ConvertFrom-Json'u BORU HATTINDA kullanma - iki adim.
    $nesne = ConvertFrom-Json -InputObject $metin
  } catch {
    $satir.durum='KOR'; $satir.sebep="istek basarisiz: $($_.Exception.Message)"
    $sonuclar += $satir; continue
  }

  if($k.tur -eq 'varlik'){
    # Fonksiyon var mi? PGRST202 = yok. Cevabin ICERIGI denetlenmez.
    if($metin -match 'PGRST202'){ $satir.durum='KIRMIZI'; $satir.sebep='fonksiyon kasada YOK (PGRST202)' }
    else { $satir.durum='YESIL' }
    $sonuclar += $satir; continue
  }

  # tur = 'anahtar'
  $s = GN_EksikAnahtar $nesne $k.beklenen
  if(-not $s.okundu){
    $satir.durum='KOR'; $satir.sebep='cevap cozulemedi'
    $sonuclar += $satir; continue
  }
  $satir.eksik = @($s.eksik)

  # GERI YON: manifesto sismis mi?
  if($k.sayfa){
    $sayfaYolu = Join-Path $depoKok $k.sayfa
    if(-not $sayfaOnbellek.ContainsKey($k.sayfa)){
      if(Test-Path $sayfaYolu){ $sayfaOnbellek[$k.sayfa] = [IO.File]::ReadAllText($sayfaYolu) }
      else { $sayfaOnbellek[$k.sayfa] = $null }
    }
    $sy = GN_SayfadaGecmeyen $sayfaOnbellek[$k.sayfa] $k.beklenen
    if(-not $sy.okundu){ $satir.sebep = "sayfa okunamadi: $($k.sayfa)" }
    else { $satir.sayfadaYok = @($sy.yok) }
  }

  if(@($satir.eksik).Count -or @($satir.sayfadaYok).Count){ $satir.durum='KIRMIZI' } else { $satir.durum='YESIL' }
  $sonuclar += $satir
}

# --- 4) BILINEN KUSURLAR: kapiyi kirmiziya boyamaz, ama SUSMAZ da.
#     (kalici-sigorta dersi: surekli kirmizi kapi kapi olmaktan cikar)
$bilinen = @()
foreach($b in @($manifesto.bilinenKusurlar)){ $bilinen += ([ordered]@{ uc=$b.uc; kusur=$b.kusur; olcum=$b.olcum; goc=$b.goc }) }

# --- 5) HUKUM
$kirmizi = @($sonuclar | Where-Object { $_.durum -eq 'KIRMIZI' })
$kor     = @($sonuclar | Where-Object { $_.durum -eq 'KOR' })
$durum = 'YESIL'
if($kirmizi.Count){ $durum = 'KIRMIZI' } elseif($kor.Count){ $durum = 'KOR' }

GN_Rapor ([ordered]@{
  tarih   = (Get-Date -Format 'dd.MM.yyyy HH:mm')
  durum   = $durum
  ozet    = ("{0} kontrol · {1} yesil · {2} kirmizi · {3} kor" -f @($sonuclar).Count, @($sonuclar | Where-Object { $_.durum -eq 'YESIL' }).Count, $kirmizi.Count, $kor.Count)
  kontroller = $sonuclar
  bilinenKusurlar = $bilinen
  not = 'Beklenen anahtarlar radar-app/sql/goc-manifesto.json icinde; kutuk radar-app/sql/UYGULANDI.md'
})

if(-not $sessiz){
  foreach($s in $sonuclar){
    $renk = switch($s.durum){ 'YESIL' {'Green'} 'KIRMIZI' {'Red'} default {'Yellow'} }
    $ek = ''
    if(@($s.eksik).Count){ $ek = " · kasadan gelmeyen: $(@($s.eksik) -join ', ') -> BAS: $($s.goc)" }
    if(@($s.sayfadaYok).Count){ $ek += " · sayfada okunmayan (manifesto sismis): $(@($s.sayfadaYok) -join ', ')" }
    if($s.sebep){ $ek += " · $($s.sebep)" }
    Write-Host ("[{0}] {1}{2}" -f $s.durum, $s.ad, $ek) -ForegroundColor $renk
  }
  foreach($b in $bilinen){ Write-Host ("[BILINEN KUSUR] {0}: {1}" -f $b.uc, $b.kusur) -ForegroundColor DarkYellow }
  Write-Host ("HUKUM: {0}" -f $durum) -ForegroundColor $(if($durum -eq 'YESIL'){'Green'}elseif($durum -eq 'KIRMIZI'){'Red'}else{'Yellow'})
}

if($durum -ne 'YESIL'){ exit 1 }
exit 0
