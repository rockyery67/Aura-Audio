package audio.aura.aura_audio

import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Handler
import android.os.Looper
import android.util.AtomicFile
import java.io.File
import android.net.Uri
import androidx.media3.common.*
import androidx.media3.common.util.UnstableApi
import androidx.media3.exoplayer.*
import androidx.media3.exoplayer.audio.*
import androidx.media3.session.*
import org.json.JSONArray
import org.json.JSONObject

@UnstableApi
class PlaybackService : MediaSessionService() {
    companion object { var instance: PlaybackService? = null; private set }
    lateinit var player: ExoPlayer
        private set
    val processor = TenBandProcessor()
    private var session: MediaSession? = null
    private val handler = Handler(Looper.getMainLooper())
    private var sleepTask: Runnable? = null
    var sleepAt: Long = 0; private set
    private val checkpoint = object : Runnable {
        override fun run() { persist(); handler.postDelayed(this, 5000) }
    }
    override fun onCreate() {
        super.onCreate()
        instance = this
        val renderers = object : DefaultRenderersFactory(this) {
            override fun buildAudioSink(context: Context, enableFloatOutput: Boolean, enableAudioOutputPlaybackParams: Boolean): AudioSink =
                DefaultAudioSink.Builder(context).setEnableFloatOutput(false)
                    .setAudioProcessors(arrayOf(processor)).build()
        }
        player = ExoPlayer.Builder(this, renderers).build().apply {
            setAudioAttributes(AudioAttributes.Builder().setUsage(C.USAGE_MEDIA).setContentType(C.AUDIO_CONTENT_TYPE_MUSIC).build(), true)
            setHandleAudioBecomingNoisy(true)
            setWakeMode(C.WAKE_MODE_LOCAL)
        }
        val pending = PendingIntent.getActivity(this, 0, Intent(this, MainActivity::class.java), PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        session = MediaSession.Builder(this, player).setSessionActivity(pending).build()
        restore()
        player.addListener(object : Player.Listener {
            override fun onEvents(player: Player, events: Player.Events) { persist() }
            override fun onIsPlayingChanged(isPlaying: Boolean) { if (isPlaying) recordHistory() }
            override fun onMediaItemTransition(item: MediaItem?, reason: Int) { if (player.isPlaying) recordHistory() }
        })
        handler.post(checkpoint)
    }
    override fun onGetSession(controllerInfo: MediaSession.ControllerInfo) = session
    private fun recordHistory() {
        val id = player.currentMediaItem?.mediaId ?: return
        val prefs = getSharedPreferences("engine", 0)
        val previous = try { JSONArray(prefs.getString("history", "[]")) } catch (_: Exception) { JSONArray() }
        val ids = mutableListOf(id)
        for (i in 0 until previous.length()) { val old = previous.optString(i); if (old != id && old.isNotEmpty() && ids.size < 200) ids.add(old) }
        prefs.edit().putString("history", JSONArray(ids).toString()).apply()
    }
    fun setSleep(minutes: Int) {
        sleepTask?.let(handler::removeCallbacks)
        sleepAt = if (minutes > 0) System.currentTimeMillis() + minutes * 60000L else 0
        sleepTask = if (minutes > 0) Runnable { player.pause(); sleepAt = 0; persist() } else null
        sleepTask?.let { handler.postDelayed(it, minutes * 60000L) }
    }
    private fun persist() {
        val queue = JSONArray()
        for (i in 0 until player.mediaItemCount) {
            val item = player.getMediaItemAt(i)
            queue.put(JSONObject().put("id", item.mediaId).put("uri", item.localConfiguration?.uri.toString())
                .put("title", item.mediaMetadata.title).put("artist", item.mediaMetadata.artist)
                .put("album", item.mediaMetadata.albumTitle).put("artwork", item.mediaMetadata.artworkUri?.toString() ?: ""))
        }
        getSharedPreferences("engine", 0).edit().putString("queue", queue.toString())
            .putInt("index", player.currentMediaItemIndex.coerceAtLeast(0)).putLong("position", player.currentPosition.coerceAtLeast(0))
            .putBoolean("shuffle", player.shuffleModeEnabled).putInt("repeat", player.repeatMode)
            .putFloat("speed", player.playbackParameters.speed).apply()
    }
    private fun restore() {
        val prefs = getSharedPreferences("engine", 0)
        try {
            val json = JSONArray(prefs.getString("queue", "[]"))
            val library = try { JSONObject(String(AtomicFile(File(filesDir, "state.json")).readFully())).optJSONArray("tracks") } catch (_: Exception) { null }
            val latest = mutableMapOf<String, JSONObject>()
            if (library != null) for (i in 0 until library.length()) { val track = library.getJSONObject(i); latest[track.getString("id")] = track }
            val items = (0 until json.length()).map { val old = json.getJSONObject(it); itemFromJson(latest[old.getString("id")] ?: old) }
            if (items.isNotEmpty()) {
                player.setMediaItems(items, prefs.getInt("index", 0).coerceIn(0, items.lastIndex), prefs.getLong("position", 0))
                player.prepare()
            }
            player.shuffleModeEnabled = prefs.getBoolean("shuffle", false)
            player.repeatMode = prefs.getInt("repeat", 0)
            player.setPlaybackSpeed(prefs.getFloat("speed", 1f))
            val eq = JSONObject(prefs.getString("eq", "{}")!!)
            val gains = eq.optJSONArray("gains")
            EqState.config = EqConfig(eq.optBoolean("enabled", true), DoubleArray(10) { gains?.optDouble(it, 0.0) ?: 0.0 }, eq.optDouble("preamp", 0.0))
        } catch (_: Exception) { player.clearMediaItems() }
    }
    override fun onDestroy() {
        persist(); handler.removeCallbacksAndMessages(null)
        session?.release(); player.release(); session = null; instance = null
        super.onDestroy()
    }
}

fun itemFromJson(json: JSONObject): MediaItem {
    val uri = Uri.parse(json.getString("uri"))
    require(uri.scheme == "content" || uri.scheme == "file") { "Only local audio is supported" }
    val metadata = MediaMetadata.Builder().setTitle(json.optString("title", "Unknown track"))
        .setArtist(json.optString("artist", "Unknown artist")).setAlbumTitle(json.optString("album", "Unknown album"))
    json.optString("artwork").takeIf { it.isNotBlank() }?.let { metadata.setArtworkUri(if (it.startsWith("/")) Uri.fromFile(File(it)) else Uri.parse(it)) }
    return MediaItem.Builder().setMediaId(json.getString("id")).setUri(uri).setMediaMetadata(metadata.build()).build()
}
