// Sauti hybrid inference bridge (Android).
//
// Gemini Nano on-device through Firebase AI Logic's hybrid SDK
// (InferenceMode.PREFER_ON_DEVICE), with cloud Gemini as fallback. On-device
// models have no function calling, so this bridge only does single-turn
// structured generation (a JSON intent). Sauti's permissioned tools run in
// Dart; no banking logic lives here.

package com.sauti.hybrid_ai

import android.content.Context
import com.google.firebase.Firebase
import com.google.firebase.FirebaseApp
import com.google.firebase.ai.GenerativeModel
import com.google.firebase.ai.InferenceMode
import com.google.firebase.ai.InferenceSource
import com.google.firebase.ai.OnDeviceConfig
import com.google.firebase.ai.ai
import com.google.firebase.ai.ondevice.FirebaseAIOnDevice
import com.google.firebase.ai.ondevice.OnDeviceModelStatus
import com.google.firebase.ai.type.GenerativeBackend
import com.google.firebase.ai.type.PublicPreviewAPI
import com.google.firebase.ai.type.generationConfig
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock

@OptIn(PublicPreviewAPI::class)
class SautiHybridAiPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main)
    private val models = mutableMapOf<String, GenerativeModel>()
    private val downloadLock = Mutex()

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, "sauti/hybrid_ai")
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        scope.cancel()
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "status" -> scope.launch { result.success(status()) }
            "generateJson" -> scope.launch {
                try {
                    result.success(generateJson(call))
                } catch (e: Exception) {
                    val (code, message) = classify(e)
                    result.error(code, message, null)
                }
            }
            "prepareOnDevice" -> scope.launch { result.success(prepareOnDevice()) }
            // Apple-only: a native session that drives the tool loop.
            "respond" -> result.error("unavailable", "no native tool loop on Android", null)
            else -> result.notImplemented()
        }
    }

    private fun firebaseReady(): Boolean = FirebaseApp.getApps(context).isNotEmpty()

    private suspend fun onDeviceState(): String {
        if (!firebaseReady()) return "unavailable"
        return try {
            when (FirebaseAIOnDevice.checkStatus()) {
                OnDeviceModelStatus.AVAILABLE -> "available"
                OnDeviceModelStatus.DOWNLOADABLE -> "downloadable"
                OnDeviceModelStatus.DOWNLOADING -> "downloading"
                else -> "unavailable"
            }
        } catch (e: Exception) {
            "unavailable"
        }
    }

    private suspend fun status(): Map<String, Any> {
        val state = onDeviceState()
        return mapOf(
            "onDevice" to (state == "available"),
            "onDeviceReason" to state,
            // The on-device model only classifies intent; Sauti renders the
            // reply in the user's language. Language policy lives in Dart.
            "onDeviceSupportsLanguage" to true,
            "cloud" to firebaseReady(),
            "onDeviceState" to state,
            "nativeToolLoop" to false,
        )
    }

    /** The SDK never downloads Gemini Nano by itself; the user starts it from Settings. */
    private suspend fun prepareOnDevice(): String = downloadLock.withLock {
        if (onDeviceState() == "downloadable") {
            try {
                FirebaseAIOnDevice.download().collect { }
            } catch (e: Exception) {
                // Reported through the resulting state below.
            }
        }
        onDeviceState()
    }

    private fun model(mode: InferenceMode, modeKey: String, cloudModel: String): GenerativeModel =
        models.getOrPut("$modeKey|$cloudModel") {
            Firebase.ai(FirebaseApp.getInstance(), GenerativeBackend.googleAI(), true) // limited-use App Check tokens
                .generativeModel(
                    modelName = cloudModel,
                    generationConfig = generationConfig {
                        temperature = 0f
                        maxOutputTokens = 256
                    },
                    onDeviceConfig = OnDeviceConfig(mode, 256, 0f),
                )
        }

    private suspend fun generateJson(call: MethodCall): Map<String, Any> {
        if (!firebaseReady()) throw IllegalStateException("unavailable: Firebase is not initialised")
        val instructions = call.argument<String>("instructions") ?: ""
        val prompt = call.argument<String>("prompt") ?: ""
        val schema = call.argument<String>("schema") ?: "{}"
        val allowOnDevice = call.argument<Boolean>("allowOnDevice") ?: false
        val allowCloud = call.argument<Boolean>("allowCloud") ?: false
        val cloudModel = call.argument<String>("cloudModel") ?: "gemini-3.5-flash-lite"

        val (mode, key) = when {
            allowOnDevice && allowCloud -> InferenceMode.PREFER_ON_DEVICE to "prefer_on_device"
            allowOnDevice -> InferenceMode.ONLY_ON_DEVICE to "only_on_device"
            allowCloud -> InferenceMode.ONLY_IN_CLOUD to "only_in_cloud"
            else -> throw IllegalStateException("unavailable: no inference path allowed")
        }
        // On-device structured output needs KSP-generated schemas; Sauti's
        // schema is tiny and flat, so it is given in the prompt and the result
        // is strictly validated in Dart.
        val text = "$instructions\n\nReply with only one JSON object matching this JSON schema:\n$schema\n\n$prompt"
        val response = model(mode, key, cloudModel).generateContent(text)
        return mapOf(
            "text" to (response.text ?: ""),
            "servedBy" to if (response.inferenceSource == InferenceSource.ON_DEVICE) "onDevice" else "cloud",
        )
    }

    private fun classify(e: Exception): Pair<String, String> {
        val name = e.javaClass.simpleName
        val message = e.message ?: name
        return when {
            message.startsWith("unavailable") -> "unavailable" to message
            name.contains("Quota") || message.contains("BUSY") || message.contains("QUOTA") -> "quota" to message
            name.contains("OnDeviceNotAvailable") -> "unavailable" to message
            name.contains("ServiceConnection") || e is java.io.IOException -> "network" to message
            name.contains("PromptBlocked") || name.contains("ResponseStopped") -> "blocked" to message
            else -> "unknown" to "$name: $message"
        }
    }
}
