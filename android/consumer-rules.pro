# MexaAds Plugin — keep all plugin classes so Flutter can find them via reflection
-keep class com.mexa.mexa_ads.** { *; }

# Adjust SDK Rules
-keep public class com.adjust.sdk.** { *; }
-keep class com.google.android.gms.common.ConnectionResult {
    int SUCCESS;
}
-keep class com.google.android.gms.ads.identifier.AdvertisingIdClient {
    com.google.android.gms.ads.identifier.AdvertisingIdClient$Info getAdvertisingIdInfo(android.content.Context);
}
-keep class com.google.android.gms.ads.identifier.AdvertisingIdClient$Info {
    java.lang.String getId();
    boolean isLimitAdTrackingEnabled();
}
-keep public class com.android.installreferrer.** { *; }

# Google Mobile Ads & Core Unity / Pangle / AppLovin / IronSource Mediation Base Keeps
-keep class io.flutter.plugins.googlemobileads.** { *; }
-keep class com.google.android.gms.ads.** { *; }
-keep class com.google.ads.mediation.** { *; }
-keep class com.applovin.** { *; }
-keep class com.ironsource.** { *; }
-keep class com.unity3d.ads.** { *; }
-keep class com.bytedance.sdk.openadsdk.** { *; }
