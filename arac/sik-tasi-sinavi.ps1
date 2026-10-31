#requires -Version 5.1
<#
================================================================================
  ŞIK TAKASI (ŞIK DENGESİ / SikTasi) — ÖZ-SINAV + MUTASYON + EŞDEĞERLİK   31.10.2026 · bedel 0 · ağ yok (eşdeğerlik hariç)
  Cem 31.10: "şık kayınca açıklamadaki harfler de aynı eşleşmeyle değişsin, öz-sınavla göster."
  NİYE: motor/kalip-parti-uret.ps1 para harcayan hattır; ÇALIŞTIRILARAK denetlenmez (CLAUDE.md). Bu sınav betiği ÇALIŞTIRMAZ:
  gerçek SikTasi / SikTasiEngel / SikDengeDongu ve yardımcılarını AST ile çıkarıp sahte kayıtlarla çağırır. ⛔ REPLİKA YOK.
  Vakalar: "doğru cevap C" yeni harfe döner · "A sınıfı", "(a) bendi", "(A) bendi", "7/A seçeneği", "Ek A", "E-fatura", "Işık A.Ş." değişmez ·
  "A, B, D, E doğru" eşlenip dizilir · harf-ek uyumu (E'de → A'da) · satır başı "C: …" · sade.sinav / konu_giris / verilenler çevrilir ·
  kor_cozum_kaynakli düşer · teori_ikiz değişmez · belirsiz anma / formül harfi / kökte şık anması / ikizde harf / kısmi aralık /
  sayı-tarih şıkları (Ş8) / harf_sabit izi → takas YAPILMAZ, kayıt BİREBİR aynı · onarım koşusunda dengeleyici KAPALI · kasada yayındaki
  soru taşınmaz · SGS kaydı (şık başına yapılı adımlar + kapanış satırı) · KGK kaydı (parantezli kişi adı + "A ve C şıklarında").
  Mutasyon: SIKTASI_MUTASYON=<ad> her biri KIRMIZI düşmeli (-Mutasyon hepsini ayrı süreçte koşar).
  Eşdeğerlik: -Esdegerlik -Asama eski|yeni|dongu-eski|dongu-yeni [-Parca i/n] (ambarın TAMAMI, para yok; bkz. aşağı).
  🚫 GÖRMEZ: gerçek modelin yazdığı her kalıbı (vakalar elle yazıldı; eşdeğerlik ambardaki gerçek metinle sayar) · kasa yayın listesinin
   ağdan okunması (SikYayindakiKimlikler ağ ister; burada $null/küme verilerek döngü sınanır).
================================================================================
#>
param([switch]$Mutasyon,[switch]$Sessiz,[switch]$Esdegerlik,[string]$Asama='',[string[]]$Klasor=@(),[string]$Cikti='',[string]$UretimYolu='',[string]$EskiYol='',[string]$YayinDosya='',[string]$Parca='0/1')
$ErrorActionPreference='Stop'
$buDizin=$(if($PSScriptRoot){ $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path })
$kok=Split-Path -Parent $buDizin
$uretYol=$(if($UretimYolu){ $UretimYolu } else { [IO.Path]::Combine($kok,'motor','kalip-parti-uret.ps1') })   # Linux'ta (dogrula.yml, pwsh) ters bölü ayraç değildir
$MUT="$env:SIKTASI_MUTASYON"

if($Mutasyon){
  $KABUK=(Get-Process -Id $PID).Path
  & $KABUK -NoProfile -ExecutionPolicy Bypass -File $PSCommandPath -Sessiz; if($LASTEXITCODE -ne 0){ Write-Host 'MUTASYON koşulmadı: bozulmamış öz-sınav zaten KIRMIZI'; exit 1 }
  $ler=@('guvenli-yok','guclu-yok','ad-yok','formul-yok','sira-yok','onarim-acik','grup-yok','ikiz-yok','sabit-yok','uyum-yok','alan-dar','kor-kalir','engel-yok','yayin-yok','kok-yok','dizi-yok','adim-yapi-yok')
  $tutan=0
  foreach($m in $ler){ $env:SIKTASI_MUTASYON=$m; & $KABUK -NoProfile -ExecutionPolicy Bypass -File $PSCommandPath -Sessiz *> $null; $kr=($LASTEXITCODE -ne 0); if($kr){ $tutan++ }; Write-Host ("  mutasyon {0,-12} {1}" -f $m,$(if($kr){'KIRMIZI (doğru)'}else{'YEŞİL (SINAV KÖR!)'})) }
  $env:SIKTASI_MUTASYON=''
  Write-Host "MUTASYON: $tutan/$($ler.Count) mutasyon KIRMIZI"; if($tutan -ne $ler.Count){ exit 1 }; exit 0
}

# --- üretim dosyasındaki fonksiyonlar (tanım yüklemek kod çalıştırmaz) ---
function IslevYukle([string]$yol,[string[]]$yalniz=@()){
  $hata=$null; $ast=[System.Management.Automation.Language.Parser]::ParseFile($yol,[ref]$null,[ref]$hata)
  if($hata -and $hata.Count){ throw "ayrıştırılamadı: $yol" }
  $fonk=@($ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst] -and -not ($n.Parent.Parent -is [System.Management.Automation.Language.FunctionDefinitionAst]) },$true))
  $metinler=@(); foreach($f in $fonk){ if($yalniz.Count -and $yalniz -notcontains $f.Name){ continue }; $t=$f.Extent.Text
    if($MUT -eq 'yayin-yok' -and $f.Name -eq 'SikDengeDongu'){ $t=$t.Replace('if($null -eq $yayinda -or $yayinda.Contains("$etiket/$oid")){ continue }','') }
    $metinler+=,$t }
  return ,$metinler
}
# 13.09 sözlük değişkenleri (eski SikTasi bunları okur; eşdeğerlikte eski sürüm yüklenirken gerekir)
function EskiDegiskenler([string]$yol){
  $ast=[System.Management.Automation.Language.Parser]::ParseFile($yol,[ref]$null,[ref]$null)
  return @($ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.AssignmentStatementAst] -and "$($n.Left)" -like '$script:SIKHARF_*' },$true) | ForEach-Object { $_.Extent.Text })
}
foreach($t in (IslevYukle $uretYol)){ . ([scriptblock]::Create($t)) }
$SIK_ANA_METIN=[IO.File]::ReadAllText($uretYol)

# mutasyonlar: üretim fonksiyonunun kilit koşulu bilerek bozulur
switch($MUT){
  'guvenli-yok' { function SikGuvenliBaglam { return $false } }
  'guclu-yok'   { function SikGucluSag { return $false }; function SikGucluSol { return $false } }
  'ad-yok'      { function SikAdBaglam { return $false } }
  'formul-yok'  { function SikFormulBaglam { return $false } }
  'sira-yok'    { function SikSayiTarihSikli { return $false } }
  'onarim-acik' { function SikDengeKapaliMi { return $false } }
  'grup-yok'    { function SikGrupBagla { } }
  'ikiz-yok'    { function SikIkizAlanlari { return @() } }
  'sabit-yok'   { function SikHarfSabitMi { return $false } }
  'uyum-yok'    { function SikEkUyum([string]$harf,[string]$ek){ return $ek } }
  'alan-dar'    { function SikKayitAlanlari { return @('aciklama','teshis','celdirici_yol','adimlar','hap','sinav_taktigi','notlandirici','sema') } }
  'kor-kalir'   { function SikModelAlanlari { return @('kor_cozum','simulasyon','simulasyon_sonnet') } }
  'engel-yok'   { function SikTasiEngel { return '' } }
  'dizi-yok'    { function SikHarfDizisi { return '' } }
  'adim-yapi-yok' { function SikAdimYapiBozuk { return $false } }
  'kok-yok'     { $SIK_ANA_METIN=$SIK_ANA_METIN.Replace('-and -not $script:SIK_DENGE_KAPALI','') }
}

if($Esdegerlik){
  # ============================================================================================================================
  #  EŞDEĞERLİK (ambarın TAMAMI, örneklem değil; para yok). Aşamalar ayrı süreçte koşar (eski/yeni aynı adlı fonksiyonları taşır):
  #   eski|yeni   : HER soruda "takas olsaydı" — doğru harf → sıradaki harf (A→B … E→A). Satır: kimlik · engel · sonuç özeti · değişen alanlar
  #   dongu-eski  : gerçek SikDengeDongu + ESKİ SikTasi, yayın/engel yok (31.10 öncesi döngü)  ·  dongu-yeni: bugünkü kod, gerçek yayın listesi
  #                 (banka 0: yalnız parti içi denge). Satır: kimlik · değişti mi · doğru harf değişti mi
  #   -Parca i/n  : dosyaların i. dilimi (paralel koşu); birleştirme ve sayım çıktılar üzerinden yapılır
  # ============================================================================================================================
  $sha=[Security.Cryptography.SHA1]::Create()
  function Ozet([string]$t){ return ([BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($t))) -replace '-','').Substring(0,12) }
  $pi=[int]($Parca -split '/')[0]; $pn=[int]($Parca -split '/')[1]
  function Dosyalar{ $sira=0; foreach($k in $Klasor){ foreach($f in @(Get-ChildItem -LiteralPath $k -Filter 'kalip-parti-*.json' | Where-Object { $_.Name -notlike '*__sistem*' } | Sort-Object Name)){ if(($sira % $pn) -eq $pi){ $f }; $sira++ } } }
  function Sinavi([string]$et){ return ($et -split '-')[0].ToUpperInvariant() }
  $yaz=New-Object System.IO.StreamWriter($Cikti,$false,[Text.UTF8Encoding]::new($false))
  if($Asama -eq 'eski' -or $Asama -eq 'dongu-eski'){
    if(-not $EskiYol){ throw '-EskiYol gerekli' }
    foreach($t in (EskiDegiskenler $EskiYol)){ . ([scriptblock]::Create($t)) }
    foreach($t in (IslevYukle $EskiYol @('SikHarfEkUyumu','SikHarfCevirIc','SikHarfCevir','SikHarfKapanis','SikHarfDerin','AdimSikYapili','SikTasi','AdimHarfeBagliMi'))){ . ([scriptblock]::Create($t)) }
    function SikTasiEngel { return '' }
  }
  $HARF=@('A','B','C','D','E')
  if($Asama -eq 'eski' -or $Asama -eq 'yeni'){
    $n=0
    foreach($f in (Dosyalar)){
      $et=$f.BaseName.Substring(12); $j=ConvertFrom-Json ([IO.File]::ReadAllText($f.FullName))
      foreach($p in @($j.PSObject.Properties)){
        $c=$p.Value; if(-not ($c -is [pscustomobject]) -or -not $c.PSObject.Properties['siklar'] -or -not $c.siklar -or -not $c.PSObject.Properties['soru']){ continue }
        $dg="$($c.dogru)".Trim().ToUpperInvariant(); $ix=$HARF.IndexOf($dg)
        if($ix -lt 0){ $yaz.WriteLine("$et/$($p.Name)`t$(Sinavi $et)`tANAHTAR-YOK`t-`t"); continue }
        $hedef=$HARF[($ix+1)%5]
        $once=ConvertTo-Json $c -Depth 40 -Compress; $kop=ConvertFrom-Json $once
        $engel="$(SikTasi $kop $dg $hedef)"
        $alan=New-Object System.Collections.Generic.List[string]
        foreach($ad in @($kop.PSObject.Properties.Name)){
          if($ad -eq 'sade' -and $kop.sade -is [pscustomobject]){ foreach($sa in @($kop.sade.PSObject.Properties.Name)){ $alan.Add("sade.$sa=$(Ozet (ConvertTo-Json $kop.sade.$sa -Depth 30 -Compress))") } }
          else { $alan.Add("$ad=$(Ozet (ConvertTo-Json $kop.$ad -Depth 40 -Compress))") }
        }
        $yaz.WriteLine("$et/$($p.Name)`t$(Sinavi $et)`t$(if($engel){ $engel -replace '\t',' ' } else { 'TASINDI' })`t$($alan -join ';')")
        $n++
      }
    }
    $yaz.Close(); Write-Host "eşdeğerlik ${Asama}: $n soru → $Cikti"; exit 0
  }
  if($Asama -eq 'dongu-eski' -or $Asama -eq 'dongu-yeni'){
    $yayin=New-Object 'System.Collections.Generic.HashSet[string]'
    if($Asama -eq 'dongu-yeni'){ if(-not $YayinDosya){ throw '-YayinDosya gerekli' }; foreach($x in (ConvertFrom-Json ([IO.File]::ReadAllText($YayinDosya)))){ [void]$yayin.Add("$x") } }
    $banka=@{}; foreach($hh in $HARF){ $banka[$hh]=0 }
    $np=0
    foreach($f in (Dosyalar)){
      $et=$f.BaseName.Substring(12); $j=ConvertFrom-Json ([IO.File]::ReadAllText($f.FullName))
      $don=[ordered]@{}; $once=@{}
      foreach($p in @($j.PSObject.Properties)){ $don[$p.Name]=$p.Value; $once[$p.Name]=(ConvertTo-Json $p.Value -Depth 40 -Compress) }
      $cumleli=@($don.Keys | Where-Object { $cc=$don[$_]; $cc -is [pscustomobject] -and $cc.PSObject.Properties['soru'] -and $cc.soru -and $cc.PSObject.Properties['siklar'] -and $cc.siklar })
      if($cumleli.Count -ge 2){ $null=(SikDengeDongu $don $cumleli $banka $yayin $et) 6>$null }
      foreach($k in @($don.Keys)){
        $once1=$once[$k]; $sonra1=(ConvertTo-Json $don[$k] -Depth 40 -Compress)
        $dEski=$(if($once1 -match '"dogru":"([A-E])"'){ $Matches[1] } else { '' }); $dYeni="$($don[$k].dogru)"
        $yaz.WriteLine("$et/$k`t$(Sinavi $et)`t$([int]($once1 -ne $sonra1))`t$([int]($dEski -ne $dYeni -and $dEski))")
      }
      $np++
    }
    $yaz.Close(); Write-Host "eşdeğerlik ${Asama}: $np parti → $Cikti"; exit 0
  }
  throw "bilinmeyen aşama: $Asama"
}

# ================================== ÖZ-SINAV ==================================
$gecti=0; $dustu=New-Object System.Collections.Generic.List[string]
function T([string]$ad,[bool]$k){ if($k){ $script:gecti++; if(-not $Sessiz){ Write-Host "  ✓ $ad" } } else { $script:dustu.Add($ad); if(-not $Sessiz){ Write-Host "  ✗ $ad" } } }
function K([string]$json){ return (ConvertFrom-Json $json) }
function J($o){ return (ConvertTo-Json $o -Depth 30 -Compress) }

# R1 — SMMM olumsuz kök, doğru C → E (C↔E eşleşmesi)
$r1=K @'
{"soru":"Vergi Usul Kanunu'na göre aşağıdakilerden hangisi yanlıştır?","siklar":{"A":"a metni","B":"b metni","C":"c metni","D":"d metni","E":"e metni"},"dogru":"C",
 "aciklama":{"A":"Doğru ifade.","B":"Doğru ifade.","C":"Doğru cevap C çünkü süre bir aydır.","D":"Doğru.","E":"Doğru."},
 "hap":"A sınıfı tüccar defter tutar; THP 7/A seçeneği vardır. A'dan E'ye kadar oku.",
 "notlandirici":"A, B, D, E doğru; yalnız C yanlış.",
 "sinav_taktigi":"Kural:\nC: ilk bakışta doğru görünür",
 "sade":{"dogru":"C şıkkı süreyi yanlış verir.","siklar":{"A":"x","B":"y","D":"z","E":"w"},"sinav":"Sınavda C şıkkındaki tuzak sık gelir.","kavramlar":[{"ad":"süre","tanim":"(a) bendi uyarınca bir ay"}]},
 "konu_giris":{"desen":"Öğrenci çoğu kez C seçeneğine kayar."},
 "verilenler":[{"ad":"süre","anlam":"C şıkkı bu süreyi yanlış kullanır"}],
 "kor_cozum":{"cevap":"C"},"kor_cozum_kaynakli":{"cevap":"C"},"simulasyon_sonnet":{"dogru_mu":true},
 "teori_ikiz":{"soru":"İkiz soru","siklar":{"A":"1","B":"2","C":"3","D":"4","E":"5"},"dogru":"C","gerekce":"doğru cevap C dir"}}
'@
$r1n=SikTasi $r1 'C' 'E'
T 'R1 takas yapıldı (engel yok)' ($r1n -eq '' -and $r1.dogru -eq 'E')
T 'R1 şık metinleri yer değişti' ($r1.siklar.E -eq 'c metni' -and $r1.siklar.C -eq 'e metni')
T 'R1 "doğru cevap C" → "doğru cevap E"' ($r1.aciklama.E -eq 'Doğru cevap E çünkü süre bir aydır.')
T 'R1 "A sınıfı" + "7/A seçeneği" + "A''dan E''ye" DEĞİŞMEZ' ($r1.hap -eq "A sınıfı tüccar defter tutar; THP 7/A seçeneği vardır. A'dan E'ye kadar oku.")
T 'R1 "A, B, D, E doğru" → "A, B, C, D doğru", "yalnız C" → "yalnız E"' ($r1.notlandirici -eq 'A, B, C, D doğru; yalnız E yanlış.')
T 'R1 satır başı "C:" etiketi → "E:"' ($r1.sinav_taktigi -eq "Kural:`nE: ilk bakışta doğru görünür")
T 'R1 sade.dogru + sade.sinav çevrildi' ($r1.sade.dogru -eq 'E şıkkı süreyi yanlış verir.' -and $r1.sade.sinav -eq 'Sınavda E şıkkındaki tuzak sık gelir.')
T 'R1 sade.siklar anahtarı taşındı' ($r1.sade.siklar.C -eq 'w' -and -not $r1.sade.siklar.PSObject.Properties['E'])
T 'R1 "(a) bendi" DEĞİŞMEZ' ($r1.sade.kavramlar[0].tanim -eq '(a) bendi uyarınca bir ay')
T 'R1 konu_giris + verilenler çevrildi' ($r1.konu_giris.desen -eq 'Öğrenci çoğu kez E seçeneğine kayar.' -and $r1.verilenler[0].anlam -eq 'E şıkkı bu süreyi yanlış kullanır')
T 'R1 kor_cozum + kor_cozum_kaynakli + simülasyon düştü' (-not $r1.PSObject.Properties['kor_cozum'] -and -not $r1.PSObject.Properties['kor_cozum_kaynakli'] -and -not $r1.PSObject.Properties['simulasyon_sonnet'])
T 'R1 teori_ikiz (ayrı soru) DEĞİŞMEZ' ($r1.teori_ikiz.dogru -eq 'C' -and $r1.teori_ikiz.gerekce -eq 'doğru cevap C dir')

# R2 — A → E: A harfi takasın içinde; güvenli bağlamlar yine değişmez; harf-ek uyumu
$r2=K @'
{"soru":"Aşağıdakilerden hangisi doğrudur?","siklar":{"A":"birinci","B":"ikinci","C":"üçüncü","D":"dördüncü","E":"beşinci"},"dogru":"A",
 "aciklama":{"A":"Doğru cevap A.","B":"Yanlış.","C":"Yanlış.","D":"Yanlış.","E":"Yanlış."},
 "hap":"A sınıfı tüccar; (A) bendi ile (a) bendi ayrıdır; E-fatura zorunlu; THP 7/A seçeneği; Ek A tanımları; Eşik aşılırsa Işık A.Ş. öder.",
 "notlandirici":"En sık hata E'de."}
'@
$r2n=SikTasi $r2 'A' 'E'
T 'R2 takas yapıldı' ($r2n -eq '' -and $r2.dogru -eq 'E')
T 'R2 "Doğru cevap A." → "Doğru cevap E."' ($r2.aciklama.E -eq 'Doğru cevap E.')
T 'R2 "A sınıfı", "(A) bendi", "(a) bendi", "E-fatura", "7/A", "Ek A", "Işık A.Ş." DEĞİŞMEZ' ($r2.hap -eq 'A sınıfı tüccar; (A) bendi ile (a) bendi ayrıdır; E-fatura zorunlu; THP 7/A seçeneği; Ek A tanımları; Eşik aşılırsa Işık A.Ş. öder.')
T 'R2 harf-ek uyumu "E''de" → "A''da"' ($r2.notlandirici -eq "En sık hata A'da.")

# R3 — belirsiz: kök harfleri kişi adı olarak kullanıyor, açıklamada yalın "A" → takas YAPILMAZ, kayıt aynı
$r3=K @'
{"soru":"A ile B araç almak için görüşmüştür. Buna göre hangisi doğrudur?","siklar":{"A":"s1","B":"s2","C":"s3","D":"s4","E":"s5"},"dogru":"C",
 "aciklama":{"A":"Yanlış.","B":"Yanlış.","C":"Doğru cevap C: A haklıdır.","D":"Yanlış.","E":"Yanlış."}}
'@
$r3o=J $r3; $r3n=SikTasi $r3 'C' 'E'
T 'R3 harf adlı soruda belirsiz anma → takas YOK, kayıt birebir aynı' ($r3n -match 'BELİRSİZ' -and (J $r3) -eq $r3o)

# R4 — sıralı tarih şıkları (Ş8) → takas YOK
$r4=K '{"soru":"Son gün hangisidir?","siklar":{"A":"01.03.2025","B":"15.03.2025","C":"01.04.2025","D":"15.04.2025","E":"01.05.2025"},"dogru":"C","aciklama":{"C":"Doğru cevap C."}}'
$r4o=J $r4; $r4n=SikTasi $r4 'C' 'A'
T 'R4 sıralı tarih şıkları → takas YOK (Ş8), kayıt aynı' ($r4n -match 'Ş8' -and (J $r4) -eq $r4o)
$r4b=K '{"soru":"Tutar kaçtır?","siklar":{"A":"10.000 TL","B":"20.000 TL","C":"30.000 TL","D":"40.000 TL","E":"50.000 TL"},"dogru":"B"}'
T 'R4b sayı şıkları → takas YOK (Ş8)' ((SikTasi $r4b 'B' 'E') -match 'Ş8' -and $r4b.dogru -eq 'B')

# R5 — SGS: şık başına yapılı adımlar + kapanış satırı + çeldirici yolu, B → D
$r5=K @'
{"soru":"İşletmenin dönem kârı hangisidir?","siklar":{"A":"kâr azalır","B":"kâr artar","C":"etkilemez","D":"gider artar","E":"varlık azalır"},"dogru":"B",
 "celdirici_yol":{"A":"yol a","C":"yol c","D":"yol d","E":"yol e"},
 "adimlar":[{"sik":"A","karar":"yanlış","formul":"Şık A: kâr azalmaz","anlatim":"."},{"sik":"B","karar":"doğru","formul":"Şık B: kâr artar","anlatim":"Doğru şık B."},
            {"sik":"C","karar":"yanlış","formul":"Şık C: etkiler","anlatim":"."},{"sik":"D","karar":"yanlış","formul":"Şık D: gider sayılmaz","anlatim":"."},
            {"sik":"E","karar":"yanlış","formul":"Şık E: azalmaz","anlatim":"."},{"sik":"","formul":"Kapanış: A ✗ B ✓ C ✗ D ✗ E ✗","anlatim":"."}]}
'@
$r5n=SikTasi $r5 'B' 'D'
$adD=@($r5.adimlar | Where-Object { $_.sik -eq 'D' })[0]; $adB=@($r5.adimlar | Where-Object { $_.sik -eq 'B' })[0]
T 'R5 SGS takas yapıldı' ($r5n -eq '' -and $r5.dogru -eq 'D' -and $r5.siklar.D -eq 'kâr artar')
T 'R5 SGS adım içeriği yeni harfe taşındı ve "Şık B:" → "Şık D:"' ($adD.formul -eq 'Şık D: kâr artar' -and $adD.anlatim -eq 'Doğru şık D.' -and $adD.karar -eq 'doğru' -and $adB.formul -eq 'Şık B: gider sayılmaz')
T 'R5 SGS kapanış satırı eşlenip dizildi' ($r5.adimlar[5].formul -eq 'Kapanış: A ✗ B ✗ C ✗ D ✓ E ✗')
T 'R5 SGS çeldirici yolu anahtarı taşındı' ($r5.celdirici_yol.B -eq 'yol d' -and -not $r5.celdirici_yol.PSObject.Properties['D'])

# R6 — KGK: parantezli kişi adı DOKUNULMAZ, "C şıkkı" çevrilir, "A ve C şıklarında" bağlı liste
$r6=K @'
{"soru":"Bay (A), (B) A.Ş.'nin denetçisidir. Buna göre hangisi doğrudur?","siklar":{"A":"k1","B":"k2","C":"k3","D":"k4","E":"k5"},"dogru":"C",
 "aciklama":{"A":"Yanlış.","B":"Yanlış.","C":"C şıkkı doğrudur; Bay (A) bağımsız değildir.","D":"Yanlış.","E":"Yanlış."},
 "sade":{"dogru":"x","sinav":"A ve C şıklarında tuzak var."}}
'@
$r6n=SikTasi $r6 'C' 'E'
T 'R6 KGK takas yapıldı (güçlü anma + kişi adı)' ($r6n -eq '' -and $r6.dogru -eq 'E')
T 'R6 KGK "C şıkkı" → "E şıkkı", "Bay (A)" DEĞİŞMEZ' ($r6.aciklama.E -eq 'E şıkkı doğrudur; Bay (A) bağımsız değildir.')
T 'R6 KGK "A ve C şıklarında" → "A ve E şıklarında", kök değişmez' ($r6.sade.sinav -eq 'A ve E şıklarında tuzak var.' -and $r6.soru -eq "Bay (A), (B) A.Ş.'nin denetçisidir. Buna göre hangisi doğrudur?")

# R7 — ikiz harf anıyor → takas YOK
$r7=K '{"soru":"Hangisi doğrudur?","siklar":{"A":"a1","B":"b1","C":"c1","D":"d1","E":"e1"},"dogru":"C","ikiz":{"hedef_cumle":"Tabloyu doldur ve A şıkkındaki müdürü bul"}}'
$r7o=J $r7; T 'R7 ikiz harf anıyor → takas YOK' ((SikTasi $r7 'C' 'E') -match 'ikiz' -and (J $r7) -eq $r7o)
# R8 — formül harfi → takas YOK
$r8=K '{"soru":"Firma değeri kaçtır?","siklar":{"A":"artar","B":"azalır","C":"vergi kalkanı kadar artar","D":"değişmez","E":"yarıya iner"},"dogru":"C","aciklama":{"C":"Doğru cevap C; VL = VU + t x B"}}'
$r8o=J $r8; T 'R8 formül harfi ("t x B") → takas YOK' ((SikTasi $r8 'C' 'B') -match 'BELİRSİZ' -and (J $r8) -eq $r8o)
# R9 — harf_sabit izi → takas YOK
$r9=K '{"soru":"Hangisi doğrudur?","siklar":{"A":"a1","B":"b1","C":"c1","D":"d1","E":"e1"},"dogru":"C","harf_sabit":{"tarih":"2026-10-31","kaynak":"onarim-rehakem"},"aciklama":{"C":"Doğru cevap C."}}'
$r9o=J $r9; T 'R9 harf_sabit izi → takas YOK' ((SikTasi $r9 'C' 'E') -match 'HARF-SABİT' -and (J $r9) -eq $r9o)
# R10 — kısmi aralık → takas YOK
$r10=K '{"soru":"Hangisi doğrudur?","siklar":{"A":"a1","B":"b1","C":"c1","D":"d1","E":"e1"},"dogru":"C","hap":"B''den D''ye kadar olanlar elenir."}'
T 'R10 kısmi aralık "B''den D''ye" → takas YOK' ((SikTasi $r10 'C' 'E') -match 'BELİRSİZ' -and $r10.dogru -eq 'C')
# R11 — kökte şık anması → takas YOK
$r11=K '{"soru":"A şıkkındaki ifadeye göre hangisi doğrudur?","siklar":{"A":"a1","B":"b1","C":"c1","D":"d1","E":"e1"},"dogru":"C"}'
T 'R11 kökte şık anması → takas YOK' ((SikTasi $r11 'C' 'E') -match 'soru' -and $r11.dogru -eq 'C')

# R12 — yalın harf dizisi (konumsal etiket) → takas YOK
$r12=K '{"soru":"Hangisi doğrudur?","siklar":{"A":"a1","B":"b1","C":"c1","D":"d1","E":"e1"},"dogru":"C","sema":{"ogeler":{"secenekler":["A","B","C","D","E"],"degerler":["v1","v2","v3","v4","v5"]}}}'
$r12o=J $r12; T 'R12 yalın harf dizisi ["A",…,"E"] → takas YOK' ((SikTasi $r12 'C' 'E') -match 'dizi' -and (J $r12) -eq $r12o)

# R13 — SMMM boşluklu "ve" listesi + "… ve C'de" + cozum_tablo + sade.kavramlar, C → E
$r13=K @'
{"soru":"Hangisi yanlıştır?","siklar":{"A":"a1","B":"b1","C":"c1","D":"d1","E":"e1"},"dogru":"C",
 "aciklama":{"A":"Doğru.","B":"Doğru.","C":"Doğru cevap C.","D":"Doğru.","E":"Doğru."},
 "notlandirici":"A, B, D ve E doğrudur; yalnız C yanlış.",
 "hap":"Tuzak B ve C'de.",
 "cozum_tablo":{"basliklar":["Şık","Durum"],"satirlar":[["C şıkkı","süre yanlış"],["Sonuç","Doğru cevap C"]]},
 "sade":{"dogru":"x","kavramlar":[{"ad":"süre","tanim":"C şıkkındaki süre bir aydır"}]}}
'@
$r13n=SikTasi $r13 'C' 'E'
T 'R13 takas yapıldı' ($r13n -eq '' -and $r13.dogru -eq 'E')
T 'R13 "A, B, D ve E doğrudur" → "A, B, C ve D doğrudur"' ($r13.notlandirici -eq 'A, B, C ve D doğrudur; yalnız E yanlış.')
T 'R13 "B ve C''de" → "B ve E''de"' ($r13.hap -eq "Tuzak B ve E'de.")
T 'R13 cozum_tablo çevrildi' ($r13.cozum_tablo.satirlar[0][0] -eq 'E şıkkı' -and $r13.cozum_tablo.satirlar[1][1] -eq 'Doğru cevap E')
T 'R13 sade.kavramlar çevrildi' ($r13.sade.kavramlar[0].tanim -eq 'E şıkkındaki süre bir aydır')

# R14 — SGS kaydında aynı davranış: "B, C, D ve E şıkları" listesi, "C ve E'de", "A'da" ek uyumu, "A grubu" değişmez, A → C
$r14=K @'
{"soru":"Hangisi doğrudur?","siklar":{"A":"birinci","B":"ikinci","C":"üçüncü","D":"dördüncü","E":"beşinci"},"dogru":"A",
 "aciklama":{"A":"Doğru cevap A.","B":"Yanlış.","C":"Yanlış.","D":"Yanlış.","E":"Yanlış."},
 "notlandirici":"B, C, D ve E şıkları yanlıştır.",
 "hap":"Hata çoğunlukla C ve E'de, A'da değil. A grubu işlerde de aynı."}
'@
$r14n=SikTasi $r14 'A' 'C'
T 'R14 SGS takas yapıldı' ($r14n -eq '' -and $r14.dogru -eq 'C' -and $r14.aciklama.C -eq 'Doğru cevap C.')
T 'R14 SGS "B, C, D ve E şıkları" → "A, B, D ve E şıkları"' ($r14.notlandirici -eq 'A, B, D ve E şıkları yanlıştır.')
T 'R14 SGS "C ve E''de, A''da değil" → "A ve E''de, C''de değil", "A grubu" DEĞİŞMEZ' ($r14.hap -eq "Hata çoğunlukla A ve E'de, C'de değil. A grubu işlerde de aynı.")
$r14b=K '{"soru":"Oran kaçtır?","siklar":{"A":"%10","B":"%15","C":"%20","D":"%25","E":"%30"},"dogru":"C","aciklama":{"C":"Doğru cevap C."}}'
$r14bo=J $r14b; T 'R14b SGS yüzde şıkları → takas YOK (Ş8)' ((SikTasi $r14b 'C' 'A') -match 'Ş8' -and (J $r14b) -eq $r14bo)
$r14c=K '{"soru":"Hangisi doğrudur?","siklar":{"A":"birinci","B":"ikinci","C":"üçüncü","D":"dördüncü","E":"beşinci"},"dogru":"A","aciklama":{"A":"Doğru cevap A."},"hap":"A''da tuzak yok."}'
$r14co=J $r14c; T 'R14c SGS tanınmayan devam ("A''da tuzak") → BELİRSİZ, takas YOK, kayıt aynı' ((SikTasi $r14c 'A' 'C') -match 'BELİRSİZ' -and (J $r14c) -eq $r14co)

# R15 — KGK: A takasın içindeyken "Bay (A)" DEĞİŞMEZ, güçlü anma çevrilir
$r15=K @'
{"soru":"Bay (A) denetçidir. Buna göre hangisi doğrudur?","siklar":{"A":"k1","B":"k2","C":"k3","D":"k4","E":"k5"},"dogru":"A",
 "aciklama":{"A":"Doğru cevap A; Bay (A) bağımsız değildir.","B":"Yanlış.","C":"Yanlış.","D":"Yanlış.","E":"Yanlış."}}
'@
$r15n=SikTasi $r15 'A' 'C'
T 'R15 KGK "cevap A" → "cevap C", "Bay (A)" DEĞİŞMEZ (A takasta)' ($r15n -eq '' -and $r15.aciklama.C -eq 'Doğru cevap C; Bay (A) bağımsız değildir.' -and $r15.soru -eq 'Bay (A) denetçidir. Buna göre hangisi doğrudur?')

# R16 — 01.11 eşdeğerlikte ölçüldü (smmm-w9-2-fmuh-kolay/kp-09): iç içe adim dizisi → takas YOK, kayıt aynı, hata fırlatmaz (Stop altında koşuyu düşürüyordu)
$r16=K '{"soru":"Tutar hangisidir?","siklar":{"A":"gelir","B":"gider","C":"varlık","D":"borç","E":"sermaye"},"dogru":"A","adimlar":[[{"doldur":[],"formul":"Verilen: 600 hesabı","anlatim":"Kapanış: A ✓ B ✗ C ✗ D ✗ E ✗"}],[{"doldur":[],"formul":"x","anlatim":"y"}]]}'
$r16o=J $r16; $r16n=$null; try{ $r16n=SikTasi $r16 'A' 'C' }catch{ $r16n='HATA' }
T 'R16 iç içe adimlar → takas YOK, hata yok, kayıt aynı' ($r16n -match 'adimlar düz değil' -and (J $r16) -eq $r16o)

# Onarım koşusunda dengeleyici KAPALI
T 'ONARIM: pilot işareti → kapalı' ((SikDengeKapaliMi @('pilot:kp-01') '') -eq $true)
T 'ONARIM: onarım turu → kapalı' ((SikDengeKapaliMi @() 'r2') -eq $true)
T 'ONARIM: işaret yok → açık (yeni üretim)' ((SikDengeKapaliMi @() '') -eq $false -and (SikDengeKapaliMi @($null,'') '') -eq $false)
T 'ONARIM: üretim akışı kapıyı okuyor (SIK_DENGE_KAPALI)' ($SIK_ANA_METIN.Contains('$script:SIK_DENGE_KAPALI=SikDengeKapaliMi @($script:ONARIM_ISARETLERI) $OnarimTuru') -and $SIK_ANA_METIN.Contains('if($cumleli.Count -ge 2 -and -not $script:SIK_DENGE_KAPALI){') -and $SIK_ANA_METIN.Contains('$sikTasinan=SikDengeDongu $don $cumleli $bankaSay $sikYayinda $Etiket'))
$astAna=[System.Management.Automation.Language.Parser]::ParseInput($SIK_ANA_METIN,[ref]$null,[ref]$null)
$cagri=@($astAna.FindAll({ param($n) $n -is [System.Management.Automation.Language.CommandAst] -and $n.GetCommandName() -eq 'SikTasi' },$true))
$disarida=@($cagri | Where-Object { $p=$_.Parent; while($p -and -not ($p -is [System.Management.Automation.Language.FunctionDefinitionAst])){ $p=$p.Parent }; -not $p -or $p.Name -ne 'SikDengeDongu' })
T 'SikTasi yalnız SikDengeDongu içinden çağrılıyor (engel + yayın kapısının arkasında)' ($cagri.Count -ge 1 -and $disarida.Count -eq 0)

# Döngü: yayındaki / harf_sabit / yayın listesi okunamayan partide taşıma yok; yeni üretimde var
function Parti([string]$ek=''){ $d=[ordered]@{}; foreach($i in 1..5){ $d["kp-0$i"]=(K ('{"soru":"Hangisi doğrudur '+$i+'?","siklar":{"A":"birinci","B":"ikinci","C":"üçüncü","D":"dördüncü","E":"beşinci"},"dogru":"A","aciklama":{"A":"Doğru cevap A."}'+$ek+'}')) }; return $d }
$banka=@{ A=0; B=0; C=0; D=0; E=0 }; $bos=New-Object 'System.Collections.Generic.HashSet[string]'
$dp=Parti; $nT=(SikDengeDongu $dp @($dp.Keys) $banka $bos 'sgs-x') 6>$null
T "DÖNGÜ: yeni üretim partisi dengelenir ($nT taşıma)" ($nT -ge 1 -and @($dp.Values | Where-Object { $_.dogru -ne 'A' }).Count -eq $nT)
$dp=Parti; $hepsi=New-Object 'System.Collections.Generic.HashSet[string]'; foreach($k in $dp.Keys){ [void]$hepsi.Add("sgs-x/$k") }
T 'DÖNGÜ: kasada yayındaki soru taşınmaz' (((SikDengeDongu $dp @($dp.Keys) $banka $hepsi 'sgs-x') 6>$null) -eq 0)
$dp=Parti; T 'DÖNGÜ: yayın listesi okunamadı ($null) → taşıma yok' (((SikDengeDongu $dp @($dp.Keys) $banka $null 'sgs-x') 6>$null) -eq 0)
$dp=Parti ',"harf_sabit":{"tarih":"2026-10-31"}'; T 'DÖNGÜ: harf_sabit izli soru taşınmaz' (((SikDengeDongu $dp @($dp.Keys) $banka $bos 'sgs-x') 6>$null) -eq 0)
$dp=Parti ',"harf_sabit":{"tarih":"2026-10-31","kaynak":"onarim-rehakem"}'; T 'DÖNGÜ: SMMM partisinde harf_sabit izli soru taşınmaz' (((SikDengeDongu $dp @($dp.Keys) $banka $bos 'smmm-x') 6>$null) -eq 0)
$dp=Parti; $biri=New-Object 'System.Collections.Generic.HashSet[string]'; [void]$biri.Add('smmm-x/kp-01'); $nB=(SikDengeDongu $dp @($dp.Keys) $banka $biri 'smmm-x') 6>$null
T "DÖNGÜ: yayındaki kp-01 yerinde, öbürleri dengelenir ($nB taşıma)" ($dp['kp-01'].dogru -eq 'A' -and $nB -ge 1)

$top=$gecti+$dustu.Count
Write-Host ("ŞIK TAKASI ÖZ-SINAVI {0} ({1}/{2}){3}" -f $(if($dustu.Count -eq 0){'YEŞİL'}else{'KIRMIZI'}),$gecti,$top,$(if($MUT){" · SIKTASI_MUTASYON=$MUT"}else{''}))
if($dustu.Count){ if($Sessiz){ $dustu | ForEach-Object { Write-Host "  ✗ $_" } }; exit 1 }; exit 0
