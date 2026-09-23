#requires -Version 5.1
<#
================================================================================
  SMMM KONU–SORU UYUMU — MODEL KONTROLÜ (TOPLU)   23.09.2026 · ÜCRETLİ (Cem onaylı)

  Cem 23.09 "1.2.3 üçünü de yap": kelime ölçüsü (arac/smmm-konu-uyum-olc.ps1) bilinen 12 yanlış etiketin yalnız
  5'ini yakaladı → karar veremez. Bu betik her soruya HAKEMLE AYNI MODELİ (claude-sonnet-5, düşürülmez) sorar:
  "bu soru bu konuyu mu ölçüyor? değilse dersin konu listesinden hangisi?"
  ÖNCE KÜÇÜK ÖLÇÜM (kural 1): -Kume anahtar → yalnız elle okunmuş 82 soru (yanlış 12 + doğru 70), ≈0,2 USD.
  Model anahtarla tutarsa ve Cem onaylarsa -Kume kasa (2.717, ≈6,5 USD tahmin).
  HEP TOPLU: Message Batches (%50). Anlık çağrı YOK. Ekrana soru metni BASILMAZ.
  Bedel: sonuçların usage alanından hesaplanır (fiyat varsayımı: giriş 3 / çıkış 15 USD/M, toplu ×0,5 —
  Console'dan doğrulanmalı).
  ÇIKTI: veri/fabrika/smmm-konu-uyum-model-<kume>.json (kimlik, karar, önerilen konu, gerekçe — gitignore)
         veri/sinav/SMMM-KONU-UYUM-MODEL.md (sayılar + anahtar karnesi, soru metni YOK)
  🚫 GÖRMEZ: modelin kendi yanılgısı (anahtar karnesi bunu ölçer, yalnız 82 soruda).
================================================================================
#>
param([ValidateSet('anahtar', 'kasa')][string]$Kume = 'anahtar', [string]$Model = 'claude-sonnet-5', [int]$KonuListe = 80, [string]$ParcaId = '', [switch]$Kuru, [int]$AzamiToken = 1500, [switch]$EksikTamamla)
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$buDizin = $(if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path })
$kok = Split-Path -Parent $buDizin
. (Join-Path $buDizin 'smmm-yayin-sarti.ps1'); . (Join-Path $buDizin 'smmm-ders-adi.ps1')
$onay = SmmmOnayHarita $kok
$AK = "$($env:ANTHROPIC_API_KEY)"; if (-not $AK) { $AK = [Environment]::GetEnvironmentVariable('ANTHROPIC_API_KEY', 'User') }
if (-not "$AK".Trim()) { throw 'ANTHROPIC_API_KEY yok' }
$H = @{ 'x-api-key' = "$AK".Trim(); 'anthropic-version' = '2023-06-01' }

# anahtar
$yanlis = @{}; foreach ($p in (Get-Content (Join-Path $buDizin 'vitrin-haric.json') -Raw -Encoding UTF8 | ConvertFrom-Json).haric.PSObject.Properties) { if ("$($p.Value)" -match '^etiket') { $yanlis[$p.Name] = "$($p.Value)" } }
$dogru = @{}; foreach ($s in @(Get-Content (Join-Path $kok 'veri\sinav\kaydir-secim\vitrin-smmm-secim.json') -Raw -Encoding UTF8 | ConvertFrom-Json | ForEach-Object { $_ })) { $dogru["$($s.etiket)/$($s.id)"] = 1 }
# dersin konu listesi (kapsama tablosundan, son10 sırası)
$dersKonu = @{}
foreach ($r in (Import-Csv (Join-Path $kok 'veri\fabrika\smmm-kapsama.csv') -Encoding UTF8 | Where-Object { [int]$_.son10 -gt 0 -and $_.ders -notmatch '/' } | Sort-Object { [int]$_.son10 } -Descending)) {
  if (-not $dersKonu.ContainsKey($r.ders)) { $dersKonu[$r.ders] = New-Object System.Collections.Generic.List[string] }
  if ($dersKonu[$r.ders].Count -lt $KonuListe) { $dersKonu[$r.ders].Add("$($r.konu)") }
}
function TabloDersi([string]$d) { foreach ($k in $dersKonu.Keys) { if ($k -eq $d -or ($d -eq 'Meslek Hukuku' -and $k -like '*Meslek Hukuku')) { return $k } }; return $d }

$sorular = New-Object System.Collections.Generic.List[object]
foreach ($f in (Get-ChildItem (Join-Path $kok 'veri\fabrika') -Filter 'kalip-parti-smmm-*.json')) {
  $et = $f.BaseName -replace '^kalip-parti-', ''; if ($et -match '(^|-)pilot\d*(-|$)') { continue }
  $j = Get-Content $f.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
  foreach ($o in $j.PSObject.Properties) {
    if ($o.Name -notlike 'kp-*') { continue }; $v = $o.Value; if (-not $v -or -not $v.soru) { continue }
    $an = "$et/$($o.Name)"
    if ($Kume -eq 'anahtar') { if (-not ($yanlis.ContainsKey($an) -or $dogru.ContainsKey($an))) { continue } }
    elseif (-not (SmmmYayinSarti $an $v $onay).gecer) { continue }
    $sorular.Add([pscustomobject]@{ an = $an; ders = (TabloDersi (SmmmDersAdi $et $null)); v = $v })
  }
}
Write-Host "küme $Kume · soru $($sorular.Count) · model $Model"
if ($Kuru) { $gt = 0; foreach ($s in $sorular) { $gt += ("$($s.v.soru)".Length + 600) }; Write-Host ("KURU: gönderilmedi · kaba giriş ≈ {0:N0} kr" -f $gt); return }

$SISTEM = 'Sen SMMM Yeterlilik sınavı soru bankasının etiket denetçisisin. Görevin yalnız şu: verilen sorunun gerçekten ölçtüğü konu, soruya iliştirilmiş KONU ETİKETİ ile aynı mı? Sorunun doğru/yanlış olduğunu DEĞERLENDİRME. Soru etiketteki konuyu doğrudan ölçüyorsa EVET; etiketle ilgili ama esas olarak başka bir alt konuyu ölçüyorsa (ör. etiket "GÜG birinci dağıtım", soru kademeli ikinci dağıtım) HAYIR; ikisini de belirgin biçimde ölçüyorsa KISMEN. HAYIR ya da KISMEN ise, verilen konu listesinden soruya en uygun konuyu AYNEN yaz; listede uygun konu yoksa "LISTEDE_YOK". Yalnız şu JSON''u döndür: {"uyum":"EVET|HAYIR|KISMEN","dogru_konu":"...","gerekce":"en fazla 20 kelime"}'
# 23.09: -EksikTamamla → önceki sonuç dosyasında EVET/HAYIR/KISMEN alan soru yeniden gönderilmez (yalnız eksik + OKUNAMADI); sonuçlar birleşir
$onceki = @{}; $cikti0 = Join-Path $kok "veri\fabrika\smmm-konu-uyum-model-$Kume.json"
if ($EksikTamamla -and (Test-Path $cikti0)) { foreach ($o in @((Get-Content $cikti0 -Raw -Encoding UTF8 | ConvertFrom-Json) | ForEach-Object { $_ })) { if ("$($o.uyum)" -in 'EVET', 'HAYIR', 'KISMEN') { $onceki["$($o.an)"] = $o } } }
if ($onceki.Count) { $sorular = [System.Collections.Generic.List[object]]@($sorular | Where-Object { -not $onceki.ContainsKey($_.an) }); Write-Host "eksik tamamla: önceki geçerli $($onceki.Count) · gönderilecek $($sorular.Count)" }
$istekler = New-Object System.Collections.Generic.List[object]; $harita = @{}; $i = 0
foreach ($s in $sorular) {
  $i++; $cid = 'ku-{0:D5}' -f $i; $harita[$cid] = $s.an
  $liste = $(if ($dersKonu.ContainsKey($s.ders)) { ($dersKonu[$s.ders] -join ' | ') } else { '' })
  $sik = (@('A', 'B', 'C', 'D', 'E') | ForEach-Object { "$_) $($s.v.siklar.$_)" }) -join "`n"
  $metin = "DERS: $($s.ders)`nKONU ETİKETİ: $($s.v.konu)`n`nSORU:`n$($s.v.soru)`n$sik`nDOĞRU CEVAP: $($s.v.dogru)`n`nDERSİN KONU LİSTESİ:`n$liste"
  $istekler.Add(@{ custom_id = $cid; params = @{ model = $Model; max_tokens = $AzamiToken; system = $SISTEM; messages = @(@{ role = 'user'; content = $metin }) } })
}
$cikti = Join-Path $kok "veri\fabrika\smmm-konu-uyum-model-$Kume.json"
if (-not $ParcaId) {
  $govde = ConvertTo-Json -InputObject @{ requests = $istekler.ToArray() } -Depth 8 -Compress
  $r = Invoke-RestMethod -Method Post -Uri 'https://api.anthropic.com/v1/messages/batches' -Headers $H -ContentType 'application/json; charset=utf-8' -Body ([Text.Encoding]::UTF8.GetBytes($govde)) -TimeoutSec 300
  $ParcaId = "$($r.id)"
  # ödenmiş işin kaydı (çöküşte yeniden gönderme yok): kimlik haritası diske
  [IO.File]::WriteAllText("$cikti.bekleyen", (ConvertTo-Json -InputObject @{ parti = $ParcaId; harita = $harita; tarih = (Get-Date -Format 'yyyy-MM-dd HH:mm') } -Depth 4), (New-Object Text.UTF8Encoding $false))
  Write-Host "toplu parti gönderildi: $ParcaId ($($istekler.Count) istek) — kayıt: $cikti.bekleyen"
} else { $harita = @{}; $b = Get-Content "$cikti.bekleyen" -Raw -Encoding UTF8 | ConvertFrom-Json; foreach ($p in $b.harita.PSObject.Properties) { $harita[$p.Name] = "$($p.Value)" } }
do { Start-Sleep -Seconds 30; $d = Invoke-RestMethod -Uri "https://api.anthropic.com/v1/messages/batches/$ParcaId" -Headers $H -TimeoutSec 60 } while ("$($d.processing_status)" -ne 'ended')
$ham = Invoke-WebRequest -UseBasicParsing -Uri "$($d.results_url)" -Headers $H -TimeoutSec 300
$satir = [Text.Encoding]::UTF8.GetString($ham.RawContentStream.ToArray()) -split "`n" | Where-Object { $_.Trim() }
$sonuc = New-Object System.Collections.Generic.List[object]; $gTok = 0; $cTok = 0; $hata = 0
foreach ($l in $satir) {
  $x = $l | ConvertFrom-Json; $an = $harita["$($x.custom_id)"]
  if ("$($x.result.type)" -ne 'succeeded') { $hata++; continue }
  $gTok += [int]$x.result.message.usage.input_tokens; $cTok += [int]$x.result.message.usage.output_tokens
  $t = (@($x.result.message.content | Where-Object { $_.type -eq 'text' } | ForEach-Object { "$($_.text)" }) -join "`n"); $m = [regex]::Match($t, '\{[\s\S]*\}')   # 23.09: ilk blok "thinking" olabilir
  $k = $null; try { $k = $m.Value | ConvertFrom-Json } catch {}
  $sonuc.Add([pscustomobject][ordered]@{ an = $an; uyum = $(if ($k) { "$($k.uyum)" } else { 'OKUNAMADI' }); dogru_konu = $(if ($k) { "$($k.dogru_konu)" } else { '' }); gerekce = $(if ($k) { "$($k.gerekce)" } else { '' }) })
}
$bedel = ($gTok * 3 + $cTok * 15) / 1e6 * 0.5
[IO.File]::WriteAllText($cikti, (ConvertTo-Json -InputObject $sonuc.ToArray() -Depth 3), (New-Object Text.UTF8Encoding $false))
# anahtar karnesi
$ky = @($sonuc | Where-Object { $yanlis.ContainsKey($_.an) }); $kd = @($sonuc | Where-Object { $dogru.ContainsKey($_.an) })
$yakalanan = @($ky | Where-Object { $_.uyum -in 'HAYIR', 'KISMEN' }).Count; $dogruHayir = @($kd | Where-Object { $_.uyum -eq 'HAYIR' }).Count; $dogruKismen = @($kd | Where-Object { $_.uyum -eq 'KISMEN' }).Count; $okunamadi = @($sonuc | Where-Object { $_.uyum -eq 'OKUNAMADI' }).Count   # 23.09 K1: $yak/$yaK aynı değişkendi
$say = @{}; foreach ($s in $sonuc) { $say[$s.uyum] = 1 + [int]$say[$s.uyum] }
$oz = "MODEL KONU UYUMU ($Kume, $Model): soru $($sonuc.Count) · " + (($say.Keys | Sort-Object | ForEach-Object { "$_ $($say[$_])" }) -join ' · ') + " · hata $hata · token $gTok/$cTok · bedel ≈ $([Math]::Round($bedel, 3)) USD"
$karne = "ANAHTAR: yanlış etiketli $($ky.Count)'in $yakalanan'ini yakaladı (HAYIR/KISMEN) · doğru etiketli $($kd.Count)'de HAYIR $dogruHayir, KISMEN $dogruKismen · okunamayan $okunamadi"
$md = New-Object System.Collections.Generic.List[string]
$md.Add('# SMMM KONU–SORU UYUMU — model kontrolü'); $md.Add('')
$md.Add("> Türetilmiştir (``arac/smmm-konu-uyum-model.ps1``). $(Get-Date -Format 'dd.MM.yyyy HH:mm') · toplu parti ``$ParcaId`` · soru metni YOK"); $md.Add('')
$md.Add("**$oz**"); $md.Add(''); $md.Add("**$karne**"); $md.Add('')
$md.Add('| kimlik | anahtar | model | önerilen konu |'); $md.Add('|---|---|---|---|')
foreach ($s in ($sonuc | Where-Object { $yanlis.ContainsKey($_.an) -or ($dogru.ContainsKey($_.an) -and $_.uyum -ne 'EVET') })) { $md.Add("| $($s.an) | $(if ($yanlis.ContainsKey($s.an)) { 'YANLIŞ' } else { 'doğru' }) | $($s.uyum) | $($s.dogru_konu) |") }
[IO.File]::WriteAllText((Join-Path $kok 'veri\sinav\SMMM-KONU-UYUM-MODEL.md'), ($md -join "`r`n"), (New-Object Text.UTF8Encoding $false))
Remove-Item "$cikti.bekleyen" -ErrorAction SilentlyContinue
$oz; $karne
