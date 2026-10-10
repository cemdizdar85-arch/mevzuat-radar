# motor/model-kod.ps1 — soru verisine model adı girmez (10.10.2026, CLAUDE.md "veriye model adı girmez").
# Soru kaydındaki iz alanları (sade.model, hakem2.model, kor_cozum.model, konu_giris.model, teori_ikiz.model,
# simulasyon*.model, aciklama_hakem.model, hakem.ikinci_bakis.model, uyarlama.model …) model ADI yerine nötr KOD taşır.
# Kod, hangi model sınıfının yazdığı bilgisini korur (kör çözüm üreticiden farklı model mi? karne bunu gösterir):
#   model-a = haiku · model-b = sonnet · model-c = opus · model-x = başka claude-* değeri
# İstek gövdelerinde (messages / max_tokens / TopluTopla) gerçek ad KALIR — API onu ister; bu dosya yalnız VERİYE yazılanı çevirir.
# İki katman: (1) üreticiler kayda ModelKod ile yazar; (2) arac/parti-senkron.ps1 -Yukle ambara giden metni ModelIziNotrMetin'den geçirir
#   (yeni bir yazıcı ModelKod'u unutursa ambara ad gitmesin; iş durmaz, yalnız çevrilir ve sayılır).
# 🚫 GÖRMEZ: alan ADINDA geçen model (simulasyon_sonnet anahtarı, 30+ okuyan; ayrı iş) · düz metin içinde geçen ad
#   (soru/açıklama metni — ölçüldü 10.10: 15.382 kayıtta 0) · "model" dışındaki anahtarlara yazılmış claude-* değeri ·
#   '__' ile başlayan sistem partileri (toplu iş kaydı; api-hedef.ps1 bedel için gerçek adı okur, ÇEVRİLMEZ).

function ModelKod([string]$m) {
  if ("$env:MODEL_IZI_MUTASYON" -eq 'kod-yok') { return $m }
  $s = "$m".Trim()
  if ($s -notmatch '^(?i)claude-') { return $m }
  if ($s -match '(?i)haiku') { return 'model-a' }
  if ($s -match '(?i)sonnet') { return 'model-b' }
  if ($s -match '(?i)opus') { return 'model-c' }
  return 'model-x'
}

# JSON METNİNDE yalnız "model": "claude-…" çiftini çevirir (anahtar tam "model"; değer claude- ile başlar). Metnin başka hiçbir
# baytına dokunmaz (girinti, sıra, öteki alanlar aynı). Dönüş: @{ metin = …; sayi = çevrilen alan sayısı }.
function ModelIziNotrMetin([string]$metin) {
  $script:_mkSayi = 0
  if ("$env:MODEL_IZI_MUTASYON" -eq 'ag-yok') { return @{ metin = $metin; sayi = 0 } }
  $rx = [regex]'("model"\s*:\s*")(claude-[^"\\]*)(")'
  $yeni = $rx.Replace($metin, [System.Text.RegularExpressions.MatchEvaluator] { param($mt) $script:_mkSayi++; $mt.Groups[1].Value + (ModelKod $mt.Groups[2].Value) + $mt.Groups[3].Value })
  return @{ metin = $yeni; sayi = $script:_mkSayi }
}

# Parti etiketi sistem kaydı mı ('__' önekli: toplu iş kayıtları, gerçek model adı işlevsel). Bunlar çevrilmez.
function ModelIziSistemPartisi([string]$etiket) {
  if ("$env:MODEL_IZI_MUTASYON" -eq 'sistem-de') { return $false }
  return "$etiket".StartsWith('__')
}
