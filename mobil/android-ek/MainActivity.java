package com.tetikte.app;

/*
 * 27.09.2026 (mobil 1.6.5) — Google ile giriş için ana etkinlik.
 * @capgo/capacitor-social-login Android'de hesap seçildikten sonra izin (Authorization) ekranını
 * startIntentSenderForResult ile açıyor; sonucu bu etkinliğin onActivityResult'u alır. Varsayılan Capacitor
 * MainActivity bunu eklentiye İLETMİYOR → login sözü hiç sonuçlanmıyor (Cem: "hata vermiyor ama ilerlemiyor").
 * Derlemede mobil-android.yml bu dosyayı `npx cap add android`'in ürettiği MainActivity'nin üstüne kopyalar.
 */
import android.content.Intent;
import android.util.Log;
import com.getcapacitor.BridgeActivity;
import com.getcapacitor.Plugin;
import com.getcapacitor.PluginHandle;
import ee.forgr.capacitor.social.login.GoogleProvider;
import ee.forgr.capacitor.social.login.ModifiedMainActivityForSocialLoginPlugin;
import ee.forgr.capacitor.social.login.SocialLoginPlugin;

public class MainActivity extends BridgeActivity implements ModifiedMainActivityForSocialLoginPlugin {

    @Override
    public void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        if (requestCode >= GoogleProvider.REQUEST_AUTHORIZE_GOOGLE_MIN && requestCode < GoogleProvider.REQUEST_AUTHORIZE_GOOGLE_MAX) {
            PluginHandle handle = getBridge().getPlugin("SocialLogin");
            if (handle == null) {
                Log.i("Tetikte", "SocialLogin eklentisi bulunamadi");
                return;
            }
            Plugin plugin = handle.getInstance();
            if (!(plugin instanceof SocialLoginPlugin)) {
                Log.i("Tetikte", "SocialLogin eklentisi beklenen turde degil");
                return;
            }
            ((SocialLoginPlugin) plugin).handleGoogleLoginIntent(requestCode, data);
        }
    }

    @Override
    public void IHaveModifiedTheMainActivityForTheUseWithSocialLoginPlugin() {}
}
