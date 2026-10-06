# ============================================================================
#  TUZAK ADI AYIRICI (06.10.2026, Cem "1.2.3" + site oturumu onayı) — motor/kaydir-coz.ps1 bunu yükler.
#  NEDEN (ölçüldü 06.10): yanlış şık açıklamasından tuzak adı "ilk ':' öncesi 3–60 karakter" kuralıyla çıkıyordu
#    (kaydir-coz.ps1 eski :221). Açıklama "Ne soruluyor: …" çözüm kalıbıyla yazılmışsa ad "Ne soruluyor" oluyor,
#    ders sayfası ve seviye testi kartı bunu başlık gibi basıyordu: SMMM yayında 241 soru (sinav oturumu t3-olcum).
#  KURAL: ad bir KALINTI desenine uyarsa (Ne soruluyor / Kural / Hesap / Bu olayda / Doğrusu tek başına, istem
#    cümlesi "tekrar edilmez/tekrarlanmaz") sırayla: R1 baştaki istem cümlesi silinip yeniden ayrıştırılır ·
#    R2 metnin içindeki "<X> Tuzağı:" etiketi ad olur · R3 etiket yoksa ad "Tuzak", baştaki "Ne soruluyor: …"
#    cümlesi metinden atılır. Kalıntıya uymayan ad HİÇ değişmez ("Kural Tuzağı", "Hesap Seçimi Tuzağı" dahil).
#  🚫 GÖRMEZ: açıklamanın İÇERİĞİ yanlış şıkkı mı anlatıyor (S1: yanlış şık açıklaması doğru şıkkınkiyle aynı;
#    doğru şıkkın açıklaması tuzak etiketli) — bunlar onarım kuyruğunda · kalıntı listesinde olmayan yeni kalıp.
#  Öz-sınav: powershell -NoProfile -File arac/tuzak-ayir.ps1 -Sinav  (mutasyon: $env:TUZAK_AYIR_MUTASYON='kapali')
# ============================================================================
# param bloğu YOK: kaydir-coz.ps1 bunu nokta-yükler; param() yükleyenin değişkenlerini ezerdi. Sınav yalnız doğrudan çağrıda (-File … -Sinav).
$script:TUZAK_KALINTI='^(ne soruluyor|kural|hesap|bu olayda|do[gğ]rusu)$|^ne soruluyor|ne soruluyor\?|tekrar edilmez|tekrarlanmaz|tekrarlamadan|tekrar etmeden'
$script:TUZAK_ISTEM='(?i)^Ne soruluyor[^.:]{0,40}?(tekrar edilmez|tekrarlanmaz|tekrarlamadan|tekrar etmeden)[^.:A-ZÇĞİÖŞÜ]*[.,]?\s*'
function TuzakAyirHam([string]$a){ $mt=[regex]::Match($a,'^([^:]{3,60}):\s*(.*)$'); if($mt.Success){ return @{ ad=($mt.Groups[1].Value.Trim() -replace '^\[|\]$','' -replace '\]\s*',' '); metin=$mt.Groups[2].Value.Trim() } }; return @{ ad='Tuzak'; metin=$a } }
function TuzakAyir([string]$a){
  $c=TuzakAyirHam $a
  if("$env:TUZAK_AYIR_MUTASYON" -eq 'kapali'){ return $c }
  if($c.ad -notmatch $script:TUZAK_KALINTI){ return $c }
  $u=[regex]::Replace($a,$script:TUZAK_ISTEM,'')
  if($u -ne $a){ $d=TuzakAyirHam $u; if($d.ad -notmatch $script:TUZAK_KALINTI){ return $d } }
  $m=[regex]::Match($u,'(?:^|[.;]\s+|\s)([A-ZÇĞİÖŞÜ][^.:;]{1,58}?Tuza[gğ][iı])\s*:\s*(.*)$')
  if($m.Success){ return @{ ad=$m.Groups[1].Value.Trim(); metin=$m.Groups[2].Value.Trim() } }
  $r=([regex]::Replace($u,'(?i)^Ne soruluyor\s*:\s*.*?(?=\s(?:Kural|Hesap|Bu olayda|Do[gğ]rusu)\s*:|$)','')).Trim()
  # 06.10 (t427 örneklemi): arkasında başlık yoksa cümle bütünüyle gidiyor, metin ham kalıyordu → yalnız 'Ne soruluyor:' etiketi atılır.
  if(-not $r){ $r=([regex]::Replace($u,'(?i)^Ne soruluyor\s*:\s*','')).Trim() }
  # 06.10: boş hesap yuvası 'Hesap: -' artığı (511 bulgulu şıkın 5'inde)
  if("$env:TUZAK_AYIR_MUTASYON" -ne 'hesap-artik'){ $r=([regex]::Replace($r,'(?i)\s*Hesap\s*:\s*[-–—](?=\s|$)',' ')).Trim() -replace '\s{2,}',' ' }
  return @{ ad='Tuzak'; metin=$(if($r){ $r } else { $u }) }
}
if($MyInvocation.InvocationName -ne '.' -and @($args) -contains '-Sinav'){
  # [girdi, beklenen ad] — kalıntı vakaları (t3-olcum S2/S3/S4 sınıfları) + DEĞİŞMEMESİ gereken meşru adlar
  $v=@(
    @('Ne soruluyor: işletmenin dönem kârı. Kural: götürü gider %15. Doğrusu: 120.000 TL.','Tuzak'),
    @('Ne soruluyor sorusu tekrar edilmez. Bildirim Yönü Tuzağı: süre bildirimden başlar.','Bildirim Yönü Tuzağı'),
    @('Ne soruluyor: matrah. Kural: m.74. İstisna Atlama Tuzağı: istisnayı düşmeden hesapladın.','İstisna Atlama Tuzağı'),
    @('Kural: m.40/1-5 gereği yakıtın %70''i indirilir.','Tuzak'),
    @('Kural Tuzağı: kuralı ters uyguladın.','Kural Tuzağı'),
    @('Hesap Seçimi Tuzağı: 191 yerine 391 seçtin.','Hesap Seçimi Tuzağı'),
    @('Vergi Gideri Tuzağı: emlak vergisini gider saymadın.','Vergi Gideri Tuzağı'),
    @('[Genel Üretim Gideri İhmali] Tuzağı: GÜG eklenmedi.','Genel Üretim Gideri İhmali Tuzağı'),
    @('Ne soruluyor cümlesini tekrar etmeden Dönem Kesri Tuzağı: ayı yanlış saydın.','Dönem Kesri Tuzağı'),
    @('etiketsiz kısa açıklama','Tuzak'))
  $h=0; foreach($x in $v){ $r=TuzakAyir $x[0]; if("$($r.ad)" -cne $x[1]){ $h++; "  DUSTU: '$($x[0].Substring(0,[math]::Min(50,$x[0].Length)))' -> '$($r.ad)' (beklenen '$($x[1])')" } }
  # kalıntı metinden atılmalı: R3'te metin "Ne soruluyor" ile başlamamalı
  $r3=TuzakAyir $v[0][0]; if("$($r3.metin)" -match '^Ne soruluyor'){ $h++; '  DUSTU: R3 metninde "Ne soruluyor" kaldı' }
  $r4=TuzakAyir 'Ne soruluyor: işletmenin cari oranı 1,6 sanıldı.'; if("$($r4.metin)" -cne 'işletmenin cari oranı 1,6 sanıldı.'){ $h++; "  DUSTU: başlıksız 'Ne soruluyor:' etiketi atılmadı -> '$($r4.metin)'" }
  $r5=TuzakAyir 'Kural: süre 30 gündür. Hesap: - Doğrusu: 30 gün.'; if("$($r5.metin)" -match 'Hesap\s*:\s*-'){ $h++; "  DUSTU: 'Hesap: -' artığı kaldı -> '$($r5.metin)'" }
  $n=$v.Count+3
  if($h){ "TUZAK AYIR SINAVI KIRMIZI: $h/$n"; exit 1 } else { "TUZAK AYIR SINAVI YESIL: $n/$n"; exit 0 }
}
