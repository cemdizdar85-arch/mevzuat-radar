# ============================================================================
#  TERİM ÖLÇÜMÜ — kanun dili ↔ sınav dili (0 USD)
#
#  NEDEN VAR (04.09.2026, Cem "sınavda genel idare gideri çıkıyor mu?" → GM 3 "ölçümü robota bağla,
#  kapı listesi ölçümden beslensin, elle yazılmasın"): Üreticinin dil kapısındaki terim çiftleri artık bu
#  betiğin ÇIKTISINDAN okunur. Adaylar elle beslenir (veri/terim-adaylari.json: kanun dili, sınav dili adayı,
#  bire_bir bayrağı); KARAR ölçümle verilir: üç sınavın çıkmış kitapçıklarında sınav dili tarafı kanun dilinin
#  en az 5 katıysa ve çift bire birse → 'kapi'. Aksi → 'dokunma' (gerekçesiyle).
#
#  GİRDİ: veri/sgs-arsiv, veri/kgk-arsiv, veri/smmm-arsiv (*.duz.txt; gitignore'da, yalnız yerelde) +
#         veri/fabrika/kalip-parti-*.json (bizim sorular; kanun dilini kaç yerde kullanmışız)
#  ÇIKTI: veri/terim-ciftleri.json (RaporYaz: içerik değişmediyse dokunmaz) + veri/TERIM-CIFTLERI.md
#  KÖR: arşiv klasörü yoksa (GitHub runner) hiçbir şey yazılmaz, eski karar dosyası kalır, çıkış 0 + KÖR mesajı.
#  ÜRETİCİ: kalip-parti-uret.ps1 açılışta bu dosya 30 günden eskiyse ve arşiv yerelde varsa bu betiği koşar.
#  ZAMANLAYICI: gorev-kur.ps1 → "Tetikte - Terim olcumu" (haftalık, Pazartesi 08:10).
# ============================================================================
param([switch]$Sessiz)
$ErrorActionPreference='Stop'
$here=Split-Path -Parent $MyInvocation.MyCommand.Path
$kok=Split-Path -Parent $here
. (Join-Path $kok 'arac\rapor-yaz.ps1')
$adayDosya=Join-Path $kok 'veri\terim-adaylari.json'
$hedefJson=Join-Path $kok 'veri\terim-ciftleri.json'
$hedefMd=Join-Path $kok 'veri\TERIM-CIFTLERI.md'
$arsiv=[ordered]@{ SGS='sgs-arsiv'; KGK='kgk-arsiv'; SMMM='smmm-arsiv' }

# Türkçe büyük/küçük harf sınıflı desen ("genel idare gider" → [Gg]enel\s+[İi]dare\s+[Gg]ider); TAMAMEN BÜYÜK kısaltma → sınır korumalı
function TerimDesen([string]$s){
  $H='A-Za-zÇĞİÖŞÜçğıöşü'
  if($s.Length -le 5 -and $s -ceq $s.ToUpper([cultureinfo]::GetCultureInfo('tr-TR'))){ return "(?<![$H])"+[regex]::Escape($s)+"(?![$H])" }
  $sb=New-Object System.Text.StringBuilder
  foreach($ch in $s.ToCharArray()){
    switch -CaseSensitive ($ch){
      ' ' { [void]$sb.Append('\s+') }
      'i' { [void]$sb.Append('[iİ]') }
      'ı' { [void]$sb.Append('[ıI]') }
      'ö' { [void]$sb.Append('[öÖ]') }
      'ü' { [void]$sb.Append('[üÜ]') }
      'ş' { [void]$sb.Append('[şŞ]') }
      'ç' { [void]$sb.Append('[çÇ]') }
      'ğ' { [void]$sb.Append('[ğĞ]') }
      'â' { [void]$sb.Append('[âÂaA]') }
      default { $u=[string]$ch; if($u -match '[A-Za-z]'){ [void]$sb.Append('['+$u.ToLowerInvariant()+$u.ToUpperInvariant()+']') } else { [void]$sb.Append([regex]::Escape($u)) } }
    }
  }
  return "(?<![$H])"+$sb.ToString()
}

$adaylar=@((Get-Content $adayDosya -Raw -Encoding UTF8 | ConvertFrom-Json).adaylar)
if(-not $adaylar.Count){ throw "aday listesi boş: $adayDosya" }

# arşiv var mı? (yalnız yerelde)
$metin=[ordered]@{}; $kitap=[ordered]@{}
foreach($s in $arsiv.Keys){
  $d=Join-Path $kok "veri\$($arsiv[$s])"
  $files=@(); if(Test-Path $d){ $files=@(Get-ChildItem $d -Filter '*.duz.txt' -Recurse -ErrorAction SilentlyContinue) }
  $metin[$s]=@($files | ForEach-Object { [IO.File]::ReadAllText($_.FullName) }); $kitap[$s]=$files.Count
}
if(($kitap.Values | Measure-Object -Sum).Sum -lt 50){
  Write-Host "KÖR: çıkmış kitapçık arşivi bu makinede yok (SGS $($kitap['SGS']) / KGK $($kitap['KGK']) / SMMM $($kitap['SMMM'])). Karar dosyasına DOKUNULMADI." -ForegroundColor Yellow
  exit 0
}
# bizim sorular
$cacheM=New-Object System.Collections.Generic.List[string]
foreach($cf in (Get-ChildItem (Join-Path $kok 'veri\fabrika') -Filter 'kalip-parti-*.json' -ErrorAction SilentlyContinue)){
  try{ $c=Get-Content $cf.FullName -Raw -Encoding UTF8 | ConvertFrom-Json }catch{ continue }
  foreach($pp in $c.PSObject.Properties){ $v=$pp.Value; $t=@("$($v.soru)","$($v.hap)"); if($v.siklar){ foreach($h in 'A','B','C','D','E'){ $t+="$($v.siklar.$h)" } }; if($v.aciklama){ foreach($h in 'A','B','C','D','E'){ if($v.aciklama.PSObject.Properties[$h]){ $a=$v.aciklama.$h; $t+=$(if($a -is [string]){ $a } else { ($a.PSObject.Properties | ForEach-Object { "$($_.Value)" }) -join ' ' }) } } }; $cacheM.Add(($t -join ' ')) }
}
function Say([string[]]$docs,[string]$desen){ $n=0; $d=0; foreach($t in $docs){ $c=[regex]::Matches($t,$desen).Count; if($c){ $n+=$c; $d++ } }; return @{n=$n;d=$d} }

$ciftler=@(); $kapi=0
foreach($a in $adaylar){
  $dk=if($a.PSObject.Properties['desen_kanun'] -and $a.desen_kanun){ $a.desen_kanun } else { TerimDesen "$($a.kanun)" }
  $ds=TerimDesen "$($a.sinav)"
  $sayim=[ordered]@{}; $tK=0; $tS=0
  foreach($s in $arsiv.Keys){ $x=Say $metin[$s] $dk; $y=Say $metin[$s] $ds; $sayim[$s]=[ordered]@{ kanun=$x.n; kanun_kitapcik=$x.d; sinav=$y.n; sinav_kitapcik=$y.d }; $tK+=$x.n; $tS+=$y.n }
  $bk=Say $cacheM $dk; $bs=Say $cacheM $ds
  $bireBir=[bool]$a.bire_bir
  $karar='dokunma'; $gerekce=''
  if(-not $bireBir){ $gerekce='bire bir karşılık değil' + $(if($a.PSObject.Properties['not'] -and $a.not){ " ($($a.not))" } else { '' }) }
  elseif($tS -ge 5*[math]::Max(1,$tK)){ $karar='kapi'; $gerekce="sınav dili baskın ($tS / $tK)"; $kapi++ }
  elseif($tK -ge 5*[math]::Max(1,$tS)){ $gerekce="kanun dili baskın ($tK / $tS)" }
  else { $gerekce="ikisi de geçiyor ($tS / $tK)" }
  $ciftler+=[ordered]@{ ad="$($a.ad)"; kanun="$($a.kanun)"; sinav="$($a.sinav)"; desen_kanun=$dk; karsilik=$(if($a.PSObject.Properties['karsilik'] -and $a.karsilik){ "$($a.karsilik)" } else { "$($a.sinav)" }); bire_bir=$bireBir; sayim=$sayim; bizim=[ordered]@{ kanun=$bk.n; kanun_soru=$bk.d; sinav=$bs.n; sinav_soru=$bs.d }; karar=$karar; gerekce=$gerekce }
}
$cikti=[ordered]@{ olcum=(Get-Date -Format 'yyyy-MM-dd HH:mm'); kural='sınav dili ≥ 5× kanun dili VE bire_bir → kapi; kanun alıntısı (tırnak içi) dokunulmaz'; kitapcik=$kitap; bizim_soru=$cacheM.Count; kapi_sayisi=$kapi; ciftler=$ciftler }
$yazildi=RaporYaz -Hedef $hedefJson -Nesne $cikti -Derinlik 8 -Sessiz:$Sessiz

$md=New-Object System.Text.StringBuilder
[void]$md.AppendLine("# TERİM ÇİFTLERİ — kanun dili ↔ sınav dili")
[void]$md.AppendLine(""); [void]$md.AppendLine("Ölçüm: $($cikti.olcum) · kitapçık SGS $($kitap['SGS']) / KGK $($kitap['KGK']) / SMMM $($kitap['SMMM']) · bizim $($cacheM.Count) soru. Hücre = geçiş / kitapçık (bizim: geçiş / soru).")
[void]$md.AppendLine("Karar kuralı: $($cikti.kural). Adaylar: ``veri/terim-adaylari.json`` (elle), karar: ``veri/terim-ciftleri.json`` (bu betik). Üretici yalnız **kapi** olanları uygular."); [void]$md.AppendLine("")
[void]$md.AppendLine("| Çift | SGS kanun | SGS sınav | KGK kanun | KGK sınav | SMMM kanun | SMMM sınav | Bizim kanun | Bizim sınav | Karar |"); [void]$md.AppendLine("|---|---|---|---|---|---|---|---|---|---|")
foreach($c in $ciftler){ $s=$c.sayim; [void]$md.AppendLine("| $($c.ad) | $($s.SGS.kanun) / $($s.SGS.kanun_kitapcik) | $($s.SGS.sinav) / $($s.SGS.sinav_kitapcik) | $($s.KGK.kanun) / $($s.KGK.kanun_kitapcik) | $($s.KGK.sinav) / $($s.KGK.sinav_kitapcik) | $($s.SMMM.kanun) / $($s.SMMM.kanun_kitapcik) | $($s.SMMM.sinav) / $($s.SMMM.sinav_kitapcik) | $($c.bizim.kanun) / $($c.bizim.kanun_soru) | $($c.bizim.sinav) / $($c.bizim.sinav_soru) | **$($c.karar)** — $($c.gerekce) |") }
$eskiMd=if(Test-Path $hedefMd){ [IO.File]::ReadAllText($hedefMd,[Text.Encoding]::UTF8) } else { '' }
$yeniMd=$md.ToString()
if((($eskiMd -replace 'Ölçüm: [^·]+·','') -replace "`r`n","`n").Trim() -ne (($yeniMd -replace 'Ölçüm: [^·]+·','') -replace "`r`n","`n").Trim()){ [IO.File]::WriteAllText($hedefMd,$yeniMd,[Text.UTF8Encoding]::new($false)) }
if(-not $Sessiz){ Write-Host ("terim ölçümü: {0} aday · kapıya giren {1} · kitapçık {2}" -f $adaylar.Count,$kapi,(($kitap.Values | Measure-Object -Sum).Sum)) }
