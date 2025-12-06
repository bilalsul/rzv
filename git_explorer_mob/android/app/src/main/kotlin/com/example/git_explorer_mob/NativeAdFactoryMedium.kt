package com.bilalworku.gzip

import android.content.Context
import android.view.LayoutInflater
import android.view.View
import android.widget.Button
import android.widget.ImageView
import android.widget.TextView
import com.google.android.gms.ads.nativead.MediaView
import com.google.android.gms.ads.nativead.NativeAd
import com.google.android.gms.ads.nativead.NativeAdView
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin

class NativeAdFactoryMedium(private val context: Context) : GoogleMobileAdsPlugin.NativeAdFactory {
	override fun createNativeAd(nativeAd: NativeAd, customOptions: Map<String, Any>?): NativeAdView {
		val adView = LayoutInflater.from(context)
			.inflate(R.layout.native_ads_medium, null) as NativeAdView

		adView.mediaView = adView.findViewById<MediaView>(R.id.native_ad_media)
		adView.headlineView = adView.findViewById<TextView>(R.id.native_ad_headline)
		adView.bodyView = adView.findViewById<TextView>(R.id.native_ad_body)
		adView.iconView = adView.findViewById<ImageView>(R.id.native_ad_icon)
		adView.callToActionView = adView.findViewById<Button>(R.id.native_ad_button)

		(adView.headlineView as TextView).text = nativeAd.headline
		(adView.bodyView as TextView).text = nativeAd.body

		if (nativeAd.icon != null) {
			(adView.iconView as ImageView).setImageDrawable(nativeAd.icon?.drawable)
		} else {
			adView.iconView?.visibility = View.GONE
		}

		(adView.callToActionView as Button).text = nativeAd.callToAction
		adView.setNativeAd(nativeAd)

		return adView
	}
}
