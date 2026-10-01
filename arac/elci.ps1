<#
  ELÇİ YÖNETİMİ — 29.09.2026 (Cem: "sadece bu kişiye vermeyeceğiz" + "elçiler için özel platform")

  Elçi eklemek, kodu kapatmak, bağlama kodu üretmek, ödeme işaretlemek ve dönem raporunu okumak için
  TEK araç. Supabase'e SERVİS anahtarıyla yazar (kullanıcı ortam değişkeni SUPABASE_SERVICE_KEY);
  anahtar ekrana, dosyaya, günlüğe YAZILMAZ. Yalnız bu makinede koşar — Actions'a konmaz
  (elçi adı/e-postası kişi verisidir, depo ve Actions günlüğü public).

  Tablolar: radar-app/sql/2026-09-15-elci-programi.sql (basılmadan araç "tablo yok" der ve durur).

  Kullanım:
    elci.ps1 -Ekle -AdSoyad "Cemal Hoca 06" [-Kod CH47] [-Eposta x@y.com] [-Instagram hesap] [-NotYazi "..."]
        → elçi satırı + 14 gün geçerli BAĞLAMA KODU (yalnız bir kez ekrana basılır; özeti tabloya yazılır)
          -Kod verilmezse KOD BİÇİMİYLE üretilir (baş harf + 2 rakam, aşağıda)
    elci.ps1 -KodOnerisi -AdSoyad "Adile Ersoy"   → çevrimdışı kod önerisi (tabloya bakmaz)
    elci.ps1 -BagKoduYenile -Kod CEMALHOCA     → yeni bağlama kodu (eski geçersiz olur; hesap bağlıysa önce bağı çözer: -BagiCoz)
    elci.ps1 -Liste                             → kod · ad · aktif · bağlı mı · koşul onayı · ödeme bilgisi
    elci.ps1 -Pasif -Kod X  /  -Aktif -Kod X    → kodu kapat / aç (geçmiş satışlar raporda kalır)
    elci.ps1 -OdemeBilgisi -Kod X               → "IBAN e-postayla geldi" işareti (IBAN tabloya YAZILMAZ)
    elci.ps1 -Odeme -Kod X -Donem "SGS 2026-3" -Tutar 4500 [-NotYazi "..."]  → ödeme kaydı (panelde görünür)
    elci.ps1 -Rapor                             → elci_donem_raporu (adet/komisyon; alıcı bilgisi yok)
    elci.ps1 -Dogrula                           → SQL basıldıktan sonra a–e denetimi (anonim uç kapalı mı,
                                                   indirim tablosu fiyat-motoru.js ile aynı mı)

  Bu araç şunu GÖRMEZ: siparişin gerçekten ödenip ödenmediği (o panelden 'odendi' işaretiyle gelir) ·
  aynı kişinin farklı e-postayla kendi koduyla alması (yalnız sözleşme + göz kontrolü).
#>
param(
  [switch]$Ekle, [switch]$BagKoduYenile, [switch]$BagiCoz, [switch]$Liste, [switch]$Pasif, [switch]$Aktif,
  [switch]$OdemeBilgisi, [switch]$Odeme, [switch]$Rapor, [switch]$Dogrula, [switch]$KodOnerisi,
  [string]$Kod, [string]$AdSoyad, [string]$Eposta, [string]$Instagram, [string]$NotYazi,
  [string]$Donem, [int]$Tutar = -1
)
$ErrorActionPreference = 'Stop'
$PSDefaultParameterValues['Invoke-RestMethod:UserAgent'] = 'mevzuat-radar-robot/1.0'   # kimlik-denetimi.ps1 (02.10)
$PSDefaultParameterValues['Invoke-WebRequest:UserAgent'] = 'mevzuat-radar-robot/1.0'
[Console]::OutputEncoding = [Text.Encoding]::UTF8

$SUPA_KOK  = 'https://bjrleanjpyujtajmazxn.supabase.co/rest/v1'
$ANON_ANAH = 'sb_publishable_kTZpYwrL7skw8Ryj5Vs8_Q_-5_Fhkcg'   # herkese açık anahtar (sitede de yazılı)
$DEPO_KOKU = Split-Path -Parent $PSScriptRoot

function ServisBasligi {
  $anahtarDegeri = "$($env:SUPABASE_SERVICE_KEY)".Trim()
  if (-not $anahtarDegeri) { $anahtarDegeri = "$([Environment]::GetEnvironmentVariable('SUPABASE_SERVICE_KEY','User'))".Trim() }
  if (-not $anahtarDegeri) { Write-Host 'SUPABASE_SERVICE_KEY yok (kullanıcı ortam değişkeni).'; exit 1 }
  return @{ apikey = $anahtarDegeri; Authorization = "Bearer $anahtarDegeri" }
}

<#
  KOD BİÇİMİ (29.09, Cem "isim değil baş harf + rakam mı, sen belirle" → GM kararı):
    BAŞ HARFLER (2–3, adın her kelimesinin ilki, Türkçe harf Latin'e) + 2 RAKAM (2–9 arası, rastgele)
    Cemal Hoca 06 → CH47 · Adile Ersoy → AE83 · İzmir Genç Muhasebeciler Derneği → IGM25
    Neden: (1) kısa — hikâyede/videoda söylenir, telefonda 4–5 tuşla yazılır; (2) linkte kişinin adı açık
    durmaz; (3) 0/1 yok → O/I ile karışmaz; (4) sıra numarası değil rastgele → "kaçıncı elçi" okunmaz.
    Aynı baş harflere 64 rakam çifti düşer; çakışırsa yeniden çekilir, 64'ü de doluysa 3 rakam.
#>
function KodOner([string]$adMetni, [string[]]$doluKodlar) {
  # Hashtable DEĞİL: PS hashtable büyük/küçük harf duyarsız, 'İ' ile 'I' anahtarı çakışıp İ düşüyordu (29.09 ölçüldü: İzmir → harfsiz).
  $kelimeler = @("$adMetni".Trim() -split '\s+' | Where-Object { $_ -and $_ -notmatch '^\d+$' })
  $basHarfler = ''
  foreach ($kelime in ($kelimeler | Select-Object -First 3)) {
    $ilk = $kelime.Substring(0,1).ToUpper([Globalization.CultureInfo]'tr-TR')
    $ilk = $ilk -creplace 'Ç','C' -creplace 'Ğ','G' -creplace 'İ','I' -creplace 'Ö','O' -creplace 'Ş','S' -creplace 'Ü','U'
    # -cmatch ŞART: -match tr-TR'de 'I'yı 'ı'ya katlar, [A-Z]'de bulamaz (29.09: İzmir/Ilgın harfsiz kalıyordu)
    if ("$ilk" -cmatch '^[A-Z]$') { $basHarfler += "$ilk" }
  }
  if ($basHarfler.Length -lt 1) { Write-Host "Addan baş harf çıkmadı: '$adMetni'"; exit 1 }
  $rakamHavuzu = '23456789'
  $rastgele = New-Object System.Security.Cryptography.RNGCryptoServiceProvider
  $bayt = New-Object byte[] 3
  for ($deneme = 0; $deneme -lt 200; $deneme++) {
    $rastgele.GetBytes($bayt)
    $haneSayisi = if ($deneme -lt 150) { 2 } else { 3 }
    $aday = $basHarfler + (-join (0..($haneSayisi - 1) | ForEach-Object { $rakamHavuzu[$bayt[$_] % 8] }))
    if ($aday.Length -lt 3) { $aday += $rakamHavuzu[$bayt[2] % 8] }
    if (@($doluKodlar) -notcontains $aday) { return $aday }
  }
  Write-Host 'Boş kod bulunamadı.'; exit 1
}

function KodNormal([string]$hamKod) {
  $temizKod = ($hamKod -replace '[^A-Za-z0-9]', '').ToUpperInvariant()
  if ($temizKod -notmatch '^[A-Z0-9]{3,12}$') { Write-Host "Kod geçersiz: 3–12 harf/rakam olmalı (Türkçe harf yok). Gelen: '$hamKod'"; exit 1 }
  return $temizKod
}

function Istek([string]$yontem, [string]$yol, $govdeNesnesi, [hashtable]$ekBaslik) {
  $basliklar = ServisBasligi
  if ($ekBaslik) { foreach ($k in $ekBaslik.Keys) { $basliklar[$k] = $ekBaslik[$k] } }
  $parametreler = @{ Method = $yontem; Uri = "$SUPA_KOK/$yol"; Headers = $basliklar; TimeoutSec = 60 }
  if ($null -ne $govdeNesnesi) {
    $parametreler.ContentType = 'application/json; charset=utf-8'
    $parametreler.Body = [Text.Encoding]::UTF8.GetBytes(($govdeNesnesi | ConvertTo-Json -Depth 6 -Compress))
  }
  try { return Invoke-RestMethod @parametreler }
  catch {
    $yanit = $_.Exception.Response
    $metin = ''
    if ($yanit) { try { $metin = (New-Object IO.StreamReader($yanit.GetResponseStream())).ReadToEnd() } catch {} }
    if ($metin -match 'PGRST205|PGRST202|does not exist') { Write-Host 'Elçi tabloları canlıda YOK — önce radar-app/sql/2026-09-15-elci-programi.sql basılmalı.'; exit 2 }
    Write-Host "İstek düştü ($yontem $yol): $metin"
    exit 1
  }
}

function BaglamaKoduUret {
  # 12 karakter, sipariş/davet koduyla aynı karışmayan harf havuzu; kriptografik rastgele.
  $havuz = 'ACDEFHJKLMNPRTUVXYZ2345679'
  $rastgele = New-Object System.Security.Cryptography.RNGCryptoServiceProvider
  $baytlar = New-Object byte[] 12
  $rastgele.GetBytes($baytlar)
  $karakterler = foreach ($b in $baytlar) { $havuz[$b % $havuz.Length] }
  $ham = -join $karakterler
  $sha = [System.Security.Cryptography.SHA256]::Create()
  $ozetHex = -join ($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($ham)) | ForEach-Object { $_.ToString('x2') })
  return [pscustomobject]@{ Gorunen = ($ham.Substring(0,4) + '-' + $ham.Substring(4,4) + '-' + $ham.Substring(8,4)); Ozet = $ozetHex }
}

function BaglamaYaz([string]$elciKodu) {
  $yeniBag = BaglamaKoduUret
  $sonTarih = (Get-Date).ToUniversalTime().AddDays(14).ToString('yyyy-MM-ddTHH:mm:ssZ')
  $null = Istek 'Patch' "elciler?kod=eq.$elciKodu" @{ bag_kodu_ozet = $yeniBag.Ozet; bag_kodu_son = $sonTarih } @{ Prefer = 'return=minimal' }
  Write-Host ''
  Write-Host "  Elçi kodu      : $elciKodu"
  Write-Host "  Bağlantı       : https://tetikte.com/satin-al.html?e=$elciKodu"
  Write-Host "  Panel          : https://tetikte.com/elci.html"
  Write-Host "  BAĞLAMA KODU   : $($yeniBag.Gorunen)   (14 gün geçerli, tek kullanımlık — yalnız ŞİMDİ görünür)"
  Write-Host ''
  Write-Host '  Elçiye gidecek metin:'
  Write-Host "    1) tetikte.com/elci.html adresine gir, hesabın yoksa aç (e-posta ya da Google)."
  Write-Host "    2) Bağlama kodunu yaz: $($yeniBag.Gorunen)"
  Write-Host "    3) Koşulları onayla; kodun ($elciKodu), bağlantın ve satışların orada."
}

# --------------------------------------------------------------------------------------------
if ($KodOnerisi) {
  # Çevrimdışı: yalnız öneri basar, tabloya bakmaz (çakışmayı -Ekle denetler).
  if ("$AdSoyad".Trim().Length -lt 3) { Write-Host '-AdSoyad gerekli.'; exit 1 }
  Write-Host ("{0} → {1}" -f $AdSoyad, (KodOner $AdSoyad @()))
  exit 0
}

if ($Ekle) {
  if ("$AdSoyad".Trim().Length -lt 3) { Write-Host '-AdSoyad en az 3 karakter.'; exit 1 }
  if (-not "$Kod".Trim()) {
    $doluListe = @(Istek 'Get' 'elciler?select=kod' $null $null | ForEach-Object { $_.kod })
    $Kod = KodOner $AdSoyad $doluListe
    Write-Host "Kod verilmedi → biçimle üretildi: $Kod"
  }
  $elciKodu = KodNormal $Kod
  $varOlan = @(Istek 'Get' "elciler?select=kod&kod=eq.$elciKodu" $null $null)
  if ($varOlan.Count -gt 0 -and $varOlan[0].kod) { Write-Host "Bu kod zaten var: $elciKodu. Başka kod seç ya da -BagKoduYenile kullan."; exit 1 }
  $satir = @{ kod = $elciKodu; ad_soyad = "$AdSoyad".Trim(); aktif = $true; baslangic_kademe = 1 }
  if ($Eposta)    { $satir.email = "$Eposta".Trim().ToLowerInvariant() }
  if ($Instagram) { $satir.instagram = "$Instagram".Trim() }
  if ($NotYazi)   { $satir.not_ = $NotYazi }
  $null = Istek 'Post' 'elciler' $satir @{ Prefer = 'return=minimal' }
  Write-Host "✓ Elçi eklendi: $elciKodu ($($satir.ad_soyad))"
  BaglamaYaz $elciKodu
  exit 0
}

if ($BagKoduYenile) {
  $elciKodu = KodNormal $Kod
  $kayit = @(Istek 'Get' "elciler?select=kod,user_id&kod=eq.$elciKodu" $null $null)
  if ($kayit.Count -eq 0 -or -not $kayit[0].kod) { Write-Host "Elçi yok: $elciKodu"; exit 1 }
  if ($kayit[0].user_id -and -not $BagiCoz) { Write-Host "Bu elçinin hesabı zaten bağlı. Hesap değiştirecekse -BagiCoz ile birlikte çalıştır."; exit 1 }
  if ($BagiCoz) { $null = Istek 'Patch' "elciler?kod=eq.$elciKodu" @{ user_id = $null } @{ Prefer = 'return=minimal' }; Write-Host "Eski hesap bağı çözüldü." }
  BaglamaYaz $elciKodu
  exit 0
}

if ($Liste) {
  $hepsi = @(Istek 'Get' 'elciler?select=kod,ad_soyad,aktif,baslangic_kademe,user_id,bag_kodu_son,sozlesme_surum,odeme_bilgisi&order=olusturma' $null $null)
  if ($hepsi.Count -eq 0) { Write-Host 'Elçi yok.'; exit 0 }
  $hepsi | ForEach-Object {
    [pscustomobject]@{
      Kod = $_.kod; Ad = $_.ad_soyad; Aktif = $_.aktif; Kademe = $_.baslangic_kademe
      Hesap = $(if ($_.user_id) { 'bağlı' } elseif ($_.bag_kodu_son) { 'kod bekliyor' } else { '—' })
      Kosul = $(if ($_.sozlesme_surum) { $_.sozlesme_surum } else { 'onaysız' })
      IBAN  = $(if ($_.odeme_bilgisi) { 'geldi' } else { 'yok' })
    }
  } | Format-Table -AutoSize
  exit 0
}

if ($Pasif -or $Aktif) {
  $elciKodu = KodNormal $Kod
  $null = Istek 'Patch' "elciler?kod=eq.$elciKodu" @{ aktif = [bool]$Aktif } @{ Prefer = 'return=minimal' }
  Write-Host ("✓ {0} {1}" -f $elciKodu, $(if ($Aktif) { 'AÇILDI' } else { 'KAPATILDI (yeni siparişte indirim yok; geçmiş raporda kalır)' }))
  exit 0
}

if ($OdemeBilgisi) {
  $elciKodu = KodNormal $Kod
  $null = Istek 'Patch' "elciler?kod=eq.$elciKodu" @{ odeme_bilgisi = $true } @{ Prefer = 'return=minimal' }
  Write-Host "✓ $elciKodu : ödeme bilgisi geldi olarak işaretlendi (IBAN tabloya yazılmadı)."
  exit 0
}

if ($Odeme) {
  $elciKodu = KodNormal $Kod
  if (-not $Donem) { Write-Host '-Donem gerekli (ör. "SGS 2026-3").'; exit 1 }
  if ($Tutar -lt 0) { Write-Host '-Tutar gerekli (TL, tam sayı).'; exit 1 }
  $odemeSatiri = @{ kod = $elciKodu; donem = $Donem; tutar_tl = $Tutar }
  if ($NotYazi) { $odemeSatiri.not_ = $NotYazi }
  $null = Istek 'Post' 'elci_odemeler' $odemeSatiri @{ Prefer = 'return=minimal' }
  Write-Host ("✓ Ödeme kaydı: {0} · {1} · {2:N0} TL" -f $elciKodu, $Donem, $Tutar)
  exit 0
}

if ($Rapor) {
  $raporSatirlari = @(Istek 'Get' 'elci_donem_raporu?select=*&order=donem,kesin_satis.desc' $null $null)
  if ($raporSatirlari.Count -eq 0) { Write-Host 'Raporda satır yok.'; exit 0 }
  $raporSatirlari | Select-Object donem, kod, kesin_satis, bekleyen_satis, iade, odeme_bekleyen, komisyon_tl, ulasilan_kademe, sonraki_baslangic, ozel_isbirligi | Format-Table -AutoSize
  exit 0
}

if ($Dogrula) {
  $anonBaslik = @{ apikey = $ANON_ANAH; Authorization = "Bearer $ANON_ANAH" }
  $sonuclar = New-Object System.Collections.Generic.List[string]
  $kirmizi = 0
  function Satir([bool]$gecti, [string]$metin) { $script:sonuclar.Add(("{0}  {1}" -f $(if ($gecti) { 'YEŞİL ' } else { 'KIRMIZI' }), $metin)); if (-not $gecti) { $script:kirmizi++ } }

  # a) sunucu indirim tablosu
  $indirimSatirlari = @(Istek 'Get' 'elci_indirim?select=paket,indirim_tl&order=paket' $null $null)
  $sunucu = @{}; foreach ($r in $indirimSatirlari) { $sunucu[$r.paket] = [int]$r.indirim_tl }
  # b) fiyat-motoru.js ELCI.indirim (ekran gösterimi) — birebir aynı olmalı
  $motorMetni = [IO.File]::ReadAllText((Join-Path $DEPO_KOKU 'fiyat-motoru.js'), [Text.Encoding]::UTF8)
  $eslesme = [regex]::Match($motorMetni, 'var ELCI\s*=\s*\{[^;]*?indirim\s*:\s*\{([^}]*)\}')
  $motor = @{}
  if ($eslesme.Success) {
    foreach ($m in [regex]::Matches($eslesme.Groups[1].Value, "'?([a-z0-9\-]+)'?\s*:\s*(\d+)")) { $motor[$m.Groups[1].Value] = [int]$m.Groups[2].Value }
  }
  $ayni = ($sunucu.Count -eq $motor.Count) -and (@($sunucu.Keys | Where-Object { $motor[$_] -ne $sunucu[$_] }).Count -eq 0)
  Satir $ayni ("elci_indirim (sunucu) = ELCI.indirim (fiyat-motoru.js) · sunucu: {0} · motor: {1}" -f (($sunucu.Keys | Sort-Object | ForEach-Object { "$_=$($sunucu[$_])" }) -join ','), (($motor.Keys | Sort-Object | ForEach-Object { "$_=$($motor[$_])" }) -join ','))

  # c) anonim uç: yok kod 0 döner; elçi tabloları okunamaz; panel fonksiyonları anonime kapalı
  function AnonCagri([string]$yontem, [string]$yol, [string]$govde) {
    try {
      $p = @{ Method = $yontem; Uri = "$SUPA_KOK/$yol"; Headers = $anonBaslik; TimeoutSec = 30; UseBasicParsing = $true }
      if ($govde) { $p.ContentType = 'application/json'; $p.Body = $govde }
      $r = Invoke-WebRequest @p
      return [pscustomobject]@{ Kod = [int]$r.StatusCode; Govde = "$($r.Content)" }
    } catch {
      $y = $_.Exception.Response
      if ($y) { return [pscustomobject]@{ Kod = [int]$y.StatusCode; Govde = '' } }
      return [pscustomobject]@{ Kod = 0; Govde = '' }
    }
  }
  $yokKod = AnonCagri 'Post' 'rpc/elci_kodu_kontrol' '{"p_kod":"YOKKOD","p_paket":"sgs"}'
  Satir ($yokKod.Kod -eq 200 -and $yokKod.Govde.Trim() -eq '0') "elci_kodu_kontrol('YOKKOD','sgs') anonim → 0 (gelen: $($yokKod.Kod) $($yokKod.Govde))"
  $merdiven = AnonCagri 'Post' 'rpc/elci_kodu_kontrol' '{"p_kod":"YOKKOD","p_paket":"yeterlilik-1"}'
  Satir ($merdiven.Kod -eq 200 -and $merdiven.Govde.Trim() -eq '0') "elci_kodu_kontrol(…,'yeterlilik-1') anonim → 0 (gelen: $($merdiven.Kod) $($merdiven.Govde))"
  foreach ($tablo in 'elciler', 'elci_indirim', 'elci_odemeler', 'elci_donem_raporu', 'sinav_donemleri') {
    $t = AnonCagri 'Get' "$tablo`?select=*&limit=1" ''
    Satir ($t.Kod -ne 200 -or $t.Govde.Trim() -eq '[]') "$tablo anonime kapalı (gelen: $($t.Kod) $($t.Govde.Substring(0,[Math]::Min(60,$t.Govde.Length))))"
  }
  foreach ($fonk in 'elci_panelim', 'elci_bagla', 'elci_sozlesme_onayla') {
    $govde = if ($fonk -eq 'elci_bagla') { '{"p_kod":"X"}' } elseif ($fonk -eq 'elci_sozlesme_onayla') { '{"p_surum":"2026-09-29"}' } else { '{}' }
    $f = AnonCagri 'Post' "rpc/$fonk" $govde
    Satir ($f.Kod -in 401, 403, 404) "$fonk anonime kapalı (gelen: $($f.Kod))"
  }
  # d) komisyon formülü
  $k30 = Istek 'Post' 'rpc/elci_komisyon' @{ n = 30; bk = 1 } $null
  Satir ([int]$k30 -eq 27750) "elci_komisyon(30,1) = 27750 (gelen: $k30)"

  $sonuclar | ForEach-Object { Write-Host $_ }
  Write-Host ("DOĞRULAMA: {0} denetim, {1} KIRMIZI" -f $sonuclar.Count, $kirmizi)
  if ($kirmizi -gt 0) { exit 1 } else { exit 0 }
}

Write-Host 'Bir iş seç: -Ekle · -BagKoduYenile · -Liste · -Pasif/-Aktif · -OdemeBilgisi · -Odeme · -Rapor · -Dogrula (ayrıntı dosyanın başında).'
exit 1
