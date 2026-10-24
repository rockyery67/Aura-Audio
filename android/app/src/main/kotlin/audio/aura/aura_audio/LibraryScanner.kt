package audio.aura.aura_audio

import android.content.ContentUris
import android.content.Context
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.media.MediaMetadataRetriever
import android.net.Uri
import android.os.Build
import android.provider.MediaStore
import androidx.documentfile.provider.DocumentFile
import java.io.File
import java.security.MessageDigest

/** Runs only on the scanner's single worker. Never touches Flutter or the audio thread. */
class LibraryScanner(private val context: Context, private val progress: (Int, String) -> Unit) {
    private val resolver = context.contentResolver
    private val prefs = context.getSharedPreferences("sources", 0)
    private val extensions = setOf("mp3", "m4a", "aac", "flac", "wav", "ogg", "opus", "3gp", "amr")
    private val tracks = linkedMapOf<String, Map<String, Any>>()
    private var skipped = 0
    fun scan(): Map<String, Any> {
        val permission = if (Build.VERSION.SDK_INT >= 33) "android.permission.READ_MEDIA_AUDIO" else "android.permission.READ_EXTERNAL_STORAGE"
        if (context.checkSelfPermission(permission) == PackageManager.PERMISSION_GRANTED) scanMedia()
        prefs.getStringSet("trees", emptySet())!!.forEach { raw ->
            try { DocumentFile.fromTreeUri(context, Uri.parse(raw))?.let { scanTree(it, it.name ?: "Music") } } catch (_: Exception) { skipped++ }
        }
        prefs.getStringSet("files", emptySet())!!.forEach { raw ->
            try { val uri = Uri.parse(raw); val doc = DocumentFile.fromSingleUri(context, uri); add(uri, doc?.name ?: "Audio", "Imported files", doc?.length() ?: 0) } catch (_: Exception) { skipped++ }
        }
        return mapOf("tracks" to tracks.values.toList(), "skipped" to skipped)
    }
    private fun scanMedia() {
        val columns = arrayOf(MediaStore.Audio.Media._ID, MediaStore.Audio.Media.DISPLAY_NAME, MediaStore.Audio.Media.SIZE,
            if (Build.VERSION.SDK_INT >= 29) MediaStore.Audio.Media.RELATIVE_PATH else MediaStore.Audio.Media.DATA)
        try {
            resolver.query(MediaStore.Audio.Media.EXTERNAL_CONTENT_URI, columns, null, null, null)?.use { cursor ->
                while (cursor.moveToNext()) {
                    val uri = ContentUris.withAppendedId(MediaStore.Audio.Media.EXTERNAL_CONTENT_URI, cursor.getLong(0))
                    add(uri, cursor.getString(1) ?: "Audio", cursor.getString(3)?.trimEnd('/') ?: "Device music", cursor.getLong(2))
                }
            }
        } catch (_: SecurityException) { skipped++ }
    }
    private fun scanTree(directory: DocumentFile, path: String) {
        val children = directory.listFiles()
        for (doc in children) {
            if (doc.isDirectory) { scanTree(doc, "$path/${doc.name}"); continue }
            val name = doc.name ?: continue
            if (name.substringAfterLast('.', "").lowercase() !in extensions) continue
            val base = name.substringBeforeLast('.')
            val lyric = children.firstOrNull { it.name.equals("$base.lrc", true) || it.name.equals("$base.txt", true) }
            val lyrics = try { lyric?.let { resolver.openInputStream(it.uri)?.bufferedReader()?.use { r -> r.readText().take(200000) } } ?: "" } catch (_: Exception) { "" }
            add(doc.uri, name, path, doc.length(), lyrics)
        }
    }
    private fun add(uri: Uri, name: String, folder: String, size: Long, lyrics: String = "") {
        if (name.substringAfterLast('.', "").lowercase() !in extensions) return
        progress(tracks.size, name)
        val retriever = MediaMetadataRetriever()
        try {
            retriever.setDataSource(context, uri)
            fun meta(key: Int, fallback: String) = retriever.extractMetadata(key)?.takeIf { it.isNotBlank() && it != "<unknown>" } ?: fallback
            val title = meta(MediaMetadataRetriever.METADATA_KEY_TITLE, name.substringBeforeLast('.'))
            val artist = meta(MediaMetadataRetriever.METADATA_KEY_ARTIST, "Unknown artist")
            val album = meta(MediaMetadataRetriever.METADATA_KEY_ALBUM, "Unknown album")
            val duration = meta(MediaMetadataRetriever.METADATA_KEY_DURATION, "0").toLongOrNull() ?: 0
            if (duration <= 0) { skipped++; return }
            // Deduplicate aliases of the same audio through MediaStore and SAF.
            val fingerprint = "$title|$artist|$album|$duration|$size"
            val id = MessageDigest.getInstance("SHA-256").digest(fingerprint.toByteArray()).joinToString("") { "%02x".format(it) }
            if (tracks.containsKey(id)) {
                // Prefer a durable SAF reference over a whole-library MediaStore grant.
                val old = tracks[id]!!
                if (uri.authority != "media") tracks[id] = old + mapOf("uri" to uri.toString(), "folder" to folder, "lyrics" to (lyrics.ifBlank { old["lyrics"] as? String ?: "" }))
                return
            }
            var artwork = ""
            var color = 0xffa078ff.toInt()
            val bytes = retriever.embeddedPicture
            if (bytes != null && bytes.size <= 16 * 1024 * 1024) {
                val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
                BitmapFactory.decodeByteArray(bytes, 0, bytes.size, bounds)
                var sample = 1
                while (maxOf(bounds.outWidth, bounds.outHeight) / sample > 512) sample *= 2
                BitmapFactory.decodeByteArray(bytes, 0, bytes.size, BitmapFactory.Options().apply { inSampleSize = sample })?.let { bitmap ->
                    val cache = File(context.filesDir, "art").apply { mkdirs() }
                    val file = File(cache, "$id.jpg")
                    file.outputStream().use { bitmap.compress(Bitmap.CompressFormat.JPEG, 86, it) }
                    artwork = file.absolutePath
                    val small = Bitmap.createScaledBitmap(bitmap, 1, 1, true)
                    color = small.getPixel(0, 0); small.recycle(); bitmap.recycle()
                }
            }
            tracks[id] = mapOf("id" to id, "uri" to uri.toString(), "title" to title, "artist" to artist,
                "album" to album, "duration" to duration, "track" to (meta(MediaMetadataRetriever.METADATA_KEY_CD_TRACK_NUMBER, "0").substringBefore('/').toIntOrNull() ?: 0),
                "folder" to folder, "size" to size, "artwork" to artwork, "color" to color.toLong(), "lyrics" to lyrics,
                "format" to name.substringAfterLast('.').uppercase(), "missing" to false, "added" to System.currentTimeMillis())
        } catch (_: Exception) { skipped++ } finally { retriever.release() }
    }
}
