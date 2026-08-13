# ============================================================================
#  SIK KARISTIRICI — dogru cevap harfini dengeler (03.08.2026)
#
#  NEDEN: Ilk sik-dagilimi olcumu (kasa-desen 12:48): dogru cevaplarin
#  %44,4'u A'da (B %22,7 · C %16 · D %9,8 · E %7). "Bilmeyen A isaretlesin"
#  diyen aday yariya yakinini tutturur - sinav degeri sifirlanir. Uretici
#  model dogruyu A'ya yigmis (bilinen LLM onyargisi).
#
#  NE YAPAR (DETERMINISTIK, MODEL YOK, 0 USD):
#   - Soru id'sinden turetilen SABIT tohumla (id hash) hedef harf secilir
#     (uniform A-E) -> ayni kosu tekrar edilirse ayni sonuc (idempotent-ish;
#     zaten hedef=mevcut ise dokunulmaz).
#   - Dogru sikkin icerigi hedef harfe tasinir; diger sik icerikleri sirasi
#     korunarak kalan harflere kaydirilir; aciklama anahtarlari AYNI esleme
#     ile tasinir; 'dogru' alani hedef harf yapilir.
#  EMNIYET:
#   - Aciklama/soru metninde HARF ATFI varsa ("B sikki", "C secenegi",
#     "A'yi isaretleyen") o soruya DOKUNULMAZ -> 'atifli' listesine yazilir
#     (onlar parali onarimda ele alinir). Yanlis metin uretmektense az duzelt.
#   - Yalnizca 5 tam sikli (A-E) ve tek dogru harfli sorular islenir.
#   - Varsayilan OLCUM. Yazmak icin -uygula. Yazim sonrasi GERI OKUYUP
#     dagilim yeniden sayilir (yesil kosu != tam veri).
#  ENV: SUPABASE_SERVICE_KEY. Rapor: veri/sik-karistir.json
# ============================================================================
param([switch]$uygula)
$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$TABAN = "https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/soru_havuzu"
$cikti = Join-Path $kok "veri/sik-karistir.json"
$enc = New-Object Text.UTF8Encoding($false)
function Yaz($n){ [IO.File]::WriteAllText($cikti, (ConvertTo-Json -InputObject $n -Depth 6), $enc) }
trap {
  $g = ""; if($_.ErrorDetails -and $_.ErrorDetails.Message){ $g = $_.ErrorDetails.Message }
  Yaz ([ordered]@{ tarih=(Get-Date -Format "dd.MM.yyyy HH:mm"); durum="HATA"; hata="$($_.Exception.Message)"; sunucu=$g; satir=$_.InvocationInfo.ScriptLineNumber })
  Write-Host ("HATA (satir {0}): {1} | sunucu: {2}" -f $_.InvocationInfo.ScriptLineNumber, $_.Exception.Message, $g); exit 1
}
$KEY = "$env:SUPABASE_SERVICE_KEY"
if([string]::IsNullOrWhiteSpace($KEY)){
  Yaz ([ordered]@{ tarih=(Get-Date -Format "dd.MM.yyyy HH:mm"); durum="ATLANDI"; not="SUPABASE_SERVICE_KEY yok" })
  Write-Host "SUPABASE_SERVICE_KEY yok - atlandi."; exit 0
}
# 13.08.2026: 'sb_secret' anahtar robot User-Agent ister; UA'siz istek TARAYICI
# sayilip 401 "Forbidden use of secret API key in browser" doner (bilinen tuzak —
# 88 motor betigi bu yuzden olmustu). UA hem IWR hem IRM icin ayri yazilir.
$BASLIK = @{ apikey = $KEY; Authorization = "Bearer $KEY"; 'User-Agent' = 'mevzuat-radar-robot/1.0' }
$PSDefaultParameterValues['Invoke-WebRequest:UserAgent'] = 'mevzuat-radar-robot/1.0'
$PSDefaultParameterValues['Invoke-RestMethod:UserAgent'] = 'mevzuat-radar-robot/1.0'

$HARFLER = @('A','B','C','D','E')
# harf atfi deseni: "B sikki", "C secenegi", "D'yi", "(E)" gibi acik atiflar.
# Genis tutuldu: suphede DOKUNMA.
$reAtif = [regex]"(?i)\b[A-E]\s*[)\-']|\b[A-E]\s+([sş][ıi]kk?[ıi]|se[çc]ene[ğg]i)|\b[A-E]['’]"

function HedefHarf([string]$id){
  # id'den deterministik 0-4: SHA yerine basit ve sabit - GetHashCode PLATFORMA
  # gore degisebilir, o yuzden karakter toplami kullanilir (her yerde ayni).
  $t = 0; foreach($ch in $id.ToCharArray()){ $t = ($t * 31 + [int]$ch) % 1000003 }
  return $HARFLER[$t % 5]
}

# ------------------------------------------------------------- kasayi cek
$hepsi = 0
$adaylar = New-Object System.Collections.Generic.List[object]
$atifli = New-Object System.Collections.Generic.List[string]
$eksikSik = 0
$dagilimOnce = @{}
$offset = 0; $sayfa = 1000
while($true){
  $istekUri = "${TABAN}?select=id,siklar,dogru,aciklama,soru&order=id&limit=$sayfa&offset=$offset"
  $hw = Invoke-WebRequest -UseBasicParsing -Uri $istekUri -Headers $BASLIK -TimeoutSec 180
  $gv = if($hw.Content -is [byte[]]){ [Text.Encoding]::UTF8.GetString($hw.Content) } else { "$($hw.Content)" }
  $parti = @(); foreach($x in (ConvertFrom-Json $gv)){ $parti += $x }
  if(-not $parti.Count){ break }
  foreach($s in $parti){
    $hepsi++
    $d = "$($s.dogru)".Trim().ToUpperInvariant()
    if($HARFLER -notcontains $d){ $eksikSik++; continue }
    $dagilimOnce[$d] = 1 + [int]$dagilimOnce[$d]
    $tam = $true
    foreach($harf in $HARFLER){ if(-not ($s.siklar -and $s.siklar.PSObject.Properties[$harf]) ){ $tam = $false; break } }
    if(-not $tam){ $eksikSik++; continue }
    # harf atfi kontrolu (soru + tum aciklamalar)
    $metin = "$($s.soru)"
    if($s.aciklama){ foreach($p in $s.aciklama.PSObject.Properties){ $metin += ' ' + "$($p.Value)" } }
    if($reAtif.IsMatch($metin)){ $atifli.Add("$($s.id)"); continue }
    $hedef = HedefHarf "$($s.id)"
    if($hedef -eq $d){ continue }   # zaten hedefte - dokunma
    $adaylar.Add($s)
  }
  if($parti.Count -lt $sayfa){ break }
  $offset += $sayfa
}
Write-Host ("Taranan: {0} | karistirilacak: {1} | harf-atifli (dokunulmaz): {2} | eksik-sik/dogru: {3}" -f $hepsi, $adaylar.Count, $atifli.Count, $eksikSik)

$duzelen = 0; $hataYaz = 0; $ilkHata = ''
if($uygula){
  foreach($s in $adaylar){
    $id = "$($s.id)"
    $d = "$($s.dogru)".Trim().ToUpperInvariant()
    $hedef = HedefHarf $id
    # esleme: dogru icerik -> hedef harf; kalan icerikler sira korunarak kalan harflere
    $digerIcerik = @(); $digerAcik = @()
    foreach($harf in $HARFLER){
      if($harf -eq $d){ continue }
      $digerIcerik += ,"$($s.siklar.$harf)"
      $digerAcik   += ,$(if($s.aciklama -and $s.aciklama.PSObject.Properties[$harf]){ "$($s.aciklama.$harf)" } else { $null })
    }
    $yeniSik = [ordered]@{}; $yeniAcik = [ordered]@{}
    $i = 0
    foreach($harf in $HARFLER){
      if($harf -eq $hedef){
        $yeniSik[$harf] = "$($s.siklar.$d)"
        $ac = $(if($s.aciklama -and $s.aciklama.PSObject.Properties[$d]){ "$($s.aciklama.$d)" } else { $null })
        if($null -ne $ac){ $yeniAcik[$harf] = $ac }
      } else {
        $yeniSik[$harf] = $digerIcerik[$i]
        if($null -ne $digerAcik[$i]){ $yeniAcik[$harf] = $digerAcik[$i] }
        $i++
      }
    }
    $govde = [ordered]@{ siklar = $yeniSik; dogru = $hedef }
    if($yeniAcik.Keys.Count -gt 0){ $govde['aciklama'] = $yeniAcik }
    $patchUri = "${TABAN}?id=eq." + [uri]::EscapeDataString($id)
    try {
      Invoke-WebRequest -Uri $patchUri -Method Patch `
        -Headers ($BASLIK + @{ 'Content-Type'='application/json'; Prefer='return=minimal' }) `
        -Body ([Text.Encoding]::UTF8.GetBytes((ConvertTo-Json -InputObject $govde -Depth 6))) `
        -UseBasicParsing -TimeoutSec 60 | Out-Null
      $duzelen++
      if(($duzelen % 500) -eq 0){ Write-Host ("  ...{0}/{1}" -f $duzelen, $adaylar.Count) }
    } catch {
      $hataYaz++
      $g = ""; if($_.ErrorDetails -and $_.ErrorDetails.Message){ $g = $_.ErrorDetails.Message }
      if(-not $ilkHata){ $ilkHata = ("{0} | sunucu: {1} | id: {2}" -f $_.Exception.Message, $g, $id) }
    }
  }
}

# --- geri okuma: yeni dagilim
$dagilimSonra = @{}
if($uygula){
  $offset = 0
  while($true){
    $istekUri = "${TABAN}?select=dogru&order=id&limit=$sayfa&offset=$offset"
    $hw = Invoke-WebRequest -UseBasicParsing -Uri $istekUri -Headers $BASLIK -TimeoutSec 180
    $gv = if($hw.Content -is [byte[]]){ [Text.Encoding]::UTF8.GetString($hw.Content) } else { "$($hw.Content)" }
    $parti = @(); foreach($x in (ConvertFrom-Json $gv)){ $parti += $x }
    if(-not $parti.Count){ break }
    foreach($s in $parti){ $d2 = "$($s.dogru)".Trim().ToUpperInvariant(); if($HARFLER -contains $d2){ $dagilimSonra[$d2] = 1 + [int]$dagilimSonra[$d2] } }
    if($parti.Count -lt $sayfa){ break }
    $offset += $sayfa
  }
}

function Yuzde($h){ $t = 0; foreach($v in $h.Values){ $t += [int]$v }; $o = [ordered]@{}; foreach($harf in $HARFLER){ $o[$harf] = if($t){ [math]::Round(100.0 * [int]$h[$harf] / $t, 1) } else { 0 } }; return $o }

Yaz ([ordered]@{
  tarih   = (Get-Date -Format "dd.MM.yyyy HH:mm")
  durum   = $(if(-not $uygula){ 'OLCUM' } elseif($hataYaz){ 'KISMI' } else { 'TAMAM' })
  mod     = $(if($uygula){ 'uygula' } else { 'olcum' })
  taranan = $hepsi
  karistirilabilir = $adaylar.Count
  harf_atifli_dokunulmaz = $atifli.Count
  eksik_sik = $eksikSik
  duzelen = $duzelen
  yazma_hatasi = $hataYaz
  ilk_hata = $ilkHata
  dagilim_once_yuzde = (Yuzde $dagilimOnce)
  dagilim_sonra_yuzde = $(if($uygula){ (Yuzde $dagilimSonra) } else { $null })
  atifli_idler = @($atifli)
})
Write-Host ("SIK KARISTIR: aday {0} | duzelen {1} | hata {2} | atifli {3}" -f $adaylar.Count, $duzelen, $hataYaz, $atifli.Count)
