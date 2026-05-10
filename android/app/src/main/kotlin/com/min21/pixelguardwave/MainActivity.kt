package com.min21.pixelguardwave

import android.media.AudioAttributes
import android.media.SoundPool
import io.flutter.FlutterInjector
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private var soundPool: SoundPool? = null
    private val soundIds = mutableMapOf<String, Int>()
    private val loadedSoundIds = mutableSetOf<Int>()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "depense_game/combat_sfx"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "preload" -> {
                    val assets = call.argument<List<String>>("assets").orEmpty()
                    result.success(preloadAssets(assets))
                }

                "play" -> {
                    val asset = call.argument<String>("asset")
                    val volume = (call.argument<Double>("volume") ?: 1.0).toFloat()
                    if (asset == null) {
                        result.success(false)
                    } else {
                        result.success(playAsset(asset, volume))
                    }
                }

                "release" -> {
                    releaseCombatSfx()
                    result.success(null)
                }

                else -> result.notImplemented()
            }
        }
    }

    override fun onDestroy() {
        releaseCombatSfx()
        super.onDestroy()
    }

    private fun ensureSoundPool(): SoundPool {
        val existing = soundPool
        if (existing != null) {
            return existing
        }

        val attributes = AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_GAME)
            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
            .build()

        val pool = SoundPool.Builder()
            .setAudioAttributes(attributes)
            .setMaxStreams(6)
            .build()

        pool.setOnLoadCompleteListener { _, sampleId, status ->
            if (status == 0) {
                loadedSoundIds.add(sampleId)
            }
        }

        soundPool = pool
        return pool
    }

    private fun preloadAssets(assets: List<String>): Boolean {
        return try {
            val pool = ensureSoundPool()
            var loadedCount = 0
            for (asset in assets) {
                if (soundIds.containsKey(asset)) {
                    loadedCount += 1
                    continue
                }

                val cachedFile = cacheAssetToFile(asset) ?: continue
                val soundId = pool.load(cachedFile.absolutePath, 1)
                if (soundId > 0) {
                    soundIds[asset] = soundId
                    loadedCount += 1
                }
            }
            loadedCount > 0
        } catch (_: Throwable) {
            false
        }
    }

    private fun playAsset(asset: String, volume: Float): Boolean {
        val pool = soundPool ?: return false
        val soundId = soundIds[asset] ?: return false
        if (!loadedSoundIds.contains(soundId)) {
            return false
        }

        val streamId = pool.play(soundId, volume, volume, 1, 0, 1.0f)
        return streamId != 0
    }

    private fun cacheAssetToFile(asset: String): File? {
        return try {
            val lookupKey = FlutterInjector.instance()
                .flutterLoader()
                .getLookupKeyForAsset("assets/audio/$asset")
            val targetDir = File(cacheDir, "combat_sfx").apply { mkdirs() }
            val targetFile = File(targetDir, asset.replace("/", "_"))
            if (!targetFile.exists()) {
                assets.open(lookupKey).use { input ->
                    targetFile.outputStream().use { output ->
                        input.copyTo(output)
                    }
                }
            }
            targetFile
        } catch (_: Throwable) {
            null
        }
    }

    private fun releaseCombatSfx() {
        soundPool?.release()
        soundPool = null
        soundIds.clear()
        loadedSoundIds.clear()
    }
}
