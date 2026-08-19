param([string]$Kok)
$ErrorActionPreference = 'Stop'
if (-not $Kok) { $Kok = Split-Path $PSScriptRoot -Parent }   # varsayilan: depo koku

$kelimeler = @(
  'icin','gun','gunluk','gunu','gune','gunler','yil','yillik','sirket','odeme','islem','islemler',
  'degisiklik','degisen','sure','sureli','guncel','guncelleme','arac','araclar','aracin','asagida',
  'yukarida','kisaca','ornegin','gonder','gonderim','iletisim','aydinlatma',
  'basvuru','musteri','sozlesme','gumruk','ucret','ucretsiz','goster','gosterir','duzenle',
  'kayit','tum','dogru','yanlis','degil','olcu','kucuk','buyuk','ogren','calis','cikis',
  'giris','ozel','onemli','gecerli','gecmis','surec','cozum','gorus','olcum','uyari',
  'acik','kapali','hicbir','tesvik','yonetmelik','teblig','hazir','bugun','yarin','henuz',
  'sec','sectigin','birak','birakmak','alindi','yapacagiz','donelim','donus','cunku',
  'dosyani','ustlenmek','uzmanligi','baglanti','kullanici','sikca','yukumluluk',
  'oduyor','odenir','sart','dongu','aliskanlik','cikti','sinav','sinavin','lutfen','tamam',
  'yukleniyor','baglanti','hatali','basarili','gecersiz','bulunamadi','sonuc','sonuclar'
) | Sort-Object -Unique

$trHarf = -join (0x00E7,0x00C7,0x011F,0x011E,0x0131,0x0130,0x00F6,0x00D6,0x015F,0x015E,0x00FC,0x00DC | ForEach-Object { [char]$_ })
$TR = 'A-Za-z0-9' + $trHarf

$kaynaklar = @()
$kaynaklar += Get-ChildItem -LiteralPath $Kok -Filter *.js -File | ForEach-Object {
  [pscustomobject]@{ ad = $_.Name; kod = [System.IO.File]::ReadAllText($_.FullName, [System.Text.Encoding]::UTF8) }
}
Get-ChildItem -LiteralPath $Kok -Filter *.html -File | ForEach-Object {
  $ham = [System.IO.File]::ReadAllText($_.FullName, [System.Text.Encoding]::UTF8)
  $sc = ([regex]::Matches($ham, '(?is)<script[^>]*>(.*?)</script>') | ForEach-Object { $_.Groups[1].Value }) -join "`n"
  if ($sc.Trim()) { $kaynaklar += [pscustomobject]@{ ad = $_.Name + ' <script>'; kod = $sc } }
}

$bulgu = @()
foreach ($k in $kaynaklar) {
  # yorum satirlarini at, sonra tirnak icindeki metinleri topla
  $kod = [regex]::Replace($k.kod, '(?m)//.*$', ' ')
  $kod = [regex]::Replace($kod, '(?s)/\*.*?\*/', ' ')
  $dizeler = [regex]::Matches($kod, '"([^"\\\r\n]{4,})"|''([^''\\\r\n]{4,})''|`([^`\\]{4,})`') |
             ForEach-Object { $_.Groups[1].Value + $_.Groups[2].Value + $_.Groups[3].Value }
  $metin = ($dizeler -join ' | ')
  foreach ($w in $kelimeler) {
    $m = [regex]::Matches($metin, "(?<![$TR])$w(?![$TR@\.])")
    if ($m.Count -gt 0) {
      $i = $m[0].Index; $bas = [Math]::Max(0, $i - 45)
      $ornek = $metin.Substring($bas, [Math]::Min(120, $metin.Length - $bas)) -replace '\s+', ' '
      $bulgu += [pscustomobject]@{ kaynak = $k.ad; kelime = $w; adet = $m.Count; ornek = $ornek.Trim() }
    }
  }
}
$bulgu | Sort-Object kaynak, kelime | ForEach-Object { "{0}|{1}|{2}|{3}" -f $_.kaynak, $_.kelime, $_.adet, $_.ornek }
"=== TOPLAM: $($bulgu.Count) bulgu / $(($bulgu | Select-Object -ExpandProperty kaynak -Unique).Count) kaynak / taranan: $($kaynaklar.Count)"
