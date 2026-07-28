# gm-okuma-10.ps1 - 28.07.2026  (BOM'lu kaydedilmeli)
# GM OKUMASI, PARTI 10: Hukuk dersinin TBK'ya dayanan 30 sorusu ('katman1-temiz').
#
# AMBARDAN BIRINCI ELDEN OKUNAN TBK MADDELERI:
#   m.63 hukuka aykiriligi kaldiran haller (zarar gorenin rizasi dahil)  -> DOGRU atif
#   m.64 haklı savunma / ZORUNLULUK HALI - hakim hakkaniyete gore belirler -> DOGRU
#   m.65 hakkaniyet sorumlulugu (ayirt etme gucu bulunmayan)            -> DOGRU
#   m.66 adam calistiranin sorumlulugu + kurtulus kaniti                -> DOGRU
#   m.69 yapi malikinin sorumlulugu (yapim bozuklugu / bakim eksikligi) -> DOGRU
#   m.71 tehlike sorumlulugu (kurtulus kaniti YOK)                      -> DOGRU
#   m.72 haksiz fiil zamanasimi: 2 yil / her halde 10 yil + uzamis ceza -> DOGRU
#   m.74 hukuk hakimi ceza hakiminin beraat/kusur kararlariyla bagli degil -> DOGRU
#   m.82 sebepsiz zenginlesme zamanasimi: 2 yil / 10 yil                -> DOGRU
#   m.133 yenileme (tecdit) - senet duzenlenmesi tek basina yenileme degil -> DOGRU
#   m.135 birlesme                                                      -> DOGRU
#   m.153 zamanasiminin durmasi (vesayet suresince)                     -> DOGRU
#   m.154 zamanasiminin kesilmesi (icra takibi dahil)                   -> DOGRU
#   m.231 ayipta zamanasimi: teslimden itibaren 2 yil                   -> DOGRU
#
# 30 SORUNUN 30'UNUN DA CEVABI DOGRU. Dort ATIF hatasi + bir nuans hatasi duzeltildi:
#   2becde55: ibra icin m.131 yazilmis. m.131 asil borca BAGLI hak ve borclarin
#             sona ermesini duzenler; IBRA m.132'dir.
#   8386b7d1: takasin gecmise etkili olmasi icin m.134 yazilmis. m.134 CARI HESAP
#             yenilemesini duzenler; takasin etkisi m.143'tedir ("her iki borc,
#             takas edilebilecekleri anda ... sona erer").
#   039c6c79: m.139 + m.144 yazilmis. m.144 alacaklinin RIZASIYLA takas edilebilen
#             ozel alacaklari sayar; tek yanli beyanla takas m.143'tedir.
#   a425b25c: m.75 yazilmis. m.75 BEDENSEL ZARARDA tazminat hukmunu degistirme
#             yetkisini duzenler; konuyla ilgisi yoktur.
#   85f7aa8b: m.69 KUSURSUZ (objektif) sorumluluktur; malik "gerekli ozeni gosterdim"
#             diyerek kurtulamaz. Sikkin metni bu nuansi yanlis ogretiyordu, duzeltildi.

$ErrorActionPreference = "Stop"
$kok = Split-Path -Parent $PSScriptRoot
$fabrikaDir = Join-Path $kok "veri\fabrika"

$KAYNAK = @{
  '2becde55' = "TBK (6098 s.K.) m.132 (ibra sözleşmesi) — eski atıf m.131 asıl borca bağlı hak ve borçların sona ermesini düzenler"
  '8386b7d1' = "TBK (6098 s.K.) m.143 (takas beyanı ve geçmişe etkisi) — eski atıf m.134 cari hesapta yenilemeyi düzenler"
  '039c6c79' = "TBK (6098 s.K.) m.139 (takasın şartları) ve m.143 (tek yanlı beyanla takas) — eski atıftaki m.144 alacaklının rızasıyla takas edilebilen özel alacakları sayar"
  'a425b25c' = "TBK (6098 s.K.) m.74 (hukuk hâkiminin ceza hâkiminin kararıyla bağlı olmaması) — eski atıf m.75 bedensel zararda tazminat hükmünü değiştirme yetkisini düzenler, konuyla ilgisi yoktur"
}

$ist = [ordered]@{ onay=0; kaynakDuzeltildi=0; sikDuzeltildi=0; gorulen=0 }

foreach($d in @(Get-ChildItem $fabrikaDir -Filter *.json | Sort-Object Name)){
  try { $x = Get-Content $d.FullName -Raw -Encoding UTF8 | ConvertFrom-Json } catch { continue }
  if(-not $x.sorular){ continue }
  $degisti = $false

  foreach($s in @($x.sorular)){
    if(-not $s -or "$($s.durum)" -ne 'katman1-temiz' -or "$($s.ders)" -ne 'Hukuk'){ continue }
    if("$($s.kaynak)" -notmatch '6098|TBK'){ continue }
    $id = "$($s.id)"; $ist.gorulen++

    if($KAYNAK.ContainsKey($id)){
      $s | Add-Member -NotePropertyName eskiKaynak -NotePropertyValue "$($s.kaynak)" -Force
      $s.kaynak = $KAYNAK[$id]
      $ist.kaynakDuzeltildi++
    }

    if($id -eq '85f7aa8b'){
      $s.siklar.C = "Yapıda bozukluk veya bakım eksikliği bulunmadığını ya da zarar ile bunlar arasında illiyet bağı olmadığını ispat etmesi gerekir"
      $s.siklar.A = "Zararın doğmasında kişisel kusuru bulunmadığını ispat etmesi yeterlidir"
      $s.aciklama.C = "Doğru. TBK m.69 yapı malikine KUSURSUZ (objektif) bir sorumluluk yükler: malik, yapımdaki bozukluklardan veya bakımdaki eksikliklerden doğan zararı gidermekle yükümlüdür. Madde, adam çalıştıranın sorumluluğundaki gibi bir 'gerekli özeni gösterdim' kurtuluş kanıtı tanımaz. Malik ancak bozukluğun/bakım eksikliğinin hiç bulunmadığını ya da zararla arasında illiyet bağı olmadığını ispat ederek kurtulabilir."
      $s.aciklama.A = "Yanlış. m.69 kusura dayalı bir sorumluluk değildir; malikin kişisel kusursuzluğu tek başına onu sorumluluktan kurtarmaz."
      $s | Add-Member -NotePropertyName gmNot -NotePropertyValue "Şık düzeltildi: eski C şıkkı 'bozukluğun bulunmadığını VE gerekli özeni gösterdiğini ispat' diyordu; m.69 objektif sorumluluk olduğundan özen ispatı bir kurtuluş kanıtı değildir. Bu nüans yanlış öğretiliyordu." -Force
      $ist.sikDuzeltildi++
    }

    $s.durum = 'gm-onay'
    $s | Add-Member -NotePropertyName gmKarar -NotePropertyValue "GM okudu (28.07): TBK m.63,64,65,66,69,71,72,74,82,132,133,135,139,143,153,154,231 ambardan birinci elden okundu; cevap doğrulandı, atıf gerekiyorsa düzeltildi." -Force
    $s | Add-Member -NotePropertyName gmTarih -NotePropertyValue "28.07.2026" -Force
    $g = if("$($s.konu)" -match 'zamanasimi'){'huk-tbk-zamanasimi'} elseif("$($s.konu)" -match 'sona erme'){'huk-tbk-borc-sona-erme'} elseif("$($s.konu)" -match 'ceza hukuku'){'huk-tbk-ceza-iliski'} elseif("$($s.konu)" -match 'ispat'){'huk-tbk-ispat'} else {'huk-tbk-haksiz-fiil'}
    $s | Add-Member -NotePropertyName benzerGrup -NotePropertyValue $g -Force
    $ist.onay++; $degisti = $true
  }

  if($degisti){ [IO.File]::WriteAllText($d.FullName, ($x | ConvertTo-Json -Depth 8), (New-Object Text.UTF8Encoding($false))) }
}

Write-Host "======== GM OKUMASI PARTI 10 (Hukuk / TBK blogu) ========"
foreach($k in $ist.Keys){ Write-Host ("  {0,-18} {1}" -f $k, $ist[$k]) }

# --- yazma sonrasi METIN dogrulamasi
Write-Host ""
$hata = 0
foreach($d in @(Get-ChildItem $fabrikaDir -Filter *.json)){
  try { $x = Get-Content $d.FullName -Raw -Encoding UTF8 | ConvertFrom-Json } catch { continue }
  foreach($s in @($x.sorular)){
    if(-not $s){ continue }
    if($KAYNAK.ContainsKey("$($s.id)")){
      if("$($s.kaynak)" -ne $KAYNAK["$($s.id)"]){ $hata++; Write-Host ("  KAYNAK YAZILMADI: {0}" -f $s.id) }
    }
    if("$($s.id)" -eq '85f7aa8b' -and "$($s.siklar.C)" -match 'gerekli özeni gösterdiğini ispat'){ $hata++; Write-Host "  SIK DUZELMEDI: 85f7aa8b" }
  }
}
if($hata -eq 0){ Write-Host "   temiz — tüm düzeltmeler metinde doğrulandı" } else { Write-Host "KIRMIZI"; exit 1 }
