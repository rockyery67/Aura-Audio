package audio.aura.aura_audio

import android.Manifest
import android.app.Activity
import android.content.ComponentName
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.util.AtomicFile
import androidx.media3.common.*
import androidx.media3.common.util.UnstableApi
import androidx.media3.session.MediaController
import androidx.media3.session.SessionToken
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray
import org.json.JSONObject
import java.io.File
import java.util.concurrent.Executors
import com.google.common.util.concurrent.ListenableFuture

@UnstableApi
class MainActivity : FlutterActivity() {
    private var controller: MediaController? = null
    private var controllerFuture: ListenableFuture<MediaController>? = null
    private var sink: EventChannel.EventSink? = null
    private var pending: MethodChannel.Result? = null
    private var pickMode = ""
    private val worker = Executors.newSingleThreadExecutor()
    private val handler = Handler(Looper.getMainLooper())
    private var lastError = ""
    private val ticker = object : Runnable {
        override fun run() {
            controller?.let { sink?.success(mapOf("type" to "position", "position" to it.currentPosition.coerceAtLeast(0))) }
            handler.postDelayed(this, 500)
        }
    }
    override fun configureFlutterEngine(engine: FlutterEngine) {
        super.configureFlutterEngine(engine)
        EventChannel(engine.dartExecutor.binaryMessenger, "aura/events").setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink) { sink = events; emit() }
            override fun onCancel(arguments: Any?) { sink = null }
        })
        MethodChannel(engine.dartExecutor.binaryMessenger, "aura/native").setMethodCallHandler(::handle)
        val future = MediaController.Builder(this, SessionToken(this, ComponentName(this, PlaybackService::class.java))).buildAsync()
        controllerFuture = future
        future.addListener({
            try {
                controller = future.get()
                controller!!.addListener(object : Player.Listener {
                    override fun onEvents(player: Player, events: Player.Events) { emit() }
                    override fun onPlayerError(error: PlaybackException) {
                        lastError = "This file cannot be played. It may have been deleted, lost permission, or use an unsupported codec."
                        emit()
                    }
                })
                emit()
                handler.post(ticker)
            } catch (e: Exception) { lastError = "Audio service could not start: ${e.message}"; emit() }
        }, { command -> handler.post(command) })
    }
    private fun emit() {
        val p = controller ?: return
        val service = PlaybackService.instance
        sink?.success(mapOf("type" to "playback", "playing" to p.isPlaying, "ready" to true,
            "loading" to (p.playbackState == Player.STATE_BUFFERING), "position" to p.currentPosition.coerceAtLeast(0),
            "duration" to p.duration.coerceAtLeast(0), "index" to p.currentMediaItemIndex,
            "ids" to (0 until p.mediaItemCount).map { p.getMediaItemAt(it).mediaId },
            "shuffle" to p.shuffleModeEnabled, "repeat" to p.repeatMode, "speed" to p.playbackParameters.speed.toDouble(),
            "sleepAt" to (service?.sleepAt ?: 0), "error" to lastError, "sampleRate" to (service?.processor?.sampleRate ?: 48000)))
        lastError = ""
    }
    private fun async(result: MethodChannel.Result, block: () -> Any?) {
        worker.execute {
            try { val value = block(); handler.post { result.success(value) } }
            catch (e: Exception) { handler.post { result.error("local_access", e.message ?: "Local file operation failed", null) } }
        }
    }
    private fun scan(result: MethodChannel.Result) = async(result) {
        LibraryScanner(this) { count, name -> handler.post { sink?.success(mapOf("type" to "scan", "count" to count, "name" to name)) } }.scan()
    }
    private fun handle(call: MethodCall, result: MethodChannel.Result) {
        try {
            val p = controller
            when (call.method) {
                "loadState" -> async(result) {
                    val file = AtomicFile(File(filesDir, "state.json"))
                    try { String(file.readFully()) } catch (_: Exception) { "{}" }
                }
                "saveState" -> async(result) {
                    val file = AtomicFile(File(filesDir, "state.json"))
                    val stream = file.startWrite()
                    try { stream.write((call.arguments as String).toByteArray()); file.finishWrite(stream) }
                    catch (e: Exception) { file.failWrite(stream); throw e }
                    true
                }
                "scan" -> scan(result)
                "scanDevice" -> {
                    if (pending != null) { result.error("busy", "Another picker is open", null); return }
                    val permission = if (Build.VERSION.SDK_INT >= 33) Manifest.permission.READ_MEDIA_AUDIO else Manifest.permission.READ_EXTERNAL_STORAGE
                    if (checkSelfPermission(permission) == PackageManager.PERMISSION_GRANTED) scan(result)
                    else { pending = result; requestPermissions(arrayOf(permission), 21) }
                }
                "pickFolder", "pickFiles", "pickLyrics", "pickArtwork" -> {
                    if (pending != null) { result.error("busy", "Another picker is open", null); return }
                    pending = result; pickMode = call.method
                    val intent = if (pickMode == "pickFolder") Intent(Intent.ACTION_OPEN_DOCUMENT_TREE) else Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                        addCategory(Intent.CATEGORY_OPENABLE)
                        type = when (pickMode) { "pickLyrics" -> "*/*"; "pickArtwork" -> "image/*"; else -> "audio/*" }
                        putExtra(Intent.EXTRA_ALLOW_MULTIPLE, pickMode == "pickFiles")
                    }
                    intent.putExtra(Intent.EXTRA_LOCAL_ONLY, true)
                    intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION)
                    startActivityForResult(intent, 22)
                }
                "validate" -> async(result) {
                    (call.arguments as List<*>).map { raw ->
                        try { contentResolver.openFileDescriptor(Uri.parse(raw.toString()), "r")?.use { true } ?: false }
                        catch (_: Exception) { false }
                    }
                }
                "setQueue" -> {
                    checkNotNull(p) { "Audio service is starting. Please try again." }
                    val args = call.arguments as Map<*, *>
                    val items = (args["tracks"] as List<*>).map { itemFromJson(JSONObject(it as Map<*, *>)) }
                    lastError = ""; p.setMediaItems(items, (args["index"] as Number).toInt().coerceAtLeast(0), 0)
                    p.prepare(); if (args["play"] == true) p.play()
                    result.success(true)
                }
                "refreshReferences" -> {
                    val latest = (call.arguments as List<*>).map { JSONObject(it as Map<*, *>) }.associateBy { it.getString("id") }
                    if (p != null) for (i in 0 until p.mediaItemCount) {
                        val old = p.getMediaItemAt(i)
                        latest[old.mediaId]?.let { json ->
                            if (old.localConfiguration?.uri.toString() != json.optString("uri")) p.replaceMediaItem(i, itemFromJson(json))
                        }
                    }
                    result.success(true)
                }
                "play" -> { checkNotNull(p); if (p.playbackState == Player.STATE_ENDED) p.seekTo(0); if (p.playerError != null) p.prepare(); p.play(); result.success(true) }
                "pause" -> { p?.pause(); result.success(true) }
                "next" -> { p?.seekToNextMediaItem(); result.success(true) }
                "previous" -> { p?.seekToPrevious(); result.success(true) }
                "seek" -> { p?.seekTo((call.arguments as Number).toLong()); result.success(true) }
                "jump" -> { p?.seekToDefaultPosition((call.arguments as Number).toInt()); p?.play(); result.success(true) }
                "move" -> { val a = call.arguments as List<*>; p?.moveMediaItem((a[0] as Number).toInt(), (a[1] as Number).toInt()); result.success(true) }
                "remove" -> { p?.removeMediaItem((call.arguments as Number).toInt()); result.success(true) }
                "clear" -> { p?.stop(); p?.clearMediaItems(); result.success(true) }
                "append" -> { p?.addMediaItem(itemFromJson(JSONObject(call.arguments as Map<*, *>))); result.success(true) }
                "shuffle" -> { p?.shuffleModeEnabled = call.arguments == true; result.success(true) }
                "repeat" -> { p?.repeatMode = (call.arguments as Number).toInt(); result.success(true) }
                "speed" -> { p?.setPlaybackSpeed((call.arguments as Number).toFloat().coerceIn(0.5f, 2f)); result.success(true) }
                "sleep" -> { PlaybackService.instance?.setSleep((call.arguments as Number).toInt()); emit(); result.success(true) }
                "eq" -> {
                    val a = call.arguments as Map<*, *>
                    val gains = (a["gains"] as List<*>).map { (it as Number).toDouble().coerceIn(-12.0, 12.0) }.toDoubleArray()
                    require(gains.size == 10)
                    val config = EqConfig(a["enabled"] == true, gains, (a["preamp"] as Number).toDouble().coerceIn(-12.0, 12.0))
                    EqState.config = config
                    getSharedPreferences("engine", 0).edit().putString("eq", JSONObject(a).toString()).apply()
                    val rate = PlaybackService.instance?.processor?.sampleRate ?: 48000
                    result.success(mapOf("response" to EqualizerDsp.response(config, rate), "headroom" to EqualizerDsp.headroom(config, rate)))
                }
                "output" -> {
                    // Android owns routing. Never offer nonexistent Bluetooth/USB endpoints.
                    try { startActivity(Intent(Settings.Panel.ACTION_VOLUME)); result.success(true) }
                    catch (_: Exception) { startActivity(Intent(Settings.ACTION_SOUND_SETTINGS)); result.success(true) }
                }
                "notifications" -> { if (Build.VERSION.SDK_INT >= 33 && checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), 23); result.success(true) }
                "sources" -> result.success(getSharedPreferences("sources", 0).getStringSet("trees", emptySet())!!.toList())
                "history" -> {
                    val ids = JSONArray(getSharedPreferences("engine", 0).getString("history", "[]"))
                    result.success((0 until ids.length()).map { ids.getString(it) })
                }
                "diagnostics" -> {
                    val processor = PlaybackService.instance?.processor
                    result.success(mapOf("processedFrames" to (processor?.processedFrames ?: 0), "sampleRate" to (processor?.sampleRate ?: 0), "appliedGains" to processor?.appliedConfig?.gains?.toList(), "appliedEnabled" to processor?.appliedConfig?.enabled))
                }
                else -> result.notImplemented()
            }
        } catch (e: Exception) { result.error("audio", e.message ?: "Audio operation unavailable", null) }
    }
    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grants: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grants)
        if (requestCode == 21) {
            val result = pending; pending = null
            if (result != null) {
                if (grants.firstOrNull() == PackageManager.PERMISSION_GRANTED) scan(result)
                else result.error("permission", "Music access was denied. Choose a folder or individual files instead.", null)
            }
        }
    }
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != 22) return
        val result = pending ?: return
        pending = null
        if (resultCode != Activity.RESULT_OK || data == null) { result.success(null); return }
        val uris = if (data.clipData != null) (0 until data.clipData!!.itemCount).map { data.clipData!!.getItemAt(it).uri } else listOfNotNull(data.data)
        try {
            val allowed = setOf("com.android.externalstorage.documents", "com.android.providers.downloads.documents", "com.android.providers.media.documents", "media")
            require(uris.all { it.authority in allowed }) { "Choose files stored on this device using the system storage providers." }
            uris.forEach { contentResolver.takePersistableUriPermission(it, Intent.FLAG_GRANT_READ_URI_PERMISSION) }
            if (pickMode == "pickLyrics") {
                async(result) { contentResolver.openInputStream(uris.first())!!.bufferedReader().use { it.readText().take(200000) } }
            } else if (pickMode == "pickArtwork") {
                async(result) {
                    val destination = File(filesDir, "playlist-${System.currentTimeMillis()}.jpg")
                    contentResolver.openInputStream(uris.first())!!.use { input -> destination.outputStream().use { input.copyTo(it) } }
                    destination.absolutePath
                }
            } else {
                val prefs = getSharedPreferences("sources", 0)
                val key = if (pickMode == "pickFolder") "trees" else "files"
                val sources = prefs.getStringSet(key, emptySet())!!.toMutableSet()
                sources.addAll(uris.map { it.toString() }); prefs.edit().putStringSet(key, sources).apply()
                scan(result)
            }
        } catch (e: Exception) { result.error("permission", e.message, null) }
    }
    override fun onDestroy() {
        handler.removeCallbacksAndMessages(null); sink = null
        controllerFuture?.let { MediaController.releaseFuture(it) }; controllerFuture = null; controller = null
        // Do not stop the service: playback belongs to the service, never the Activity.
        worker.shutdown()
        super.onDestroy()
    }
}
