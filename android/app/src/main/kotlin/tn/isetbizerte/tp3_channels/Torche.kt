package tn.isetbizerte.tp3_channels

import android.content.Context
import android.hardware.camera2.CameraCharacteristics
import android.hardware.camera2.CameraManager
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class Torche(context: Context) : MethodChannel.MethodCallHandler {

    private val cameraManager =
        context.getSystemService(Context.CAMERA_SERVICE) as CameraManager

    override fun onMethodCall(
        call: MethodCall,
        result: MethodChannel.Result
    ) {
        when (call.method) {
            "changer" -> {
                val etat = call.argument<Boolean>("etat") ?: false

                try {
                    val cameraId = cameraManager.cameraIdList.firstOrNull {
                        val caracteristiques =
                            cameraManager.getCameraCharacteristics(it)

                        caracteristiques.get(
                            CameraCharacteristics.FLASH_INFO_AVAILABLE
                        ) == true
                    }

                    if (cameraId == null) {
                        result.error(
                            "PAS_DE_FLASH",
                            "Aucun flash disponible",
                            null
                        )
                        return
                    }

                    cameraManager.setTorchMode(cameraId, etat)
                    result.success(null)

                } catch (e: Exception) {
                    result.error("ERREUR_TORCHE", e.message, null)
                }
            }

            else -> result.notImplemented()
        }
    }
}