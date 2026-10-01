package com.orman.orman

import com.google.firebase.installations.FirebaseInstallations
import com.google.firebase.messaging.FirebaseMessaging
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, FID_CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == REGISTER_FID_METHOD) {
                    registerFid(result)
                } else {
                    result.notImplemented()
                }
            }
    }

    private fun registerFid(result: MethodChannel.Result) {
        try {
            FirebaseMessaging.getInstance().register()
                .addOnSuccessListener {
                    FirebaseInstallations.getInstance().id
                        .addOnSuccessListener { fid ->
                            if (fid.isNullOrBlank()) {
                                result.error(
                                    "invalid_fid",
                                    "Firebase returned an invalid installation ID.",
                                    null,
                                )
                            } else {
                                result.success(fid)
                            }
                        }
                        .addOnFailureListener {
                            result.error(
                                "fid_retrieval_failed",
                                "Unable to retrieve the registered Firebase installation ID.",
                                null,
                            )
                        }
                }
                .addOnFailureListener {
                    result.error(
                        "fcm_registration_failed",
                        "Firebase Messaging registration failed.",
                        null,
                    )
                }
        } catch (_: Exception) {
            result.error(
                "fcm_registration_failed",
                "Firebase Messaging registration failed.",
                null,
            )
        }
    }

    private companion object {
        const val FID_CHANNEL = "com.orman.orman/fcm_fid_registration"
        const val REGISTER_FID_METHOD = "registerFid"
    }
}
