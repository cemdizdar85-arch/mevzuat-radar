# ============================================================================
#  THP LISTESI MALIYET OLCUMU (03.08.2026 gece) — 0 USD, API YOK, YAZMA YOK
#
#  NEDEN: 3. pilotta tam kasa tahmini ~325 -> ~367 USD'ye cikti. Suphelilerden
#  biri: THP listesi (269 hesap, 8.833 karakter ~ 2.524 token) su anda GENIS
#  bir desene uyan HER soruya gonderiliyor:
#    muhasebe|hesap|yevmiye|defter|kayit|bilanco|gelir tablo|maliyet|stok|
#    amortisman|avans|karsilik|reeskont
#  "Maliye", "hesap" kelimesi gecen her hukuk sorusu da bu desene uyar - liste
#  bosuna gider. Cem: "ucuzlatma yolu THP listesini yalniz hesap kodu gereken
#  sorulara koymak - olculmedi." BU BETIK O OLCUMU YAPAR.
#
#  UC SENARYO SAYILIR:
#   A) SIMDIKI  : genis desen (yukaridaki regex)
#   B) DAR      : sorunun/siklarin/aciklamanin metninde GERCEKTEN 3-haneli hesap
#                 kodu deseni var (yani model zaten kod yazacak) YA DA yevmiye/
#                 tablo/kayit gibi acik muhasebe fiili geciyor
#   C) EN DAR   : yalnizca metinde 3-haneli hesap kodu deseni olanlar
#
#  RISK NOTU: B/C'ye gecmek 181 vakasi riskini geri getirebilir (kod metinde
#  YOKKEN model hafizadan yazarsa). O yuzden bu betik yalniz OLCER, karar Cem'in.
#  Ayrica "liste gitmedi ama model yine de kod yazdi" riskini olcmek icin:
#  simdiki desene UYMAYAN ama metninde hesap kodu OLAN sorular da sayilir.
#
#  CIKTI: veri/thp-liste-maliyet-raporu.json
#  ENV: SUPABASE_SERVICE_KEY
# ============================================================================
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$PSDefaultParameterValues['Invoke-RestMethod:UserAgent'] = 'mevzuat-radar-robot/1.0'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$raporYol = Join-Path $kok 'veri/thp-liste-maliyet-raporu.json'

trap {
  $g=''; if($_.ErrorDetails -and $_.ErrorDetails.Message){ $g=$_.ErrorDetails.Message }
  Set-Content -LiteralPath $raporYol -Encoding UTF8 -NoNewline -Value (ConvertTo-Json -Depth 3 -InputObject ([ordered]@{
    tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); durum='HATA'; hata="$($_.Exception.Message)"; sunucu=$g; satir=$_.InvocationInfo.ScriptLineNumber }))
  Write-Host ("HATA (satir {0}): {1}" -f $_.InvocationInfo.ScriptLineNumber, $_.Exception.Message); exit 1
}
if(-not $env:SUPABASE_SERVICE_KEY){ Write-Host "SUPABASE_SERVICE_KEY yok."; exit 0 }
$U  = "https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/soru_havuzu"
$SB = @{ apikey=$env:SUPABASE_SERVICE_KEY; Authorization="Bearer $($env:SUPABASE_SERVICE_KEY)" }
function CekListe([string]$uri){
  $h = Invoke-WebRequest -Uri $uri -Headers $SB -UseBasicParsing -TimeoutSec 180
  $m = if($h.RawContentStream){ [Text.Encoding]::UTF8.GetString($h.RawContentStream.ToArray()) } else { "$($h.Content)" }
  return @($m | ConvertFrom-Json)
}

# --- THP listesinin GERCEK boyutu (motor ile ayni sekilde kurulur) ---
$c2 = New-Object System.Collections.Generic.List[string]
$seen = @{}
foreach($tf in (Get-ChildItem (Join-Path $kok 'veri/mevzuat/msugt*.json') -ErrorAction SilentlyContinue)){
  try {
    $v = Get-Content $tf.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
    foreach($b in @($v.belgeler)){
      $m = [regex]::Match("$($b.kaynak_ad)", '(?i)THP\s*(\d{3})\s*[-–—]\s*(.+)$')
      if($m.Success -and -not $seen.ContainsKey($m.Groups[1].Value)){
        $seen[$m.Groups[1].Value] = 1
        $c2.Add(($m.Groups[1].Value + ' ' + $m.Groups[2].Value.Trim()))
      }
    }
  } catch {}
}
$thpMetin = ($c2 | Sort-Object) -join "`n"
$thpKarakter = $thpMetin.Length
$thpToken = [Math]::Round($thpKarakter / 3.5)     # Turkce icin ~3,5 karakter/token
Write-Host ("THP listesi: {0} hesap, {1} karakter, ~{2} token" -f $c2.Count, $thpKarakter, $thpToken)

$kasa = New-Object System.Collections.Generic.List[object]
for($o=0; $o -lt 60000; $o+=1000){
  $r = CekListe "$U`?select=id,ders,konu,soru,siklar,aciklama&order=id&limit=1000&offset=$o"
  if($r.Count -eq 0){ break }
  foreach($x in $r){ if($null -ne $x){ $kasa.Add($x) } }
  if($r.Count -lt 1000){ break }
}
Write-Host ("Kasa: {0} soru" -f $kasa.Count)

# Motorun SIMDIKI genis deseni (onarim-motoru.ps1 ile birebir ayni)
$reGenis = [regex]'(?i)muhasebe|hesap|yevmiye|defter|kay[ıi]t|bilan[çc]o|gelir tablo|maliyet|stok|amortisman|avans|kar[şs][ıi]l[ıi]k|reeskont'
# Metinde GERCEK hesap kodu izi: "NNN Ad" ya da "Ad (NNN)"
$reKod   = [regex]'(?<![\d.,])\b([1-8]\d{2})(?!\d)\s*[-–—]?\s*[A-Za-zÇĞİÖŞÜçğıöşü]|[A-Za-zÇĞİÖŞÜçğıöşü]\s*\(\s*[1-8]\d{2}\s*\)'
# Acik muhasebe fiili (kod yazilmasi beklenir)
$reFiil  = [regex]'(?i)yevmiye|bor[çc]land[ıi]r|alacakland[ıi]r|kaydeder|muhasebele[şs]tir|hesab[ıi]na (bor[çc]|alacak)|defter-i kebir|mizan'

$A = 0; $B = 0; $C = 0; $risk = 0
foreach($s in $kasa){
  $tum = "$($s.ders) $($s.konu) $($s.soru)"
  $tam = $tum
  if($s.siklar){   foreach($p in $s.siklar.PSObject.Properties){   $tam += ' ' + "$($p.Value)" } }
  if($s.aciklama){ foreach($p in $s.aciklama.PSObject.Properties){ $tam += ' ' + "$($p.Value)" } }

  $genisMi = $reGenis.IsMatch($tum)          # motor SORU+KONU+DERS'e bakiyor
  $kodVar  = $reKod.IsMatch($tam)            # metinde gercek kod izi
  $fiilVar = $reFiil.IsMatch($tam)

  if($genisMi){ $A++ }
  if($kodVar -or $fiilVar){ $B++ }
  if($kodVar){ $C++ }
  # RISK: simdiki desen listeyi GONDERMIYOR ama metinde kod var -> model
  # hafizadan yazma riski (181 vakasi). Daraltirsak bu sinif buyur.
  if(-not $genisMi -and $kodVar){ $risk++ }
}

function Maliyet($adet){ return [Math]::Round($adet * $thpToken / 1000000.0, 2) }  # 1 USD/M giris
$rapor = [ordered]@{
  tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); durum='TAMAM'; mod='OLCUM (0 USD, yazma yok)'
  kasa=$kasa.Count
  thp_hesap=$c2.Count; thp_karakter=$thpKarakter; thp_tahmini_token=$thpToken
  senaryo_A_simdiki_genis_desen=$A
  senaryo_B_kod_izi_veya_muhasebe_fiili=$B
  senaryo_C_yalniz_kod_izi=$C
  maliyet_A_usd=(Maliyet $A)
  maliyet_B_usd=(Maliyet $B)
  maliyet_C_usd=(Maliyet $C)
  tasarruf_B_usd=[Math]::Round((Maliyet $A) - (Maliyet $B), 2)
  tasarruf_C_usd=[Math]::Round((Maliyet $A) - (Maliyet $C), 2)
  risk_desen_disi_ama_kod_var=$risk
  not='Yalniz OLCUM - kasaya ve isteme dokunulmadi. Token tahmini ~3,5 karakter/token (Turkce). Maliyet yalniz THP LISTESININ giris tokeni; sorunun kendisi ve dayanak haric. Daraltma karari Cem in - 181 vakasi riski (kod metinde yokken model hafizadan yazar) risk_desen_disi_ama_kod_var sayacinda gorunur.'
}
Set-Content -LiteralPath $raporYol -Value (ConvertTo-Json -InputObject $rapor -Depth 4) -Encoding UTF8 -NoNewline
Write-Host "`n=== THP LISTESI MALIYET OLCUMU ==="
Write-Host ("  A) Simdiki genis desen : {0,6} soru -> {1,7} USD" -f $A, (Maliyet $A))
Write-Host ("  B) Kod izi VEYA fiil   : {0,6} soru -> {1,7} USD  (tasarruf {2} USD)" -f $B, (Maliyet $B), $rapor.tasarruf_B_usd)
Write-Host ("  C) Yalniz kod izi      : {0,6} soru -> {1,7} USD  (tasarruf {2} USD)" -f $C, (Maliyet $C), $rapor.tasarruf_C_usd)
Write-Host ("  RISK (desen disi ama metinde kod var): {0}" -f $risk)
