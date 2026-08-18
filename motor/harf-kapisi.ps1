# ============================================================================
#  HARF KAPISI  (18.08.2026 — Cem: "butun riskleri kapatmadan soru basmak
#  istemiyorum"; A1 maddesi)
#
#  NEDEN VAR: uretim hatti kasaya yazarken Turkce harf denetimi YAPMIYORDU.
#  Agustos uretiminin ~%2'si bozuk girdi (16.08 olcumu: kasada 3.390 bozuk
#  satir / 63.434 gecis birikti). En agiri: "şık" kelimesinin duzlesmis hali
#  kufur okunuyor ve 293 satirda duruyor (acilis durdurucu). Temizlik ayri is;
#  bu kapinin isi YENI bozuk satir girmesini imkansiz kilmak.
#
#  KULLANIM: soru-uret.ps1 ve toplu-uret.ps1 dot-source eder;
#    $kusur = HarfKusuru $metin   ->  $null = temiz, dolu = RET sebebi
#
#  Dosya BOM'lu UTF-8 (PS 5.1 BOM'suz dosyada Turkce regexleri bozar).
# ============================================================================

# Duzlesmis halde YAZILDIGINDA baska gecerli Turkce kelimeye donusmeyen,
# sinav metinlerinde sik gecen kelimeler. ("vergisi" gibi zaten aksansiz
# gecerli kelimeler LISTEYE GIREMEZ - yanlis alarm uretir.)
$HARF_BOZUK_KELIMELER = @(
  'aciklama','yururluk','sozlesme','mukellef','sirket','duzenleme',
  'yukumluluk','donem','dogru','yanlis','odeme','ucret','butce','olcum',
  'uretim','musteri','tesvik','isci','isveren','sure','oduyor','gecerli'
)

function HarfKusuru([string]$metin){
  if(-not "$metin".Trim()){ return $null }
  # TUZAK (18.08'de olculdu): -match VARSAYILAN HARF-DUYARSIZ ve siniftaki
  # 'İ' (U+0130) Turkce kulturde kucuk 'i'ye katlanir -> '[...İ...]' sinifi
  # duz ASCII "i" harfini de yakalar, tam-ASCII testi HIC ateslenmez.
  # Cozum: metni bir kez kucult, sonra HARF-DUYARLI (-cmatch) desenlerle calis.
  $m = "$metin".ToLowerInvariant()

  # 1) KUFUR AILESI - tek gecis bile RET. "şık/şıkkı/şıkkın" duzlesince bu
  #    aileye duser. Onceki/sonraki harf sinirlariyla "eksik/beşik" gibi
  #    icinde geceni TUTMAZ. ("sikke" gibi nadir mesru kelime de takilir -
  #    kabul edilen bedel: yanlis RED ucuz, kufurun yayina sizmasi olumcul.)
  if($m -cmatch '(?<![a-zçğıöşü])sik(?:k[ıi]?[a-zçğıöşü]*)?(?![çğıöşü])'){
    return 'kufur-ailesi (sik*)'
  }

  # 2) TAM-ASCII - 80+ karakterlik Turkce sinav metninde HIC Turkce harf
  #    olmamasi imkansizdir; metin duzlesmis demektir.
  if($m.Length -ge 80 -and $m -cnotmatch '[çğıöşü]'){
    return 'tam-ascii (hic Turkce harf yok)'
  }

  # 3) SERPME - metinde Turkce harf VAR ama bilinen duzlesmis kelimeler de
  #    geciyor (kismi bozulma; 16.08 olcumundeki Sinif 1).
  foreach($k in $HARF_BOZUK_KELIMELER){
    if($m -cmatch ('(?<![a-zçğıöşü])' + [regex]::Escape($k) + '(?![a-zçğıöşü])')){
      return ('serpme-bozulma (' + $k + ')')
    }
  }
  return $null
}

# Sorunun TUM gorunen metnini tek dizeye toplar (kok + siklar + aciklamalar + hap).
function SoruMetniBirlestir($s){
  $parcalar = New-Object System.Collections.Generic.List[string]
  [void]$parcalar.Add("$($s.soru)")
  foreach($p in @($s.siklar.PSObject.Properties)){ [void]$parcalar.Add("$($p.Value)") }
  if($s.aciklama){
    if($s.aciklama -is [string]){ [void]$parcalar.Add("$($s.aciklama)") }
    else { foreach($p in @($s.aciklama.PSObject.Properties)){ [void]$parcalar.Add("$($p.Value)") } }
  }
  if($s.hap){ [void]$parcalar.Add("$($s.hap)") }
  return ($parcalar -join "`n")
}
