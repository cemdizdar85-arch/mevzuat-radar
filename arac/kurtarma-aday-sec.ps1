# KURTARMA ADAY SEÇİCİ (08.09, SORU-BASMA-KURALLARI B1) — 0 USD
# Eski SGS dökümünden (eski-sgs-dump) huninin ADAY saydığı soruları (kapı-temiz ∧ damgalı ∧ pencerede) ders ders çeker,
# FAZ U'nun okuyacağı dosyayı yazar: veri/fabrika/kurtarma-aday-<etiket>.json (id, soru, siklar, dogru, aciklama, konu, ders, kanun_no, madde_no, madde_damga, kaynak, hap).
# Sıra: hesap sorusu (sayı şıklı) önce, sonra çıkmış dönem sayısı; -Adet ile kesilir. Ölçüm için -Adet 10.
param([Parameter(Mandatory=$true)][string]$Ders,[string]$Etiket='',[int]$Adet=10,[switch]$YalnizHesap)
$ErrorActionPreference='Stop'
$kok=Split-Path $PSScriptRoot -Parent
$dump=(Get-ChildItem (Join-Path $kok 'veri\fabrika') -Filter 'eski-sgs-dump-*.json' | Sort-Object LastWriteTime -Descending | Select-Object -First 1).FullName
$huniYol=(Get-ChildItem (Join-Path $kok 'veri\fabrika') -Filter 'eski-sgs-huni-*.json' | Sort-Object LastWriteTime -Descending | Select-Object -First 1).FullName
$d=@(ConvertFrom-Json -InputObject (Get-Content $dump -Raw -Encoding UTF8)); if($d.Count -eq 1 -and $d[0].PSObject.Properties['SyncRoot']){ $d=@($d[0].SyncRoot) }
$h=ConvertFrom-Json -InputObject (Get-Content $huniYol -Raw -Encoding UTF8)
$aday=@{}; foreach($a in @($h.adayIdler)){ if("$($a.ders)" -eq $Ders){ $aday["$($a.id)"]=$a } }
function SayiSikli($s){ $n=0; foreach($hh in 'A','B','C','D','E'){ if("$($s.siklar.$hh)" -match '^\s*%?\s*-?\d[\d.,]*\s*(TL|₺|%|adet|kg|gün|yıl|ay|saat|birim)?\s*$'){ $n++ } }; return ($n -ge 4) }
$sec=@(); foreach($s in $d){ if(-not $aday.ContainsKey("$($s.id)")){ continue }; $hes=SayiSikli $s; if($YalnizHesap -and -not $hes){ continue }
  $sec+=[pscustomobject]@{ id="$($s.id)"; soru="$($s.soru)"; siklar=$s.siklar; dogru="$($s.dogru)"; aciklama=$s.aciklama; konu="$($s.konu)"; ders="$($s.ders)"; kanun_no="$($s.kanun_no)"; madde_no="$($s.madde_no)"; madde_damga="$($s.madde_damga)"; kaynak="$($s.kaynak)"; hap="$($s.hap)"; zorluk="$($s.zorluk)"; hesap=$hes } }
$sec=@($sec | Sort-Object { -[int]$_.hesap }, { "$($_.id)" } | Select-Object -First $Adet)
if(-not $Etiket){ $Etiket='sgs-kurtarma-'+(($Ders -creplace '[^A-Za-z]','').ToLowerInvariant()) }
$out=Join-Path $kok "veri\fabrika\kurtarma-aday-$Etiket.json"
[IO.File]::WriteAllText($out,(ConvertTo-Json -InputObject @($sec) -Depth 6),[Text.UTF8Encoding]::new($false))
"yazildi: $out · $($sec.Count) aday (hesap $(@($sec | Where-Object { $_.hesap }).Count) · teori/kayıt $(@($sec | Where-Object { -not $_.hesap }).Count)) · ders '$Ders' aday havuzu $($aday.Count)"
$sec | ForEach-Object { "  $($_.id.Substring(0,8)) · $($_.konu) · $(if($_.hesap){'hesap'}else{'teori'}) · $($_.madde_damga)" }
