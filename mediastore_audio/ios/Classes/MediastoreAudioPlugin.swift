import Flutter
import UIKit
import MediaPlayer

public class MediastoreAudioPlugin: NSObject, FlutterPlugin {
  var pendingResult: FlutterResult?

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "mediastore_audio", binaryMessenger: registrar.messenger())
    let instance = MediastoreAudioPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
      case "checkPermissions":
        let status = MPMediaLibrary.authorizationStatus()
        result(status == .authorized)

      case "requestPermissions":
        MPMediaLibrary.requestAuthorization { status in
          DispatchQueue.main.async {
            result(status == .authorized)
          }
        }

      case "listAudioFiles":
        let query = MPMediaQuery.songs()
        let items = query.items?.map { $0.title ?? "Unknown" } ?? []
        result(items)

      case "getAudios":
        result(getAudios())

      default:
        result(FlutterMethodNotImplemented)
    }
  }

  private fun getAudios(context: Context): List<Map<String, Any?>> {
      val audioList = mutableListOf<Map<String, Any?>>()
      val contentResolver: ContentResolver = context.contentResolver

      val projection = arrayOf(
          MediaStore.Audio.Media._ID,
          MediaStore.Audio.Media.TITLE,
          MediaStore.Audio.Media.ARTIST,
          MediaStore.Audio.Media.ALBUM,
          MediaStore.Audio.Media.ALBUM_ID,
          MediaStore.Audio.Media.DURATION
      )

      val selection = "${MediaStore.Audio.Media.IS_MUSIC} != 0"
      val sortOrder = "${MediaStore.Audio.Media.TITLE} ASC"

      contentResolver.query(
          MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,
          projection,
          selection,
          null,
          sortOrder
      )?.use { cursor ->
          val idColumn = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media._ID)
          val titleColumn = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.TITLE)
          val artistColumn = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.ARTIST)
          val albumColumn = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.ALBUM)
          val albumIdColumn = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.ALBUM_ID)
          val durationColumn = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.DURATION)

          while (cursor.moveToNext()) {
              val id = cursor.getLong(idColumn)
              val title = cursor.getString(titleColumn)
              val artist = cursor.getString(artistColumn)
              val album = cursor.getString(albumColumn)
              val albumId = cursor.getLong(albumIdColumn)
              val duration = cursor.getLong(durationColumn)

              // Content URI for playback
              val contentUri = ContentUris.withAppendedId(
                  MediaStore.Audio.Media.EXTERNAL_CONTENT_URI, id
              )

              // --- Get Album Art from MediaStore.Audio.Albums ---
              val albumArt: String? = getAlbumArt(contentResolver, albumId)

              val audio = mapOf(
                  "id" to id,
                  "title" to title,
                  "artist" to artist,
                  "album" to album,
                  "duration" to duration,
                  "contentUri" to contentUri.toString(),
                  "albumArt" to albumArt // Could be a file path or null
              )
              audioList.add(audio)
          }
      }

      return audioList
  }

  // Helper function to fetch album art path
  private fun getAlbumArt(contentResolver: ContentResolver, albumId: Long): String? {
      val projection = arrayOf(MediaStore.Audio.Albums.ALBUM_ART)
      val uri = ContentUris.withAppendedId(MediaStore.Audio.Albums.EXTERNAL_CONTENT_URI, albumId)

      contentResolver.query(uri, projection, null, null, null)?.use { cursor ->
          val albumArtColumn = cursor.getColumnIndexOrThrow(MediaStore.Audio.Albums.ALBUM_ART)
          if (cursor.moveToFirst()) {
              return cursor.getString(albumArtColumn)
          }
      }
      return null
  }

}
