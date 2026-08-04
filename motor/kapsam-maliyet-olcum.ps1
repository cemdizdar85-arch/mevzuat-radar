# ============================================================================
#  KAPSAM VE MALIYET OLCUMU (04.08.2026) — 0 USD, API YOK, YAZMA YOK
#
#  CEM: "benim 4.334 sorum yok, diger sorulari nasil yapacagiz? Tum bunlar
#  benim bir haftalik onerilerim."
#
#  DOGRU SORU. Bu gece kanitlandi ki bazi iyilestirmeler tum kasaya
#  ULASMIYOR:
#   - hap (kehribar kart): motor bu alani HIC uretmiyor -> puf noktasi
#     kurali mevcut 27 bin karta ulasmaz.
#   - dort parca: yalniz EKSIK olanda yeniden yazilir (D11) -> "ilkenin
#     adini soyle" kurali sorularin kucuk bir kismina ulasir.
#
#  BU BETIK KARAR ICIN RAKAM URETIR: uc kapsam senaryosunda kac soru
#  islenir ve fatura ne olur. Token varsayimlari ACIKCA yazilir (uydurma
#  rakam yok - hepsi pilot-0408-1437'nin OLCULEN degerlerinden turetildi).
#
#  CIKTI: veri/kapsam-maliyet-raporu.json  ·  ENV: SUPABASE_SERVICE_KEY
# ============================================================================
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$PSDefaultParameterValues['Invoke-RestMethod:UserAgent'] = 'mevzuat-radar-robot/1.0'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$raporYol = Join-Path $kok 'veri/kapsam-maliyet-raporu.json'

function RaporYaz($n){
  $j = ConvertTo-Json -InputObject $n -Depth 6
  if($j.Length -gt 20480){ $j = ConvertTo-Json -Depth 2 -InputObject @{ durum='KIRMIZI - rapor sismis'; boyut=$j.Length } }
  Set-Content -LiteralPath $raporYol -Value $j -Encoding UTF8 -NoNewline
}
trap {
  $g=''; if($_.ErrorDetails -and $_.ErrorDetails.Message){ $g=$_.ErrorDetails.Message }
  RaporYaz ([ordered]@{ tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); durum='HATA'
    hata="$($_.Exception.Message)"; sunucu=$g; satir=$_.InvocationInfo.ScriptLineNumber })
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

# --- OLCULEN TEMEL DEGERLER (pilot-0408-1437, 200 soru) ---
# giris 1.581.956 / 200 = 7.910 token/soru   (dayanak + THP listesi + istem)
# cikis   230.621 / 200 = 1.153 token/soru
# fiyat: 1 USD/M giris + 5 USD/M cikis (Haiku 4.5 liste fiyati)
$GIRIS_SORU = 7910.0
$CIKIS_SORU = 1153.0
$FIY_GIRIS  = 1.0 / 1000000.0
$FIY_CIKIS  = 5.0 / 1000000.0
# Ek alanlarin CIKIS token tahmini (Turkce ~3,5 karakter/token):
#  hap        : kehribar kart tek-iki cumle, ~220 karakter  -> ~63 token
#  dort_parca : dort baslikli tam aciklama, ~1.700 karakter -> ~486 token
$EK_HAP  = 63.0
$EK_D4   = 486.0

$kasa = New-Object System.Collections.Generic.List[object]
for($o=0; $o -lt 60000; $o+=1000){
  $r = CekListe "$U`?select=id,soru,siklar,dogru,aciklama,hap,tablo,yevmiye&order=id&limit=1000&offset=$o"
  if($r.Count -eq 0){ break }
  foreach($x in $r){ if($null -ne $x){ $kasa.Add($x) } }
  if($r.Count -lt 1000){ break }
}
Write-Host ("Kasa: {0} soru" -f $kasa.Count)

# --- motorun EKSIK tespitiyle BIREBIR ayni desenler ---
$reNe=[regex]'(?i)ne\s+sorul'; $reKural=[regex]'(?i)(^|\n|\*|\||>)\s*kural\s*:'
$reOlay=[regex]'(?i)bu\s+olayda'; $reAkil=[regex]'(?i)ak[ıi]lda\s+kals[ıi]n'
$reTuzak=[regex]'(?i)tuzak\s*:|kar[ıi][sş]t[ıi]r'; $reDogrusu=[regex]'(?i)do[ğg]rusu\s*:'
$reHesapli=[regex]'(?i)ka[çc]\s*TL|ne\s+kadar|hesapla|tutar[ıi]n[ıi]|maliyet bedeli|amortisman|toplam[ıi]'
$reKayit=[regex]'(?i)yevmiye|kay[ıi]t|kaydeder|muhasebele[şs]tir|bor[çc]land|alacakland'
$reKarsi=[regex]'(?i)hangisi\s+do[ğg]rudur|a[şs]a[ğg][ıi]dakilerden\s+hangisi'
function Dolu($v){ if($null -eq $v){ return $false }; $s="$v"; if($s.Trim().Length -lt 5){ return $false }; return ($s -ne '{}' -and $s -ne '[]' -and $s -ne 'null') }

$isleyen = 0            # A: simdiki kapsam - eksigi olan soru
$d4Eksik = 0            # dort parca su an ISTENIYOR
$d4Tam = 0              # dort parca TAM (senaryo C'de yeniden yazilacaklar)
$hapVar = 0; $hapYok = 0
$aciklamasiz = 0

foreach($s in $kasa){
  $a = $s.aciklama
  if($null -eq $a){ $aciklamasiz++; continue }
  $dh = "$($s.dogru)".Trim().ToUpper()
  $dm = ""; try { if($a.PSObject.Properties[$dh]){ $dm = "$($a.$dh)" } } catch {}
  $eksik = @()
  $p = 0
  if($reNe.IsMatch($dm)){$p++}; if($reKural.IsMatch($dm)){$p++}
  if($reOlay.IsMatch($dm)){$p++}; if($reAkil.IsMatch($dm)){$p++}
  if($p -lt 4){ $eksik += 'D1'; $d4Eksik++ } else { $d4Tam++ }
  $tz=0; $dg=0
  foreach($h in 'A','B','C','D','E'){
    if($h -eq $dh){ continue }
    $m=""; try { if($a.PSObject.Properties[$h]){ $m="$($a.$h)" } } catch {}
    if($m.Length -lt 5){ continue }
    if($reTuzak.IsMatch($m)){$tz++}; if($reDogrusu.IsMatch($m)){$dg++}
  }
  if($tz -lt 3){ $eksik += 'D2t' }
  if($dg -lt 3){ $eksik += 'D2d' }
  $gv = "$($s.soru)"
  if($reHesapli.IsMatch($gv) -and -not (Dolu $s.tablo)){ $eksik += 'D7t' }
  if($reKayit.IsMatch($gv)   -and -not (Dolu $s.yevmiye)){ $eksik += 'D7y' }
  if($reKarsi.IsMatch($gv) -and -not $reHesapli.IsMatch($gv) -and -not (Dolu $s.tablo)){ $eksik += 'D8' }
  if($eksik.Count -gt 0){ $isleyen++ }
  if("$($s.hap)".Trim().Length -gt 3){ $hapVar++ } else { $hapYok++ }
}

function USD($soru, $ekCikis){
  return [Math]::Round($soru * ($GIRIS_SORU*$FIY_GIRIS + ($CIKIS_SORU+$ekCikis)*$FIY_CIKIS), 2)
}
# A) SIMDIKI KAPSAM
$A_soru = $isleyen; $A_usd = USD $A_soru 0
# B) A + hap (islenen her soruya kehribar kart da uretilir)
$B_soru = $isleyen;  $B_usd = USD $B_soru $EK_HAP
# C) B + dort parca TUM sorularda yeniden yazilir (ilkenin adi her yere ulassin)
#    Islenen soru sayisi ayni kalir ama d4 TAM olanlara da d4 uretilecegi icin
#    o kadar soruda EK cikis olur.
$C_soru = $isleyen
$C_usd  = [Math]::Round( (USD $C_soru $EK_HAP) + ($d4Tam * $EK_D4 * $FIY_CIKIS), 2)
# D) C + hic islenmeyen sorulara da dokun (kapsam = TUM kasa)
$D_soru = $kasa.Count - $aciklamasiz
$D_usd  = [Math]::Round( (USD $D_soru $EK_HAP) + ($d4Tam * $EK_D4 * $FIY_CIKIS), 2)

RaporYaz ([ordered]@{
  tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); durum='TAMAM'; mod='OLCUM (0 USD, yazma yok)'
  kasa=$kasa.Count; aciklamasi_olmayan=$aciklamasiz
  simdiki_kapsamda_islenen=$isleyen
  dort_parca_EKSIK=$d4Eksik
  dort_parca_TAM_su_an_dokunulmuyor=$d4Tam
  kehribar_karti_olan=$hapVar; kehribar_karti_olmayan=$hapYok
  varsayimlar=[ordered]@{
    kaynak='pilot-0408-1437 (200 soru) OLCULEN degerleri'
    giris_token_soru=$GIRIS_SORU; cikis_token_soru=$CIKIS_SORU
    ek_cikis_hap=$EK_HAP; ek_cikis_dort_parca=$EK_D4
    fiyat='1 USD/M giris + 5 USD/M cikis (Haiku 4.5 liste)'
  }
  senaryolar=@(
    [ordered]@{ ad='A - SIMDIKI kapsam'; soru=$A_soru; usd=$A_usd; kapsam='Dogrusu/tuzak/tablo/yevmiye + eksik dort parca. hap URETILMEZ.' }
    [ordered]@{ ad='B - A + kehribar kart'; soru=$B_soru; usd=$B_usd; kapsam='Ayni sorular + her birine puf noktali hap. Cem in "puf noktasi" istegi buraya girer.' }
    [ordered]@{ ad='C - B + dort parca HERKESE'; soru=$C_soru; usd=$C_usd; kapsam='Ustune, dort parcasi TAM olan sorularda da yeniden yazilir -> "ilkenin adini soyle" kurali tum kasaya ulasir.' }
    [ordered]@{ ad='D - C + hic islenmeyenler'; soru=$D_soru; usd=$D_usd; kapsam='Kapsam TUM kasa. Su an hicbir eksigi olmayan sorular da elden gecer.' }
  )
  not='Yalniz OLCUM. Rakamlar uydurma degil: giris/cikis token degerleri pilot-0408-1437 in olculen toplamlarindan soru basina bolunerek alindi. Ek alan tahminleri karakter/3,5 ile hesaplandi ve varsayimlar bolumunde aciktir.'
})
Write-Host "`n=== KAPSAM VE MALIYET ==="
Write-Host ("  Kasa {0} | simdiki kapsamda islenen {1}" -f $kasa.Count, $isleyen)
Write-Host ("  dort parca: EKSIK {0} / TAM {1} (TAM olanlara su an DOKUNULMUYOR)" -f $d4Eksik, $d4Tam)
Write-Host ("  kehribar kart: var {0} / yok {1}" -f $hapVar, $hapYok)
Write-Host ("  A simdiki           : {0,6} soru -> {1,8} USD" -f $A_soru, $A_usd)
Write-Host ("  B +kehribar kart    : {0,6} soru -> {1,8} USD" -f $B_soru, $B_usd)
Write-Host ("  C +d4 herkese       : {0,6} soru -> {1,8} USD" -f $C_soru, $C_usd)
Write-Host ("  D +hic islenmeyenler: {0,6} soru -> {1,8} USD" -f $D_soru, $D_usd)
