# ============================================================================
#  ONARIM MOTORU (02.08.2026) — SINAV-KURALLARI D1/D2/D7/D8 tamamlayicisi
#  Sartname: ONARIM-MOTOR-SARTNAMESI.md (bu gecenin TUM kararlari orada)
#
#  CEM'IN KURALI: "parali islemi bir kez calistirip birakalim" + "tekrar tekrar
#  yapmayalim". Bu yuzden motor bir soruyu ACAR ve EKSIK OLAN NE VARSA HEPSINI
#  AYNI CAGRIDA uretir. Bir soruya BIR KEZ dokunulur.
#
#  UC MOD:
#   (varsayilan) KURU  : 0 USD. Kimin neyi eksik oldugunu sayar, ORNEK ISTEMLERI
#                        dosyaya yazar. Hicbir API cagrisi YOK. Gozle kontrol icin.
#   -uygula -sinir N   : PARALI pilot. N soru islenir, GERCEK FATURA olculur.
#   -uygula            : PARALI tam parti (Cem'in acik "bas"i olmadan kosulmaz).
#
#  KIRMIZI CIZGILER (sartname 3):
#   - Dayanak metni COZULEMEYEN soru ATLANIR, uydurulmaz (D4).
#   - Zaten TAM olan madde uretilmez (hem para hem kalite kaybi).
#   - Yazma PATCH ile (kismi upsert NOT NULL duvarina carpar - 27.07 dersi).
#   - Yazilan her soru GERI OKUNUR; dogrulanmayan "yapildi" sayilmaz.
#   - Her kosu rapor yazar (kor kalma): islenen/yazilan/dogrulanan/atlanan+sebep.
#
#  ENV: SUPABASE_SERVICE_KEY (+ -uygula icin ANTHROPIC_API_KEY)
#  Cikti: veri/onarim-motor-raporu.json · veri/onarim-motor-ornek-istem.txt
# ============================================================================
param(
  [switch]$uygula,
  [int]$sinir = 0,
  [string]$model = 'claude-haiku-4-5-20251001'
)
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$PSDefaultParameterValues['Invoke-RestMethod:UserAgent'] = 'mevzuat-radar-robot/1.0'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$raporYol = Join-Path $kok 'veri/onarim-motor-raporu.json'
$ornekYol = Join-Path $kok 'veri/onarim-motor-ornek-istem.txt'

trap {
  $g = ""; if($_.ErrorDetails -and $_.ErrorDetails.Message){ $g = $_.ErrorDetails.Message }
  Set-Content -LiteralPath $raporYol -Encoding UTF8 -NoNewline -Value (ConvertTo-Json -Depth 4 -InputObject ([ordered]@{
    tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); durum='HATA'
    hata="$($_.Exception.Message)"; sunucu=$g; satir=$_.InvocationInfo.ScriptLineNumber }))
  Write-Host ("HATA (satir {0}): {1} | {2}" -f $_.InvocationInfo.ScriptLineNumber, $_.Exception.Message, $g)
  exit 1
}
if(-not $env:SUPABASE_SERVICE_KEY){ Write-Host "SUPABASE_SERVICE_KEY yok - cikildi."; exit 0 }
$U  = "https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/soru_havuzu"
$DK = "https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/dokumanlar"
$SB = @{ apikey=$env:SUPABASE_SERVICE_KEY; Authorization="Bearer $($env:SUPABASE_SERVICE_KEY)" }

# Ham JSON ile cek: IRM diziyi bozup tek nesne verebiliyor (bu gece 2 kez yandik)
function CekListe([string]$uri){
  $h = Invoke-WebRequest -Uri $uri -Headers $SB -UseBasicParsing -TimeoutSec 180
  $m = if($h.RawContentStream){ [Text.Encoding]::UTF8.GetString($h.RawContentStream.ToArray()) } else { "$($h.Content)" }
  return @($m | ConvertFrom-Json)
}

# --- kasa ---
$kasa = New-Object System.Collections.Generic.List[object]
for($o=0; $o -lt 60000; $o+=1000){
  $r = CekListe "$U`?select=id,ders,konu,soru,siklar,dogru,aciklama,tablo,yevmiye,kaynak&order=id&limit=1000&offset=$o"
  if($r.Count -eq 0){ break }
  foreach($x in $r){ if($null -ne $x){ $kasa.Add($x) } }
  if($r.Count -lt 1000){ break }
}
Write-Host ("Kasa: {0} soru" -f $kasa.Count)
if($kasa.Count -lt 1000){ Write-Host "!! SUPHELI: kasa beklenenden kucuk - sayfalama kirik olabilir." }

# --- sozlesme denetleyicileri (aciklama-sozlesme-olcum.ps1 ile AYNI desenler) ---
$reNe=[regex]'(?i)ne\s+sorul'; $reKural=[regex]'(?i)(^|\n|\*|\||>)\s*kural\s*:'
$reOlay=[regex]'(?i)bu\s+olayda'; $reAkil=[regex]'(?i)ak[ıi]lda\s+kals[ıi]n'
$reTuzak=[regex]'(?i)tuzak\s*:|kar[ıi][sş]t[ıi]r'; $reDogrusu=[regex]'(?i)do[ğg]rusu\s*:'
$reHesapli=[regex]'(?i)ka[çc]\s*TL|ne\s+kadar|hesapla|tutar[ıi]n[ıi]|maliyet bedeli|amortisman|toplam[ıi]'
$reKayit=[regex]'(?i)yevmiye|kay[ıi]t|kaydeder|muhasebele[şs]tir|bor[çc]land|alacakland'
$reKarsi=[regex]'(?i)hangisi\s+do[ğg]rudur|a[şs]a[ğg][ıi]dakilerden\s+hangisi'
function Dolu($v){ if($null -eq $v){ return $false }; $s="$v"; if($s.Trim().Length -lt 5){ return $false }; return ($s -ne '{}' -and $s -ne '[]' -and $s -ne 'null') }

# --- her soru icin EKSIK LISTESI cikar ---
$isler = New-Object System.Collections.Generic.List[object]
foreach($s in $kasa){
  $a = $s.aciklama; if($null -eq $a){ continue }
  $dh = "$($s.dogru)".Trim().ToUpper()
  $dm = ""; try { if($a.PSObject.Properties[$dh]){ $dm = "$($a.$dh)" } } catch {}
  $eksik = @()
  $p = 0
  if($reNe.IsMatch($dm)){$p++}; if($reKural.IsMatch($dm)){$p++}
  if($reOlay.IsMatch($dm)){$p++}; if($reAkil.IsMatch($dm)){$p++}
  if($p -lt 4){ $eksik += 'D1_dort_parca' }
  $tz=0; $dg=0
  foreach($h in 'A','B','C','D','E'){
    if($h -eq $dh){ continue }
    $m=""; try { if($a.PSObject.Properties[$h]){ $m="$($a.$h)" } } catch {}
    if($m.Length -lt 5){ continue }
    if($reTuzak.IsMatch($m)){$tz++}; if($reDogrusu.IsMatch($m)){$dg++}
  }
  if($tz -lt 3){ $eksik += 'D2_tuzak' }
  if($dg -lt 3){ $eksik += 'D2_dogrusu' }
  $gv = "$($s.soru)"
  if($reHesapli.IsMatch($gv) -and -not (Dolu $s.tablo)){ $eksik += 'D7_tablo' }
  if($reKayit.IsMatch($gv)   -and -not (Dolu $s.yevmiye)){ $eksik += 'D7_yevmiye' }
  if($reKarsi.IsMatch($gv) -and -not $reHesapli.IsMatch($gv) -and -not (Dolu $s.tablo)){ $eksik += 'D8_karsilastirma' }
  if($eksik.Count -eq 0){ continue }
  $isler.Add([pscustomobject]@{ soru=$s; eksik=$eksik })
}
Write-Host ("Eksigi olan soru: {0}" -f $isler.Count)

# --- DAYANAK KAPISI (D4): kaynak metni ambarda yoksa soru ATLANIR ---
# Uydurma kanun/oran yasak; "Dogrusu" yalniz dayanak metninden turetilir.
$atlanan = New-Object System.Collections.Generic.List[object]
$hazir   = New-Object System.Collections.Generic.List[object]
$dayanakOnbellek = @{}
foreach($i in $isler){
  $kay = "$($i.soru.kaynak)".Trim()
  if($kay.Length -lt 6){ $atlanan.Add([ordered]@{ id="$($i.soru.id)"; sebep='kaynak etiketi yok' }); continue }
  if(-not $dayanakOnbellek.ContainsKey($kay)){
    $arama = [Uri]::EscapeDataString(($kay -replace '\s+',' '))
    try {
      $bul = CekListe "$DK`?select=kaynak_ad,metin&kaynak_ad=ilike.*$arama*&limit=1"
      $dayanakOnbellek[$kay] = $(if($bul.Count -gt 0){ "$($bul[0].metin)" } else { '' })
    } catch { $dayanakOnbellek[$kay] = '' }
  }
  $metin = $dayanakOnbellek[$kay]
  if($metin.Length -lt 40){ $atlanan.Add([ordered]@{ id="$($i.soru.id)"; sebep="dayanak ambarda cozulemedi: $kay" }); continue }
  $i | Add-Member -NotePropertyName dayanak -NotePropertyValue $metin -Force
  $hazir.Add($i)
  if($sinir -gt 0 -and $hazir.Count -ge $sinir){ break }
}
Write-Host ("Islenebilir: {0} | Atlanan (dayanaksiz): {1}" -f $hazir.Count, $atlanan.Count)

# --- ISTEM KURUCU: yalniz EKSIK olanlari ister ---
function IstemKur($i){
  $s = $i.soru
  $sik = ""
  foreach($h in 'A','B','C','D','E'){ if($s.siklar.PSObject.Properties[$h]){ $sik += "$h) $($s.siklar.$h)`n" } }
  $ist = @()
  if($i.eksik -contains 'D1_dort_parca'){ $ist += 'dort_parca: dogru sikkin aciklamasini SU DORT BASLIKLA yeniden yaz: "Ne soruluyor:", "Kural:", "Bu olayda:", "Akilda kalsin:". 400-700 karakter, gunluk dil, hic muhasebe bilmeyene anlatir gibi.' }
  if($i.eksik -contains 'D2_tuzak'){    $ist += 'tuzak: her YANLIS sik icin tuzagin ADINI koy — "TUZAK: <A> ile <B> karistiriliyor. <A> sudur; <B> ise budur."' }
  if($i.eksik -contains 'D2_dogrusu'){  $ist += 'dogrusu: her YANLIS sik aciklamasini "Dogrusu: <dayanaga dayali TEK cumle>" ile bitir.' }
  if($i.eksik -contains 'D7_tablo'){    $ist += 'tablo: hesap tablosu uret (kolonlar: kalem, tutar; son satir toplam).' }
  if($i.eksik -contains 'D7_yevmiye'){  $ist += 'yevmiye: yevmiye fisi uret (her satir: hesap adi VE KODU, borc, alacak; borc toplami = alacak toplami).' }
  if($i.eksik -contains 'D8_karsilastirma'){ $ist += 'tablo: karsilastirma tablosu uret (ayrimi yapilan kavramlar satir satir; sorunun konusu olan satiri "<-" ile isaretle).' }
@"
Sen bir SMMM sinav sorusu editorusun. ASAGIDAKI SORUYA YALNIZCA ISTENEN ALANLARI uret.

MUTLAK KURALLAR:
- Yazdigin her cumle YALNIZCA asagidaki DAYANAK METNINDEN turetilecek. Dayanakta
  olmayan kanun, madde, oran, tutar veya tarih YAZAMAZSIN. Emin degilsen o alani bos birak.
- "Bu sik yanlis cunku dogru cevap X" gibi cumle YASAK - ogretmez.
- Var olan dogru metni degistirme; yalnizca istenen alanlari uret.
- Ciktiyi SAF JSON ver, baska hicbir sey yazma.

DERS: $($s.ders) | KONU: $($s.konu)
KAYNAK: $($s.kaynak)

DAYANAK METNI:
$($i.dayanak.Substring(0, [Math]::Min(2500, $i.dayanak.Length)))

SORU:
$($s.soru)

SIKLAR:
$sik
DOGRU SIK: $($s.dogru)

URETILECEK ALANLAR:
$([string]::Join("`n", ($ist | ForEach-Object { "- $_" })))

CIKTI BICIMI (yalniz istenen anahtarlari doldur):
{"dort_parca":"...","tuzak":{"A":"...","B":"..."},"dogrusu":{"A":"...","B":"..."},"tablo":{"baslik":"...","kolonlar":["..."],"satirlar":[["..."]]},"yevmiye":[{"hesap":"100 KASA","borc":0,"alacak":0}]}
"@
}

# --- KURU MOD: ornek istemleri yaz, para harcama ---
if(-not $uygula){
  $sb = New-Object Text.StringBuilder
  $ornekSayi = [Math]::Min(10, $hazir.Count)
  for($n=0; $n -lt $ornekSayi; $n++){
    [void]$sb.AppendLine("=============== ORNEK $($n+1) / $ornekSayi ===============")
    [void]$sb.AppendLine("SORU ID : $($hazir[$n].soru.id)")
    [void]$sb.AppendLine("EKSIK   : $($hazir[$n].eksik -join ', ')")
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine((IstemKur $hazir[$n]))
    [void]$sb.AppendLine("")
  }
  Set-Content -LiteralPath $ornekYol -Value $sb.ToString() -Encoding UTF8
  $dagilim = @{}
  foreach($i in $hazir){ foreach($e in $i.eksik){ $dagilim[$e] = 1 + $dagilim[$e] } }
  $rapor = [ordered]@{
    tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); mod='KURU (0 USD)'
    kasa=$kasa.Count; eksigi_olan=$isler.Count; islenebilir=$hazir.Count
    atlanan_dayanaksiz=$atlanan.Count
    eksik_dagilimi=[ordered]@{}
    atlanan_ornek=@($atlanan | Select-Object -First 20)
    not='Hicbir API cagrisi YAPILMADI. veri/onarim-motor-ornek-istem.txt icindeki 10 ornek GOZLE okunacak; Cem onaylayinca -uygula -sinir 200 ile pilot kosulur.'
  }
  foreach($k in ($dagilim.Keys | Sort-Object)){ $rapor.eksik_dagilimi[$k] = $dagilim[$k] }
  Set-Content -LiteralPath $raporYol -Value (ConvertTo-Json -InputObject $rapor -Depth 5) -Encoding UTF8 -NoNewline
  Write-Host "`n=== KURU KOSU ==="
  foreach($k in ($dagilim.Keys | Sort-Object)){ Write-Host ("  {0,-20} {1}" -f $k, $dagilim[$k]) }
  Write-Host ("`n-> {0}`n-> {1}" -f $raporYol, $ornekYol)
  Write-Host "PARA HARCANMADI. Ornek istemler gozle kontrol edilecek."
  exit 0
}

# --- UYGULA: bu dal Cem'in acik onayindan ve 10 ornegin gozle kontrolunden
#     SONRA acilacak. Pilot olcumu yapilmadan tam parti kosulmaz. ---
Write-Host "UYGULA modu: API cagri katmani pilot onayindan sonra acilacak (sartname adim 4)."
Write-Host "Once: kuru kosu ornekleri Cem'e gosterilecek -> onay -> -uygula -sinir 200."
$rapor = [ordered]@{
  tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); mod='UYGULA - HENUZ ACIK DEGIL'
  islenebilir=$hazir.Count; atlanan_dayanaksiz=$atlanan.Count
  not='API katmani bilerek kapali: para harcayan ve kasaya yazan kod, 10 ornek gozle dogrulanmadan acilmayacak (ONARIM-MOTOR-SARTNAMESI adim 2-3).'
}
Set-Content -LiteralPath $raporYol -Value (ConvertTo-Json -InputObject $rapor -Depth 4) -Encoding UTF8 -NoNewline
exit 0
