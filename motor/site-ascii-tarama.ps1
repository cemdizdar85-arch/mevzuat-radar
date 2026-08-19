param([string]$Kok)
$ErrorActionPreference = 'Stop'
if (-not $Kok) { $Kok = Split-Path $PSScriptRoot -Parent }   # varsayilan: depo koku

# Turkcede MUTLAKA sapkali/noktali harf iceren sozcuklerin ASCII'ye duzlestirilmis halleri.
# Dogrudan ASCII yazilan gercek kelimeler (beyanname, soru, indir, sistem...) listeye ALINMAZ.
$kelimeler = @(
  'icin','gun','gunluk','gunu','gune','gunler','yil','yillik','sirket','odeme','islem','islemler',
  'degisiklik','degisen','sure','sureli','guncel','guncelleme','arac','araclar','aracin','asagida',
  'yukarida','kisaca','ornegin','gonder','gonderim','iletisim','aydinlatma',
  'basvuru','musteri','sozlesme','gumruk','ucret','ucretsiz','goster','gosterir','duzenle',
  'kayit','tum','dogru','yanlis','degil','olcu','kucuk','buyuk','ogren','calis','cikis',
  'giris','ozel','onemli','gecerli','gecmis','surec','cozum','gorus','olcum','uyari',
  'acik','kapali','hicbir','tesvik','yonetmelik','teblig','hazir','bugun','yarin','henuz','heniz',
  'sec','sectigin','birak','birakmak','alindi','yapacagiz','donelim','donus','ayni','cunku',
  'dosyani','ustlenmek','uzmanligi','baglanti','kullanici','sikca','yukumluluk','kasim','aralik',
  'yayim','oduyor','odenir','olcut','sart','dongu','aliskanlik','cikti','sinav','sinavin','ilan'
) | Sort-Object -Unique

# Turkce harfler kod noktasindan kurulur (ps1 dosyasi ASCII kalsin diye)
$trHarf = -join (0x00E7,0x00C7,0x011F,0x011E,0x0131,0x0130,0x00F6,0x00D6,0x015F,0x015E,0x00FC,0x00DC | ForEach-Object { [char]$_ })
$TR = 'A-Za-z0-9' + $trHarf

$dosyalar = Get-ChildItem -LiteralPath $Kok -Filter *.html -File
$bulgu = @()
foreach ($f in $dosyalar) {
  $ham = [System.IO.File]::ReadAllText($f.FullName, [System.Text.Encoding]::UTF8)
  $t = [regex]::Replace($ham, '(?s)<!--.*?-->', ' ')            # HTML yorumlari disari
  $t = [regex]::Replace($t, '(?is)<script.*?</script>', ' ')
  $t = [regex]::Replace($t, '(?is)<style.*?</style>', ' ')
  $nitelik = [regex]::Matches($t, '(?i)(placeholder|title|alt|aria-label)\s*=\s*"([^"]*)"') |
             ForEach-Object { $_.Groups[2].Value }
  $t = [regex]::Replace($t, '(?s)<[^>]*>', ' ')
  $metin = ($t + ' ' + ($nitelik -join ' '))
  foreach ($k in $kelimeler) {
    $m = [regex]::Matches($metin, "(?<![$TR])$k(?![$TR@\.])")
    if ($m.Count -gt 0) {
      $i = $m[0].Index
      $bas = [Math]::Max(0, $i - 50)
      $ornek = $metin.Substring($bas, [Math]::Min(130, $metin.Length - $bas)) -replace '\s+', ' '
      $bulgu += New-Object psobject -Property ([ordered]@{
        dosya = $f.Name; kelime = $k; adet = $m.Count; ornek = $ornek.Trim()
      })
    }
  }
}
$bulgu | Sort-Object dosya, kelime | ForEach-Object {
  "{0}|{1}|{2}|{3}" -f $_.dosya, $_.kelime, $_.adet, $_.ornek
}
"=== TOPLAM SATIR: $($bulgu.Count) / DOSYA: $(($bulgu | Select-Object -ExpandProperty dosya -Unique).Count) / TARANAN: $($dosyalar.Count)"
