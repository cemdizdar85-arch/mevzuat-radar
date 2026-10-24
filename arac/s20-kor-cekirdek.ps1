# arac/s20-kor-cekirdek.ps1 — BULUT KÖR KAPISININ ÇÖZÜCÜSÜ, ÜRETİCİNİN KENDİ KAYNAĞINDAN (24.10.2026, Cem: "aynı çözücü")
# Dot-source edilir (param() YOK). Kör istem, model, jeton tavanı, ayrıştırıcı ve cevap okuma KOPYALANMAZ:
# motor/kalip-parti-uret.ps1 her yüklemede AYRIŞTIRILIR (PowerShell AST) ve şu parçalar oradan alınır:
#   · $korIstem here-string'i (FAZ K istemi)            · $KOR_MAXTOK değeri          · param() içindeki $KorModel varsayılanı
#   · Coz + KorCoz işlevleri (kör yanıt ayrıştırıcısı)  · FAZ K döngüsündeki $sikM / $korEk='' / $istK deyimleri (istem kurulumu)
#   · aynı döngüdeki $cev / if($cev -match '^H') / $dm deyimleri (cevap harfi okuma + doğru mu)
# Üretici değişirse bu çekirdek de değişir; parça bulunamaz ya da birden çok çıkarsa YÜKLEME DÜŞER (sessiz sapma yok).
# KAYNAKSIZ KÖR: üreticinin -KorKaynak'sız yolu ($korEk='' deyimi; kaynak/açıklama/hap/teşhis verilmez). Effort: üretici
#   TopluTopla'ya '' verir → api-hedef Get-EffortDegeri (MEVZUAT_EFFORT yoksa medium); burada da '' verilir.
# Dışa açılanlar: S20KorIs $id $kayit → TopluTopla ile AYNI iş kaydı (@{id,model,icerik,maxTok,effort,faz})
#                 S20KorKarar $kayit $metin → $null (bozuk) ya da @{cevap; dogru_mu; sonuc; hesap; guven; kusur}
#                 $script:S20_KOR_IZ → çıkarılan parçaların SHA-256 izi (günlüğe basılır; eşdeğerlik sınamasında kıyaslanır)
# 🚫 GÖRMEZ: üreticinin "toplu cevap bozuk → bir kez ANLIK yeniden" yolu (burada hep toplu: bozuk cevap tuzlu ikinci toplu dalgaya gider)
#   · plan satırı korModel/korKaynak verirse üreticinin kullandığı değer (SGS s20 planlarında YOK, ölçüldü 24.10; varsayılan kullanılır).

$script:S20_URETICI = Join-Path (Split-Path -Parent $PSScriptRoot) 'motor/kalip-parti-uret.ps1'
$s20Tok = $null; $s20Hata = $null
$s20Ast = [System.Management.Automation.Language.Parser]::ParseFile($script:S20_URETICI, [ref]$s20Tok, [ref]$s20Hata)
if ($s20Hata -and @($s20Hata).Count) { throw "S20 KÖR: üretici ayrıştırılamadı: $(@($s20Hata)[0].Message)" }
function S20Tek($liste, [string]$ne) { $l = @($liste); if ($l.Count -ne 1) { throw "S20 KÖR: üreticide '$ne' $($l.Count) kez bulundu (1 bekleniyordu) — çekirdek üreticiyle uyumsuz, GÖNDERİLMEZ" }; return $l[0] }
function S20Atama($ast, [string]$sol) { return @($ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.AssignmentStatementAst] -and $n.Left.Extent.Text -eq $sol }, $true)) }

$s20Istem = S20Tek (S20Atama $s20Ast '$korIstem') '$korIstem='
$script:S20_KOR_ISTEM_SABLON = [string]$s20Istem.Right.Expression.Value
if (-not $script:S20_KOR_ISTEM_SABLON.StartsWith('Sen SMMM sınavına giren çok titiz bir adaysın.')) { throw 'S20 KÖR: $korIstem beklenen metinle başlamıyor (çıkarma bozuk)' }
$script:S20_KOR_MAXTOK = [int](S20Tek (S20Atama $s20Ast '$KOR_MAXTOK') '$KOR_MAXTOK=').Right.Expression.Value
$script:S20_KOR_MODEL = [string](S20Tek @($s20Ast.ParamBlock.Parameters | Where-Object { $_.Name.VariablePath.UserPath -eq 'KorModel' }) 'param KorModel').DefaultValue.Value
foreach ($s20Fn in 'Coz', 'KorCoz') {
  $s20F = S20Tek @($s20Ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -eq $s20Fn }, $true)) "function $s20Fn"
  . ([scriptblock]::Create($s20F.Extent.Text))
  Set-Variable -Scope Script -Name "S20_FN_$s20Fn" -Value $s20F.Extent.Text
}
$s20IstK = S20Tek (S20Atama $s20Ast '$istK') '$istK='
$s20Blok = $s20IstK.Parent
if ($s20Blok -isnot [System.Management.Automation.Language.StatementBlockAst]) { throw 'S20 KÖR: $istK deyimi beklenen döngü bloğunda değil' }
function S20Deyim($blok, [string]$bas) { return (S20Tek @($blok.Statements | Where-Object { $_.Extent.Text.StartsWith($bas) }) $bas).Extent.Text }
$script:S20_KOR_DEYIM = [ordered]@{
  sikM  = (S20Deyim $s20Blok '$sikM=')
  korEk = (S20Deyim $s20Blok "`$korEk=''")
  istK  = $s20IstK.Extent.Text
  cev   = (S20Deyim $s20Blok '$cev=')
  cevH  = (S20Deyim $s20Blok "if(`$cev -match '^H')")
  dm    = (S20Deyim $s20Blok '$dm=')
}
if ($script:S20_KOR_DEYIM.istK -notmatch "Replace\('\{KAYNAK\}',\`$korEk\)") { throw 'S20 KÖR: $istK deyimi beklenen biçimde değil' }
# istem kurucu + cevap okuyucu: deyimler üreticideki metnin AYNISI, aynı değişken adlarıyla çalışır ($cvp = soru kaydı)
. ([scriptblock]::Create(@"
function S20KorIstem(`$cvp){
  `$korIstem = `$script:S20_KOR_ISTEM_SABLON
  $($script:S20_KOR_DEYIM.sikM)
  $($script:S20_KOR_DEYIM.korEk)
  $($script:S20_KOR_DEYIM.istK)
  return `$istK
}
function S20KorKarar(`$cvp, [string]`$metin){
  `$aK = KorCoz `$metin
  if(-not `$aK -or -not `$aK.PSObject.Properties['cevap']){ return `$null }
  $($script:S20_KOR_DEYIM.cev)
  $($script:S20_KOR_DEYIM.cevH)
  $($script:S20_KOR_DEYIM.dm)
  return [pscustomobject]@{ cevap=`$cev; dogru_mu=`$dm; sonuc="`$(`$aK.sonuc)"; hesap="`$(`$aK.hesap)"; guven="`$(`$aK.guven)"; kusur="`$(`$aK.kusur)" }
}
"@))
# 24.10: $model verilirse AYNI istem + ayrıştırıcı o modelle (kalibrasyon emri cozucu_model); verilmezse üretimin KorModel'i
function S20KorIs([string]$id, $cvp, [string]$model = '') { return @{ id = $id; model = $(if ($model) { $model } else { $script:S20_KOR_MODEL }); icerik = (S20KorIstem $cvp); maxTok = $script:S20_KOR_MAXTOK; effort = ''; faz = 'K' } }
function S20Sha([string]$m) { $s = [Security.Cryptography.SHA256]::Create(); try { return (($s.ComputeHash([Text.Encoding]::UTF8.GetBytes($m)) | ForEach-Object { $_.ToString('x2') }) -join '') } finally { $s.Dispose() } }
$script:S20_KOR_IZ = S20Sha (@($script:S20_KOR_ISTEM_SABLON, $script:S20_FN_Coz, $script:S20_FN_KorCoz) + @($script:S20_KOR_DEYIM.Values) -join "`n#`n")
Remove-Variable s20Tok, s20Hata, s20Ast, s20Istem, s20IstK, s20Blok, s20F, s20Fn -ErrorAction SilentlyContinue
