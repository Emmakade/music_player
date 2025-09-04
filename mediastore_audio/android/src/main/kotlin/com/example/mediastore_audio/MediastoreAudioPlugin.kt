package com.example.mediastore_audio

import android.Manifest
import android.app.Activity
import android.content.ContentResolver
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.provider.MediaStore
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry
import android.net.Uri

class MediastoreAudioPlugin : 
    FlutterPlugin, 
    MethodChannel.MethodCallHandler, 
    ActivityAware, 
    PluginRegistry.RequestPermissionsResultListener {

    private lateinit var channel: MethodChannel
    private var context: Context? = null
    private var activity: Activity? = null
    private var pendingResult: MethodChannel.Result? = null
    private val PERMISSION_REQ_CODE = 1001

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "mediastore_audio")
        channel.setMethodCallHandler(this)
        context = binding.applicationContext
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        context = null
    }

    // --- ActivityAware ---
    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        binding.addRequestPermissionsResultListener(this)
    }
    override fun onDetachedFromActivity() { activity = null }
    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) { onAttachedToActivity(binding) }
    override fun onDetachedFromActivityForConfigChanges() { onDetachedFromActivity() }

    // --- Method calls from Dart ---
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "checkPermissions" -> {
                val ctx = activity ?: context
                if (ctx == null) {
                    result.error("NO_CONTEXT", "No valid context available", null)
                    return
                }
                val perm = getStoragePermission()
                val granted = ContextCompat.checkSelfPermission(ctx, perm) == PackageManager.PERMISSION_GRANTED
                result.success(granted)
            }

            "requestPermissions" -> {
                val act = activity
                if (act == null) {
                    result.error("NO_ACTIVITY", "No activity attached", null)
                    return
                }
                if (pendingResult != null) {
                    result.error("PENDING", "Permission request already in progress", null)
                    return
                }
                pendingResult = result
                ActivityCompat.requestPermissions(
                    act,
                    arrayOf(getStoragePermission()),
                    PERMISSION_REQ_CODE
                )
            }

            "listAudioFiles" -> {
                result.success(listAudioFiles())
            }

            "getAudios" -> {
                result.success(getAudios())
            }

            else -> result.notImplemented()
        }
    }

    // --- Handle permission callback ---
    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray): Boolean {
        if (requestCode == PERMISSION_REQ_CODE) {
            val granted = grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED
            pendingResult?.success(granted)
            pendingResult = null
            return true
        }
        return false
    }

    // --- Helpers ---
    private fun getStoragePermission(): String {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            Manifest.permission.READ_MEDIA_AUDIO
        } else {
            Manifest.permission.READ_EXTERNAL_STORAGE
        }
    }

    private fun listAudioFiles(): List<String> {
        val resolver: ContentResolver = context?.contentResolver ?: return emptyList()
        val fileList = mutableListOf<String>()

        val projection = arrayOf(MediaStore.Audio.Media.DATA)

        val cursor = resolver.query(
            MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,
            projection, null, null, null
        )

        cursor?.use {
            val dataCol = it.getColumnIndexOrThrow(MediaStore.Audio.Media.DATA)
            while (it.moveToNext()) {
                fileList.add(it.getString(dataCol))
            }
        }
        return fileList
    }

    private fun getAudios(): List<Map<String, Any?>> {
        val audioList = mutableListOf<Map<String, Any?>>()
        val contentResolver: ContentResolver = context?.contentResolver ?: return emptyList()


        val projection = arrayOf(
            MediaStore.Audio.Media._ID,
            MediaStore.Audio.Media.TITLE,
            MediaStore.Audio.Media.ARTIST,
            MediaStore.Audio.Media.ALBUM,
            MediaStore.Audio.Media.DURATION,
            MediaStore.Audio.Media.ALBUM_ID
        )

        val uri = MediaStore.Audio.Media.EXTERNAL_CONTENT_URI
        val sortOrder = "${MediaStore.Audio.Media.DATE_ADDED} DESC"

        contentResolver.query(uri, projection, null, null, sortOrder)?.use { cursor ->
            val idCol = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media._ID)
            val titleCol = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.TITLE)
            val artistCol = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.ARTIST)
            val albumCol = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.ALBUM)
            val durationCol = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.DURATION)
            val albumIdCol = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.ALBUM_ID)

            while (cursor.moveToNext()) {
                val id = cursor.getLong(idCol)
                val title = cursor.getString(titleCol)
                val artist = cursor.getString(artistCol)
                val album = cursor.getString(albumCol)
                val duration = cursor.getLong(durationCol)
                val albumId = cursor.getLong(albumIdCol)

                // build audio content URI
                val contentUri: Uri = Uri.withAppendedPath(
                    MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,
                    id.toString()
                )

                // build album art URI
                val albumArtUri: Uri = Uri.parse("content://media/external/audio/albumart")
                val albumArt: String = Uri.withAppendedPath(albumArtUri, albumId.toString()).toString()

                audioList.add(
                    mapOf(
                        "id" to id,
                        "title" to title,
                        "artist" to artist,
                        "album" to album,
                        "duration" to duration,
                        "uri" to contentUri.toString(),   // playable content URI
                        "albumArt" to albumArt            // album art content URI (may not always exist)
                    )
                )
            }
        }
        return audioList
    }
}