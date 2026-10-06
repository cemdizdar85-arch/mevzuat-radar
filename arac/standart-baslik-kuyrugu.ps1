# STANDART PARAGRAF BAŞLIK KUYRUĞU (07.10.2026, KGK oturumu, Cem "ikisini de yap") — 0 USD.
# NE YAPAR: paragraf numarasından numarasına kesilen metinde (motor/kgk-standart-yut.ps1 Parcala paragraf yolu: Etik Kurallar, KYS 1/2 …)
#   bir sonraki bölümün BAŞLIĞI önceki paragrafın SONUNA yapışıyordu (altyapı ölçümü 07.10: 4.240 standart paragrafında 610 aday, örneklem
#   39/40 gerçek; Etik Kurallar 317). Bu işlev gövdenin son 1–2 satırı başlık biçimindeyse onları ayırır; çağıran başlığı bir SONRAKİ
#   paragrafın başına taşır (İÇERİK ATILMAZ). Kayıt adı değişmez → soru-kaynak bağı kopmaz.
# KURAL: son satır (ve gerekirse ondan önceki tek satır) noktalamasız, büyük harfle başlar, ';:' içermez, ≤25 kelime, fiille / bağlaçla bitmez
#   VE başlığın hemen üstündeki satır cümle sonuyla biter (gövde ortası değil). Başlıktan sonra gelen yan numara ("53 54", "D2") başlığın parçasıdır.
# Mutasyon: $env:SBK_MUTASYON=kapali → hiçbir şey ayrılmaz (öz-sınav KIRMIZI düşmeli).
# 🚫 GÖRMEZ: "-lar/-ler" ile biten fiil ("düzenler") çoğul isimden ayrılamaz → cümle sonu noktasızsa başlık sanılabilir · üç ve daha çok satıra saran başlık · tek satıra sıkışmış (satır sonu olmayan) metin · cümle gibi noktayla biten başlık.
function SbkBaslikBicimi([string]$x){
  $x = $x.Trim()
  if($x.Length -lt 3 -or $x.Length -gt 180){ return $false }
  if($x -match '[.:;,!?]$' -or $x -match '[;:]'){ return $false }
  if($x -cnotmatch '^[A-ZÇĞİÖŞÜ“"]'){ return $false }
  if(@($x -split '\s+').Count -gt 25){ return $false }
  $son = ([regex]::Match(($x -replace '(\s+[A-Z]?\d{1,3}[A-Z]?)+$',''), '\p{L}+(?=\P{L}*$)')).Value.ToLowerInvariant()   # yan numara ("… 53 54", "… D2") sayılmaz
  if(-not $son){ return $false }
  if($son -match '(dır|dir|dur|dür|tır|tir|tur|tür|maz|mez|mış|miş|muş|müş|abilir|ebilir)$' -or $son -in @('ve','veya','ile','ya','da','de','için','gibi','olan')){ return $false }
  if($son -match '(ı|i|u|ü)r$' -or ($son -match '(a|e)r$' -and $son -notmatch '(lar|ler)$')){ return $false }   # geniş zaman fiili ("yürütür", "yazar") — motor/mevzuat-yut.ps1 KuyrukBaslikMi ile aynı
  return $true
}
function StandartBaslikKuyrugu([string]$govde){
  $sonuc = [pscustomobject]@{ govde = $govde; baslik = '' }
  if("$env:SBK_MUTASYON" -eq 'kapali'){ return $sonuc }
  $sat = @(($govde -replace "`r",'') -split "`n" | ForEach-Object { $_.TrimEnd() })
  $dolu = @(for($i=0; $i -lt $sat.Count; $i++){ if($sat[$i].Trim()){ $i } })
  if($dolu.Count -lt 2){ return $sonuc }   # gövde (numara aynı satırda olabilir: Etik "110.1 A1 …") + başlık
  $s1 = $dolu[$dolu.Count-1]; $s0 = $dolu[$dolu.Count-2]
  if(-not (SbkBaslikBicimi $sat[$s1])){ return $sonuc }
  $tirnakSon = [string][char]0x201D + [string][char]0x2019   # akıllı tırnak char koduyla: PS tek tırnaklı dizgide U+2019 dizgiyi KAPATIR
  $bitis = { param([string]$t) $t.Trim() -match ('[.;:!?)\]"' + $tirnakSon + ']$') }
  $basIx = -1
  if(& $bitis $sat[$s0]){ $basIx = $s1 }
  elseif($dolu.Count -ge 3 -and (SbkBaslikBicimi $sat[$s0]) -and (& $bitis $sat[$dolu[$dolu.Count-3]]) -and ($sat[$s0].Trim().Length + $sat[$s1].Trim().Length) -le 180){ $basIx = $s0 }
  if($basIx -lt 0 -or $basIx -eq $dolu[0]){ return $sonuc }   # numara satırının kendisi başlık sayılmaz
  $sonuc.baslik = ((@($sat[$basIx..($sat.Count-1)] | ForEach-Object { $_.Trim() } | Where-Object { $_ })) -join ' ')
  $sonuc.govde = ((@($sat[0..($basIx-1)])) -join "`n").TrimEnd()
  return $sonuc
}
if($MyInvocation.InvocationName -ne '.' -and $args -contains '-Sinav'){
  $v = @(
    @('Etik: cümle + başlık', "110.1 A1 Denetçi dürüst davranır.`nMeslekî Davranış", 'Meslekî Davranış'),
    @('saran iki satırlık başlık', "120.2 Denetçi tehditleri belirler ve değerlendirir.`nTehditleri Belirleme ve Değerlendirmede Dikkate`nAlınacak Hususlar", 'Tehditleri Belirleme ve Değerlendirmede Dikkate Alınacak Hususlar'),
    @('yan numaralı başlık', "52 İşletme bu yaklaşımı uygular.`nPrim dağıtımı yaklaşımı 53 54", 'Prim dağıtımı yaklaşımı 53 54'),
    @('gövde ortası (önceki satır cümle değil) → yok', "15 İşletme varlığı ilk kez ölçerken maliyet ve`nGerçeğe Uygun Değer arasındaki farkı", ''),
    @('fiille biten son satır → yok', "15 Denetçi ilk paragrafı okur.`nDenetçi bu durumda raporu yeniden yazar", ''),
    @('liste girişi (iki nokta) → yok', "15 Aşağıdakiler dahildir.`nÖrnekler şunlardır:", ''),
    @('tek satırlık paragraf → yok', "15 Kısa paragraf metni burada biter.", '')
  )
  $h = 0; foreach($x in $v){ $r = StandartBaslikKuyrugu $x[1]; $ok = ($r.baslik -eq $x[2]) -and ($x[2] -eq '' -or ($r.govde + ' ' + $r.baslik) -replace '\s+',' ' -eq ($x[1] -replace '\s+',' ')); if(-not $ok){ $h++; "  DUSTU: $($x[0]) -> '$($r.baslik)'" } }
  if($h){ "BASLIK KUYRUGU SINAVI KIRMIZI: $h/$($v.Count)"; exit 1 } else { "BASLIK KUYRUGU SINAVI YESIL: $($v.Count)/$($v.Count)"; exit 0 }
}
