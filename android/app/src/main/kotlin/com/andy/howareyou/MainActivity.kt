package com.andy.howareyou

import android.os.Bundle
import com.android.installreferrer.api.InstallReferrerClient
import com.android.installreferrer.api.InstallReferrerStateListener
import com.android.installreferrer.api.ReferrerDetails
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getInstallReferrer") {
                getInstallReferrer { referrer ->
                    result.success(referrer)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private fun getInstallReferrer(callback: (String?) -> Unit) {
        val client = InstallReferrerClient.newBuilder(this).build()
        client.startConnection(object : InstallReferrerStateListener {
            override fun onInstallReferrerSetupFinished(responseCode: Int) {
                when (responseCode) {
                    InstallReferrerClient.InstallReferrerResponse.OK -> {
                        try {
                            val response: ReferrerDetails? = client.installReferrer
                            val referrer = response?.installReferrer?.toString()
                            callback(if (referrer.isNullOrBlank()) null else referrer)
                        } catch (e: Exception) {
                            callback(null)
                        } finally {
                            client.endConnection()
                        }
                    }
                    else -> {
                        client.endConnection()
                        callback(null)
                    }
                }
            }
            override fun onInstallReferrerServiceDisconnected() {
                callback(null)
            }
        })
    }

    companion object {
        private const val CHANNEL = "howareyou/install_referrer"
    }
}
