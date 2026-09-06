# ============================================================================
#  KÂĞIT → KATMAN RAPORU (06.09.2026, Cem "1 yap": "en sık atlanan katman tablosu")
#  kagit_kayit tablosundaki hesap kâğıdı kayıtlarından ders/konu/soru bazında:
#  kayıt sayısı, doğru oranı, EN SIK ATLANAN tablo değeri (eksik), en sık tablo dışı
#  rakam (yanlış hesap adayı), çizim payı. Adım istemini düzeltmenin tek gerçek verisi.
#
#  Girdi: Supabase REST, SERVICE key (anon okuyamaz - RLS). Sayfalama ORDER'lı (30.08 dersi).
#  Çıktı: veri/kagit-katman-raporu.json (RaporYaz: zaman hariç aynıysa dosyaya dokunmaz)
#         + veri/KAGIT-KATMAN-RAPORU.md (okunur tablo).
#  Tablo basılmamışsa (PGRST205) rapor "TABLO YOK" der ve 0 ile çıkar - hafızadan "var/yok" yok.
#  Eşik: konu başına en az 5 kayıt yoksa o satır "az veri" işaretlenir (rakam yorumlanmaz).
# ============================================================================
param([int]$Esik=5,[int]$Sayfa=1000)
$ErrorActionPreference='Stop'
[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12
$here=Split-Path -Parent $MyInvocation.MyCommand.Path
$depoKok=Split-Path -Parent $here
. (Join-Path $depoKok 'arac\rapor-yaz.ps1')
$KEY=$env:SUPABASE_SERVICE_KEY; if(-not $KEY){ throw 'SUPABASE_SERVICE_KEY yok.' }
$H=@{ apikey=$KEY; Authorization="Bearer $KEY"; 'User-Agent'='mevzuat-radar-robot/1.0' }
$SB='https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/kagit_kayit'
$hedefJson=Join-Path $depoKok 'veri\kagit-katman-raporu.json'
$hedefMd=Join-Path $depoKok 'veri\KAGIT-KATMAN-RAPORU.md'

# --- çek (order + range ile sayfalı) -----------------------------------------
$kayit=New-Object System.Collections.Generic.List[object]; $ofs=0; $tabloYok=$false
while($true){
  $u="$SB`?select=soru_id,ders,konu,secim,dogru,dogru_mu,satir_sayisi,cizim_var,tabloda,eksik,tablo_disi,tablo_n,oturum,olusturma&order=id.asc&offset=$ofs&limit=$Sayfa"
  try{ $r=Invoke-WebRequest -UseBasicParsing -Uri $u -Headers $H -TimeoutSec 60; $c=$r.Content; if($c -is [byte[]]){ $c=[Text.Encoding]::UTF8.GetString($c) }; $p=@(($c | ConvertFrom-Json)) }
  catch{ $m="$($_.Exception.Message)"; if($m -match '404|PGRST205'){ $tabloYok=$true; break }; throw }
  foreach($x in $p){ $kayit.Add($x) }
  if($p.Count -lt $Sayfa){ break }; $ofs+=$Sayfa
}
if($tabloYok){
  $cikti=[ordered]@{ olcum=(Get-Date -Format 'yyyy-MM-dd HH:mm'); durum='TABLO YOK'; not='kagit_kayit basılmamış (radar-app/sql/2026-09-06-kagit-kayit.sql) — Cem Supabase SQL Editor''de bir kez çalıştıracak'; kayit=0 }
  RaporYaz -Hedef $hedefJson -Nesne $cikti
  [IO.File]::WriteAllText($hedefMd,"# KÂĞIT → KATMAN RAPORU`n`n**TABLO YOK** — `kagit_kayit` basılmamış. UYGULANDI.md satırı ⏳. Ölçüm: $($cikti.olcum)`n",[Text.UTF8Encoding]::new($false))
  "TABLO YOK (kagit_kayit) - SQL basılmadan rapor üretilemez"; exit 0
}
"kayıt: $($kayit.Count)"

# --- topla --------------------------------------------------------------------
function EnSik($dizi){ $g=@($dizi | Where-Object { "$_" -ne '' } | Group-Object | Sort-Object Count -Descending); if($g.Count){ return @{ deger="$($g[0].Name)"; adet=$g[0].Count } }; return $null }
$satirlar=New-Object System.Collections.Generic.List[object]
foreach($g in ($kayit | Group-Object { "$($_.ders)|$($_.konu)|$($_.soru_id)" } | Sort-Object Count -Descending)){
  $r=$g.Group; $n=$r.Count
  $dogru=@($r | Where-Object { $_.dogru_mu -eq $true }).Count
  $eksikler=@(); foreach($x in $r){ foreach($e in @($x.eksik)){ $eksikler+="$e" } }
  $disi=@(); foreach($x in $r){ foreach($e in @($x.tablo_disi)){ $disi+="$e" } }
  $enEksik=EnSik $eksikler; $enDisi=EnSik $disi
  $cizim=@($r | Where-Object { $_.cizim_var -eq $true }).Count
  $tamKagit=@($r | Where-Object { $_.tablo_n -gt 0 -and @($_.eksik).Count -eq 0 }).Count
  $satirlar.Add([ordered]@{ ders="$($r[0].ders)"; konu="$($r[0].konu)"; soru_id="$($r[0].soru_id)"; kayit=$n; az_veri=($n -lt $Esik); dogru_yuzde=[int][math]::Round(100*$dogru/$n);
    en_sik_atlanan=$(if($enEksik){ $enEksik.deger } else { '' }); atlanan_adet=$(if($enEksik){ $enEksik.adet } else { 0 }); atlanan_yuzde=$(if($enEksik){ [int][math]::Round(100*$enEksik.adet/$n) } else { 0 });
    en_sik_tablo_disi=$(if($enDisi){ $enDisi.deger } else { '' }); tablo_disi_adet=$(if($enDisi){ $enDisi.adet } else { 0 });
    tam_kagit_yuzde=[int][math]::Round(100*$tamKagit/$n); cizim_yuzde=[int][math]::Round(100*$cizim/$n); oturum=@($r | ForEach-Object { $_.oturum } | Select-Object -Unique).Count })
}
$dersOzet=@(); foreach($g in ($kayit | Group-Object ders)){ $r=$g.Group; $dersOzet+=[ordered]@{ ders="$($g.Name)"; kayit=$r.Count; dogru_yuzde=[int][math]::Round(100*@($r | Where-Object { $_.dogru_mu -eq $true }).Count/$r.Count); cizim_yuzde=[int][math]::Round(100*@($r | Where-Object { $_.cizim_var -eq $true }).Count/$r.Count) } }
$cikti=[ordered]@{ olcum=(Get-Date -Format 'yyyy-MM-dd HH:mm'); durum='OK'; kayit=$kayit.Count; esik=$Esik; ders=$dersOzet; konular=$satirlar.ToArray() }
RaporYaz -Hedef $hedefJson -Nesne $cikti

# --- MD -----------------------------------------------------------------------
$md=New-Object System.Text.StringBuilder
[void]$md.AppendLine("# KÂĞIT → KATMAN RAPORU ($($cikti.olcum)) · $($kayit.Count) kayıt")
[void]$md.AppendLine("Kaynak: kagit_kayit (Kaydır-Çöz ✏️ hesap kâğıdı, cevap anında). Eksik = çözüm tablosunda var, adayın kâğıdında yok = ATLANAN KATMAN. Tablo dışı = kâğıtta var, tabloda yok = yanlış hesap adayı. Konu başına $Esik kayıttan az ise 'az veri', yorumlanmaz.")
[void]$md.AppendLine(""); [void]$md.AppendLine("| Ders | Kayıt | Doğru % | Çizim % |"); [void]$md.AppendLine("|---|---:|---:|---:|")
foreach($d in $dersOzet){ [void]$md.AppendLine("| $($d.ders) | $($d.kayit) | $($d.dogru_yuzde) | $($d.cizim_yuzde) |") }
[void]$md.AppendLine(""); [void]$md.AppendLine("| Ders | Konu | Soru | Kayıt | Doğru % | En sık atlanan | Atlayan % | En sık tablo dışı | Tam kâğıt % |"); [void]$md.AppendLine("|---|---|---|---:|---:|---|---:|---|---:|")
foreach($s in $satirlar){ $az=$(if($s.az_veri){ ' ⚠ az veri' } else { '' }); [void]$md.AppendLine("| $($s.ders) | $($s.konu) | $($s.soru_id)$az | $($s.kayit) | $($s.dogru_yuzde) | $($s.en_sik_atlanan) | $($s.atlanan_yuzde) | $($s.en_sik_tablo_disi) | $($s.tam_kagit_yuzde) |") }
[IO.File]::WriteAllText($hedefMd,$md.ToString(),[Text.UTF8Encoding]::new($false))
"rapor: $hedefMd · konu satırı $($satirlar.Count)"
