# ============================================================================
#  B7 TANI ROBOTU — "kosucu cozum farki"nin kanitini toplar (03.08.2026)
#
#  NEDEN: denetim-500 KOSUCUDA 363 'ambarda-yok' + 134 'kanun-bulunamadi'
#  uretti; AYNI sorular YERELDE 267/267 cozuldu. Kok sebep bulunmadan yeni
#  hakem partisi ACILMAZ (kilitli kural). Bu robot ayni 12 bilinen-vakayi
#  KaynakCoz'dan gecirir ve HER ADIMIN kanitini dosyaya yazar:
#   - PS surumu + isletim sistemi (kosucu pwsh/linux, yerel 5.1/win farki)
#   - $H basligi SAGLAM mi (degisken-ezme sinifi: homoglif $u/$U dersi)
#   - ham baglanti testi: dokumanlar'a sabit bir imatch sorgusunun HTTP kodu
#     ve kayit sayisi
#   - her vaka icin KaynakCoz durum + metin uzunlugu
#  Cikti: veri/b7-tani.json (kosucuda) — yerelde: veri/b7-tani-yerel.json
#  PARA HARCAMAZ: yalniz okuma.
# ============================================================================
$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$ciktiAd = if($env:GITHUB_ACTIONS -eq 'true'){ 'veri/b7-tani.json' } else { 'veri/b7-tani-yerel.json' }
$cikti = Join-Path $kok $ciktiAd
$enc = New-Object Text.UTF8Encoding($false)
function Yaz($n){ [IO.File]::WriteAllText($cikti, (ConvertTo-Json -InputObject $n -Depth 6), $enc) }
trap {
  Yaz ([ordered]@{ tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); durum='HATA'; hata="$($_.Exception.Message)"; satir=$_.InvocationInfo.ScriptLineNumber })
  Write-Host ("HATA (satir {0}): {1}" -f $_.InvocationInfo.ScriptLineNumber, $_.Exception.Message); exit 1
}

# madde-coz kutuphanesini AYNEN denetim-500 gibi yukle (ayni kosullar)
. (Join-Path $here 'madde-coz.ps1') -kutuphane

# --- ortam kaniti
$ortam = [ordered]@{
  ps_surum   = "$($PSVersionTable.PSVersion)"
  ps_edition = "$($PSVersionTable.PSEdition)"
  isletim    = "$([System.Environment]::OSVersion.Platform)"
  actions    = "$env:GITHUB_ACTIONS"
  servis_key = [bool]$env:SUPABASE_SERVICE_KEY
}

# --- $H basligi saglam mi? (degisken-ezme kaniti)
$basligKanit = [ordered]@{
  tip = "$($H.GetType().Name)"
  anahtar_sayisi = $(if($H -is [hashtable]){ $H.Keys.Count } else { -1 })
  apikey_var = $(if($H -is [hashtable]){ $H.ContainsKey('apikey') } else { $false })
}

# --- ham baglanti: sabit imatch sorgusu (VUK m.323 - kesin var olan kayit)
$desen = '^VUK.*m\.323'
$hamUri = "$SB_URL/rest/v1/dokumanlar?select=kaynak_ad&kaynak_ad=imatch." + [uri]::EscapeDataString($desen) + "&limit=5"
$ham = [ordered]@{ uri = $hamUri }
try {
  $hw = Invoke-WebRequest -UseBasicParsing -Uri $hamUri -Headers $H -TimeoutSec 60
  $gv = if($hw.RawContentStream){ [Text.Encoding]::UTF8.GetString($hw.RawContentStream.ToArray()) } else { "$($hw.Content)" }
  $liste = @($gv | ConvertFrom-Json)
  $ham['http'] = [int]$hw.StatusCode
  $ham['kayit'] = $liste.Count
  $ham['ilk'] = $(if($liste.Count){ "$($liste[0].kaynak_ad)" } else { '' })
} catch {
  $ham['http'] = -1
  $ham['hata'] = "$($_.Exception.Message)"
  if($_.ErrorDetails -and $_.ErrorDetails.Message){ $ham['sunucu'] = "$($_.ErrorDetails.Message)" }
}

# --- 12 bilinen vaka (denetim-500'de BULUNAMADI cikan gercek kaynaklar)
$vakalar = @(
  '5510 sayılı Kanun m.50',
  '4857 sayılı İş Kanunu m.13',
  'VUK m.235',
  'TMS 21 p.1 - Amaç',
  'TFRS 10 p.1-3 - Amac',
  'TBK m.52',
  'SMMM K. (3568 s.K.) m.50 [1/2]',
  'Kamu Malî Yönetimi K. (5018 s.K.) m.3 [1/3]',
  '6356 sayılı Sendikalar ve Toplu İş Sözleşmesi Kanunu m.2/1-g',
  'BDS 501 madde 4',
  'VUK (213 s.K.) m.231 - Fatura nizamı [1/2]',
  '4054 sayılı Rekabet Kanunu m.6'
)
$sonuclar = @()
foreach($k in $vakalar){
  $v = [ordered]@{ kaynak = $k }
  try {
    $c = KaynakCoz $k ''
    $v['durum'] = "$($c.durum)"
    $v['metin_kr'] = $(if($c -and $c.metin){ "$($c.metin)".Length } else { 0 })
    $v['ad'] = "$($c.ad)"
  } catch {
    $v['durum'] = 'EXCEPTION'
    $v['hata'] = "$($_.Exception.Message)"
  }
  $sonuclar += ,$v
}
$cozulen = @($sonuclar | Where-Object { "$($_.durum)" -like 'cozuldu*' }).Count

Yaz ([ordered]@{
  tarih = (Get-Date -Format 'dd.MM.yyyy HH:mm')
  durum = 'TAMAM'
  ortam = $ortam
  baslik_kaniti = $basligKanit
  ham_sorgu = $ham
  vaka_sayisi = $vakalar.Count
  cozulen = $cozulen
  sonuclar = $sonuclar
})
Write-Host ("B7 TANI: {0}/{1} cozuldu | ham sorgu http={2} kayit={3} | PS {4}" -f $cozulen, $vakalar.Count, $ham['http'], $ham['kayit'], $ortam.ps_surum)
