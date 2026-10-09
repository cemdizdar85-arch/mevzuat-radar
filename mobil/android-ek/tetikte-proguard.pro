# ============================================================================
#  Tetikte - R8 ek kurallari (09.10.2026, Play "DEX optimizasyonu esigin altinda")
#  mobil-android.yml bu dosyayi android/app/ altina kopyalar ve release'e baglar.
#
#  Zaten gelenler (tekrar yazilmaz, consumer kurali olarak AAR'dan gelir):
#    - @capacitor/android  capacitor/proguard-rules.pro : Plugin alt siniflari + @PluginMethod
#    - @capgo/capacitor-social-login consumer-proguard-rules.pro :
#        ee.forgr.** + com.getcapacitor.** + gms.auth.** + googleid.** + androidx.credentials.**
#        + androidx.browser.customtabs.** + okhttp3 + jwtdecode
#    - Play Billing (native-purchases) kendi consumer kurallariyla gelir.
#  Asagidakiler o kurallarin KAPSAMADIGI, 09.10'da kaynaktan okunarak bulunan bosluklar.
# ============================================================================

# Google girisi: social-login DependencyAvailabilityChecker bu sinifi Class.forName ile ARIYOR
# (8.5.11, helpers/DependencyAvailabilityChecker.java:110). gms.common.** consumer kuralinda yok;
# R8 atar/yeniden adlandirirsa eklenti "Google bagimliligi yok" der ve Google girisi kapanir.
-keep class com.google.android.gms.common.api.ApiException

# Credential Manager'in resmi R8 kurali (developer.android.com/identity/sign-in/credential-manager).
# social-login'in androidx.credentials.** kurali bugun kapsiyor; eklenti surumu degisirse diye ayrica.
-if class androidx.credentials.CredentialManager
-keep class androidx.credentials.playservices.** { *; }

# Ana etkinlik: Google izin ekraninin sonucunu eklentiye iletir (android-ek/MainActivity.java).
-keep class com.tetikte.app.MainActivity { *; }

# Play Console'daki cokme yiginlari mapping.txt ile acilir; satir numarasi kalsin.
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile
