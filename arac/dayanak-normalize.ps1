# ============================================================================
#  DAYANAK NORMALIZE + ALIAS (01.09.2026, Cem: "alias sozlugunu kopru V2 ile
#  birlestir - bunlar olmasin diye kopru kurduk, neden hala karsilasiyoruz")
#
#  NEDEN VAR: 01.09'da UC ayri olcum ayni sekilde yanildi - kaynak AMBARDA
#  oldugu halde "yok/zayif" sanildi, cunku ayni kaynak farkli adlarla yasiyor:
#    - kisa ad vs uzun ad     : "KUMI FRS"  vs "KUMI FRS - Kucuk ve Mikro ... (RG ...)"
#    - madde-ekli ad          : "KVK GUT (1 Seri No) m.6" / "... gec. m.3 [73/405]"
#    - yazim farki + Turkce-I : "Seri: X, No: 22" / "Seri:X No:22"; kucuk 'i' regex tuzagi
#  Kopru KONU eslemesini cozdu; bu modul KAYNAK-ADI eslemesini cozer.
#
#  KULLANIM:  . (Join-Path $kok 'arac\dayanak-normalize.ps1')
#             $anahtar = DayanakAnahtar 'KVK GUT (1 Seri No) m.6'   # -> 'KVK GUT (1 SERI NO)'
#  OZ-SINAV:  powershell -NoProfile -File arac\dayanak-normalize.ps1 -Sinav
# ============================================================================

# Bilinen takma adlar: SOL taraf normalize SONRASI yakalanan varyant, SAG kanonik.
# Yeni vaka cikinca BURAYA satir eklenir (koda dokunulmaz).
$script:DAYANAK_ALIAS = @{
  'KUMI FRS - KUCUK VE MIKRO ISLETMELER ICIN FINANSAL RAPORLAMA STANDARDI' = 'KUMI FRS'
  'BOBI FRS - BUYUK VE ORTA BOY ISLETMELER ICIN FINANSAL RAPORLAMA STANDARDI' = 'BOBI FRS'
  'SPK TEBLIG (SERI: X, NO: 22) - SERMAYE PIYASASINDA BAGIMSIZ DENETIM STANDARTLARI HAKKINDA TEBLIG' = 'SPK TEBLIG (SERI: X, NO: 22)'
  'KURUMLAR VERGISI GENEL TEBLIGI (SERI NO: 1)' = 'KVK GUT (1 SERI NO)'
  'SERMAYE PIYASASI K.' = 'SPKN (6362 S.K.)'
  'SERMAYE PIYASASI KANUNU' = 'SPKN (6362 S.K.)'
  'SPKN' = 'SPKN (6362 S.K.)'
}

function DayanakAnahtar([string]$ad){
  if([string]::IsNullOrWhiteSpace($ad)){ return '' }
  $s = $ad.Trim()
  # 1) Turkce katlama ASCII'ye - kulturden bagimsiz eslesme (Turkce-I tuzagi dersi)
  $s = $s -creplace 'İ','I' -creplace 'ı','i' -creplace 'Ğ','G' -creplace 'ğ','g' `
          -creplace 'Ü','U' -creplace 'ü','u' -creplace 'Ş','S' -creplace 'ş','s' `
          -creplace 'Ö','O' -creplace 'ö','o' -creplace 'Ç','C' -creplace 'ç','c'
  $s = $s.ToUpperInvariant()
  # 2) madde/parca eklerini at: ' m.6', ' gec. m.3', ' [73/405]', ' par.12', ' md.5'
  $s = $s -replace '\s+\[\d+/\d+\]',''
  $s = $s -replace '\s+(GEC\.\s*)?M(D)?\.\s*\d+[A-Z]?(/\d+)?(\s|$).*$',''
  # kilavuz-bolum eki (01.09 KVK GUT yeniden bolme: 'b.10.3.2.1' gibi)
  $s = $s -replace '\s+B\.\s*\d+(\.\d+)*(\s|$).*$',''
  $s = $s -replace '\s+PAR\.\s*\d+.*$',''
  # 3) sondaki RG/karar kunyesini at: '(Kurul Karari ...; RG ...)' - ama
  #    '(SERI NO: 1)' / '(SERI: X, NO: 22)' / '(6362 S.K.)' gibi KIMLIK parantezleri KALIR
  $s = $s -replace '\s*\((KURUL KARARI|RG)\b[^)]*\)',''
  # 4) yazim sadelestirme: 'SERI:X' -> 'SERI: X', 'NO:22' -> 'NO: 22', coklu bosluk tek
  $s = $s -replace '(SERI|NO)\s*:\s*','$1: '
  $s = ($s -replace '\s+',' ').Trim().TrimEnd('-',',',';').Trim()
  # 4b) 03.09 KANUN NUMARASI KANONU (Cem "1 yap"): ayni kanun uc adla yasiyor -
  #     "5510 sayili Kanun" / "5510 s. SGK Kanunu" / "SSGSSK (5510 s.K.)"; "3568 s. SMMM K." /
  #     "SMMM K. (3568 s.K.)". Olculdu: metinsiz raporunun 148 "bulunmayan"inin buyuk kismi
  #     bu ad farkiydi, ambarda hepsi vardi. Kanun numarasi varsa anahtar = K<numara>.
  #     (madde eki 2. adimda zaten atildi; kanun-duzeyi anahtar kopru semantigiyle ayni)
  $mk=[regex]::Match($s,'\b(\d{3,4})\s*(SAYILI|S\.\s*K\.|S\.(?=\s))')
  if($mk.Success){ return "K$($mk.Groups[1].Value)" }
  # 5) uzun-ad kuyrugunu alias sozlugune sor; yoksa ' - ' oncesi govdeyi de dene
  if($script:DAYANAK_ALIAS.ContainsKey($s)){ return $script:DAYANAK_ALIAS[$s] }
  $govde = ($s -split '\s+-\s+')[0].Trim()
  if($script:DAYANAK_ALIAS.ContainsKey($govde)){ return $script:DAYANAK_ALIAS[$govde] }
  # uzun ad ise (govde + aciklama) govdeyi kanonik say - "X - aciklamasi" deseninde
  if($govde -ne $s -and $govde.Length -ge 6){ return $govde }
  return $s
}

# --- OZ-SINAV (93 kapi kurali: karar veren betik kendini sinar) --------------
if($args -contains '-Sinav' -or ($MyInvocation.InvocationName -ne '.' -and $PSBoundParameters.Count -eq 0 -and $args.Count -eq 0 -and $MyInvocation.Line -match '-Sinav')){ }
if($args -contains '-Sinav'){
  $vakalar = @(
    # 01.09'un uc gercek yanilgisi + koruma vakalari
    @{ a='KUMI FRS'; b='KUMI FRS - Kucuk ve Mikro Isletmeler icin Finansal Raporlama Standardi (Kurul Karari 20.12.2022; RG 16.01.2023-32075 muk.)'; ayni=$true }
    @{ a='KVK GUT (1 Seri No)'; b='KVK GUT (1 Seri No) m.6'; ayni=$true }
    @{ a='KVK GUT (1 Seri No)'; b='KVK GUT (1 Seri No) gec. m.3 [73/405]'; ayni=$true }
    @{ a='SPK Tebliğ (Seri: X, No: 22)'; b='SPK TEBLIG (SERI:X, NO:22) - Sermaye Piyasasinda Bagimsiz Denetim Standartlari Hakkinda Teblig'; ayni=$true }
    @{ a='Sermaye Piyasası Kanunu'; b='SPKn'; ayni=$true }
    @{ a='Bankacılık K. (5411 s.K.)'; b='Sermaye Piyasası K. (6362 s.K.)'; ayni=$false }
    @{ a='TMS 12'; b='TMS 19'; ayni=$false }
    # 03.09 kanun-numarasi kanonu
    @{ a='5510 sayılı Kanun m.18'; b='5510 s. SGK Kanunu m.18'; ayni=$true }
    @{ a='3568 s. SMMM K. m.25/son fıkra'; b='SMMM K. (3568 s.K.) m.25'; ayni=$true }
    @{ a='3568 sayili Kanun m.48 (disiplin cezalari) ve Disiplin Yonetmeligi'; b='SMMM K. (3568 s.K.) m.48'; ayni=$true }
    @{ a='TTK (6102 s.K.) m.482'; b='TBK (6098 s.K.) m.20'; ayni=$false }
    @{ a='VUK (213 s.K.) m.275 - İmal edilen emtia'; b='VUK m.275'; ayni=$false }
  )
  $kotu=0
  foreach($v in $vakalar){
    $ka=DayanakAnahtar $v.a; $kb=DayanakAnahtar $v.b
    $sonuc=($ka -eq $kb)
    if($sonuc -ne $v.ayni){ $kotu++; Write-Host ("  HATA: '{0}' -> '{1}'  |  '{2}' -> '{3}'  (beklenen ayni={4})" -f $v.a,$ka,$v.b,$kb,$v.ayni) -ForegroundColor Red }
  }
  if($kotu){ Write-Host "  DAYANAK-NORMALIZE OZ-SINAVI DUSTU ($kotu)" -ForegroundColor Red; exit 2 }
  Write-Host "  DAYANAK-NORMALIZE OZ-SINAVI: $($vakalar.Count)/$($vakalar.Count) GECTI" -ForegroundColor Green
  exit 0
}
