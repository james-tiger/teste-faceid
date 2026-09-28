package br.com.delivy.lab_facial_delivy

import android.app.Activity
import android.content.Intent
import android.graphics.Bitmap
import android.os.Build
import android.provider.MediaStore
import android.util.Base64
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.io.File
import java.nio.charset.StandardCharsets
import java.security.KeyStore
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import kotlin.math.sqrt

class MainActivity : FlutterActivity() {
    private val channelName = "lab_facial_delivy/device"
    private val captureRequest = 7401
    private val stateFileName = "lab_state.enc"
    private val keyAlias = "lab_facial_delivy_state_v1"
    private var pendingCapture: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler(::handleCall)
    }

    private fun handleCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "capturePhoto" -> capturePhoto(result)
            "saveEncryptedState" -> {
                val json = call.argument<String>("json")
                if (json == null) result.error("INVALID_DATA", "Estado ausente", null)
                else runCatching { saveEncrypted(json); true }
                    .onSuccess { result.success(null) }
                    .onFailure { result.error("SECURE_WRITE", it.message, null) }
            }
            "loadEncryptedState" -> runCatching { loadEncrypted() }
                .onSuccess(result::success)
                .onFailure { result.error("SECURE_READ", it.message, null) }
            "purgeEncryptedState" -> runCatching {
                File(filesDir, stateFileName).delete()
            }.onSuccess { result.success(null) }
                .onFailure { result.error("PURGE", it.message, null) }
            "diagnostics" -> result.success(
                mapOf(
                    "platform" to "Android",
                    "androidVersion" to "${Build.VERSION.RELEASE} (API ${Build.VERSION.SDK_INT})",
                    "encryptedStateExists" to File(filesDir, stateFileName).exists(),
                    "keystore" to "Android Keystore + AES/GCM",
                    "networkUsed" to false,
                    "rawPhotosPersisted" to false,
                )
            )
            else -> result.notImplemented()
        }
    }

    private fun capturePhoto(result: MethodChannel.Result) {
        if (pendingCapture != null) {
            result.error("CAPTURE_BUSY", "Já existe uma captura em andamento", null)
            return
        }
        val intent = Intent(MediaStore.ACTION_IMAGE_CAPTURE).apply {
            putExtra("android.intent.extras.CAMERA_FACING", 1)
            putExtra("android.intent.extra.USE_FRONT_CAMERA", true)
            putExtra("android.intent.extras.LENS_FACING_FRONT", 1)
        }
        if (intent.resolveActivity(packageManager) == null) {
            result.error("NO_CAMERA", "Nenhum aplicativo de câmera disponível", null)
            return
        }
        pendingCapture = result
        startActivityForResult(intent, captureRequest)
    }

    @Deprecated("Legacy activity result is sufficient for this isolated prototype")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != captureRequest) return
        val result = pendingCapture ?: return
        pendingCapture = null
        if (resultCode != Activity.RESULT_OK) {
            result.success(null)
            return
        }
        @Suppress("DEPRECATION")
        val bitmap = data?.extras?.get("data") as? Bitmap
        if (bitmap == null) {
            result.error("EMPTY_CAPTURE", "A câmera não retornou uma imagem", null)
            return
        }
        runCatching { analyze(bitmap) }
            .onSuccess(result::success)
            .onFailure { result.error("IMAGE_ANALYSIS", it.message, null) }
    }

    private fun analyze(source: Bitmap): Map<String, Any> {
        val side = minOf(source.width, source.height)
        val left = (source.width - side) / 2
        val top = (source.height - side) / 2
        val square = Bitmap.createBitmap(source, left, top, side, side)
        val preview = Bitmap.createScaledBitmap(square, 256, 256, true)
        val grid = Bitmap.createScaledBitmap(square, 16, 16, true)
        val detail = Bitmap.createScaledBitmap(square, 96, 96, true)

        val values = mutableListOf<Double>()
        var sum = 0.0
        for (y in 0 until 16) {
            for (x in 0 until 16) {
                val luminance = luminance(grid.getPixel(x, y))
                values.add(luminance)
                sum += luminance
            }
        }
        val mean = sum / values.size
        val variance = values.sumOf { (it - mean) * (it - mean) } / values.size
        val contrast = sqrt(variance)

        var edge = 0.0
        var edgeCount = 0
        for (y in 1 until 95) {
            for (x in 1 until 95) {
                val center = luminance(detail.getPixel(x, y))
                val leftPixel = luminance(detail.getPixel(x - 1, y))
                val topPixel = luminance(detail.getPixel(x, y - 1))
                edge += kotlin.math.abs(center - leftPixel) + kotlin.math.abs(center - topPixel)
                edgeCount += 2
            }
        }
        val normalized = if (contrast > 0.0001) {
            values.map { ((it - mean) / contrast).coerceIn(-3.0, 3.0) / 6.0 + 0.5 }
        } else values

        val output = ByteArrayOutputStream()
        preview.compress(Bitmap.CompressFormat.JPEG, 82, output)
        val encoded = Base64.encodeToString(output.toByteArray(), Base64.NO_WRAP)
        if (square !== source) square.recycle()
        preview.recycle()
        grid.recycle()
        detail.recycle()
        return mapOf(
            "jpegBase64" to encoded,
            "features" to normalized,
            "brightness" to mean,
            "contrast" to contrast,
            "sharpness" to (edge / edgeCount),
        )
    }

    private fun luminance(color: Int): Double {
        val r = (color shr 16) and 0xff
        val g = (color shr 8) and 0xff
        val b = color and 0xff
        return (0.2126 * r + 0.7152 * g + 0.0722 * b) / 255.0
    }

    private fun getOrCreateKey(): SecretKey {
        val keyStore = KeyStore.getInstance("AndroidKeyStore").apply { load(null) }
        (keyStore.getKey(keyAlias, null) as? SecretKey)?.let { return it }
        val generator = KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, "AndroidKeyStore")
        generator.init(
            KeyGenParameterSpec.Builder(
                keyAlias,
                KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT,
            ).setBlockModes(KeyProperties.BLOCK_MODE_GCM)
                .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
                .setRandomizedEncryptionRequired(true)
                .build()
        )
        return generator.generateKey()
    }

    private fun saveEncrypted(json: String) {
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        cipher.init(Cipher.ENCRYPT_MODE, getOrCreateKey())
        val encrypted = cipher.doFinal(json.toByteArray(StandardCharsets.UTF_8))
        val bytes = byteArrayOf(cipher.iv.size.toByte()) + cipher.iv + encrypted
        val target = File(filesDir, stateFileName)
        val temporary = File(filesDir, "$stateFileName.tmp")
        temporary.writeBytes(bytes)
        if (!temporary.renameTo(target)) {
            target.delete()
            check(temporary.renameTo(target)) { "Falha ao concluir gravação segura" }
        }
    }

    private fun loadEncrypted(): String? {
        val target = File(filesDir, stateFileName)
        if (!target.exists()) return null
        val bytes = target.readBytes()
        require(bytes.isNotEmpty()) { "Arquivo protegido vazio" }
        val ivSize = bytes[0].toInt() and 0xff
        require(ivSize in 12..16 && bytes.size > ivSize + 1) { "Arquivo protegido inválido" }
        val iv = bytes.copyOfRange(1, ivSize + 1)
        val encrypted = bytes.copyOfRange(ivSize + 1, bytes.size)
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        cipher.init(Cipher.DECRYPT_MODE, getOrCreateKey(), GCMParameterSpec(128, iv))
        return String(cipher.doFinal(encrypted), StandardCharsets.UTF_8)
    }
}
