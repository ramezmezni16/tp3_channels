
package tn.isetbizerte.tp3_channels

import android.annotation.SuppressLint
import android.media.AudioFormat
import android.media.AudioRecord
import android.media.MediaRecorder
import io.flutter.plugin.common.EventChannel
import kotlinx.coroutines.*
import kotlin.math.log10
import kotlin.math.sqrt

class NiveauSonore(private val scope: CoroutineScope) :
    EventChannel.StreamHandler {

    private var job: Job? = null
    private var dernierEnvoi = 0L

    @SuppressLint("MissingPermission")
    override fun onListen(
        arguments: Any?,
        events: EventChannel.EventSink
    ) {
        job = scope.launch(Dispatchers.IO) {

            val frequence = 44100

            val taille = AudioRecord.getMinBufferSize(
                frequence,
                AudioFormat.CHANNEL_IN_MONO,
                AudioFormat.ENCODING_PCM_16BIT
            )

            if (taille <= 0) {
                withContext(Dispatchers.Main) {
                    events.error(
                        "MICRO_INDISPONIBLE",
                        "Taille de buffer audio invalide",
                        null
                    )
                }
                return@launch
            }

            val micro = AudioRecord(
                MediaRecorder.AudioSource.MIC,
                frequence,
                AudioFormat.CHANNEL_IN_MONO,
                AudioFormat.ENCODING_PCM_16BIT,
                taille
            )

            if (micro.state != AudioRecord.STATE_INITIALIZED) {
                micro.release()

                withContext(Dispatchers.Main) {
                    events.error(
                        "MICRO_INDISPONIBLE",
                        "Microphone indisponible",
                        null
                    )
                }
                return@launch
            }

            val echantillons = ShortArray(taille)

            try {
                micro.startRecording()

                while (isActive) {
                    val n = micro.read(
                        echantillons,
                        0,
                        echantillons.size
                    )

                    if (n > 0) {
                        val maintenant = System.currentTimeMillis()

                        // Bonus: envoyer au maximum une mesure toutes les 200 ms
                        if (maintenant - dernierEnvoi >= 200) {
                            dernierEnvoi = maintenant

                            var somme = 0.0

                            for (i in 0 until n) {
                                val valeur = echantillons[i].toDouble()
                                somme += valeur * valeur
                            }

                            val rms = sqrt(somme / n)

                            val db = if (rms > 0) {
                                20 * log10(rms / Short.MAX_VALUE)
                            } else {
                                -90.0
                            }

                            withContext(Dispatchers.Main) {
                                events.success(db)
                            }
                        }
                    }
                }
            } finally {
                if (micro.recordingState ==
                    AudioRecord.RECORDSTATE_RECORDING
                ) {
                    micro.stop()
                }

                micro.release()
            }
        }
    }

    override fun onCancel(arguments: Any?) {
        job?.cancel()
        job = null
    }
}
