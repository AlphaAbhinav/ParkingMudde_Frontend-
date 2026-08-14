package com.parkingmudde.app

import android.content.ContentProvider
import android.content.ContentResolver
import android.content.ContentValues
import android.content.Context
import android.content.res.AssetFileDescriptor
import android.database.Cursor
import android.net.Uri
import android.os.Bundle
import android.os.ParcelFileDescriptor
import java.io.File
import java.io.FileNotFoundException

class NotificationSoundProvider : ContentProvider() {
    companion object {
        private const val AUTHORITY_SUFFIX = ".notification_sound"
        private const val SOUND_NAME = "parking_mudde_loop_alert"
        private const val SOUND_ASSET_PATH =
            "flutter_assets/assets/sounds/FullAudioPMAlertsFinalAlertTone.mpeg"
        private const val SOUND_FILE_NAME = "$SOUND_NAME.mpeg"
        private const val LOOP_REPEAT_COUNT = 180
        private const val MIN_LOOP_SOUND_BYTES = 1_000_000L
        private const val MIME_TYPE = "audio/mpeg"

        fun soundUri(context: Context): Uri = Uri.Builder()
            .scheme(ContentResolver.SCHEME_CONTENT)
            .authority("${context.packageName}$AUTHORITY_SUFFIX")
            .appendPath(SOUND_NAME)
            .build()

        fun prepareSoundFile(context: Context): File {
            val soundFile = File(context.noBackupFilesDir, SOUND_FILE_NAME)
            if (soundFile.exists() && soundFile.length() >= MIN_LOOP_SOUND_BYTES) {
                return soundFile
            }

            context.noBackupFilesDir.mkdirs()
            val alertToneBytes = context.assets.open(SOUND_ASSET_PATH).use { input ->
                input.readBytes()
            }
            soundFile.outputStream().buffered().use { output ->
                repeat(LOOP_REPEAT_COUNT) {
                    output.write(alertToneBytes)
                }
            }
            return soundFile
        }
    }

    override fun onCreate(): Boolean = true

    override fun getType(uri: Uri): String? =
        if (isNotificationSoundUri(uri)) MIME_TYPE else null

    override fun openFile(uri: Uri, mode: String): ParcelFileDescriptor {
        if (!mode.startsWith("r")) {
            throw FileNotFoundException("Notification sound is read-only")
        }
        return ParcelFileDescriptor.open(
            getNotificationSoundFile(uri),
            ParcelFileDescriptor.MODE_READ_ONLY,
        )
    }

    override fun openAssetFile(uri: Uri, mode: String): AssetFileDescriptor {
        if (!mode.startsWith("r")) {
            throw FileNotFoundException("Notification sound is read-only")
        }
        val soundFile = getNotificationSoundFile(uri)
        return AssetFileDescriptor(
            ParcelFileDescriptor.open(soundFile, ParcelFileDescriptor.MODE_READ_ONLY),
            0,
            soundFile.length(),
        )
    }

    override fun openTypedAssetFile(
        uri: Uri,
        mimeTypeFilter: String,
        opts: Bundle?,
    ): AssetFileDescriptor {
        if (
            mimeTypeFilter != "*/*" &&
                mimeTypeFilter != MIME_TYPE &&
                !mimeTypeFilter.startsWith("audio/")
        ) {
            throw FileNotFoundException("Unsupported notification sound type")
        }
        return openAssetFile(uri, "r")
    }

    override fun query(
        uri: Uri,
        projection: Array<out String>?,
        selection: String?,
        selectionArgs: Array<out String>?,
        sortOrder: String?,
    ): Cursor? = null

    override fun insert(uri: Uri, values: ContentValues?): Uri? =
        throw UnsupportedOperationException("Notification sound is read-only")

    override fun delete(uri: Uri, selection: String?, selectionArgs: Array<out String>?): Int =
        throw UnsupportedOperationException("Notification sound is read-only")

    override fun update(
        uri: Uri,
        values: ContentValues?,
        selection: String?,
        selectionArgs: Array<out String>?,
    ): Int = throw UnsupportedOperationException("Notification sound is read-only")

    private fun getNotificationSoundFile(uri: Uri): File {
        if (!isNotificationSoundUri(uri)) {
            throw FileNotFoundException(uri.toString())
        }

        val appContext = context?.applicationContext
            ?: throw FileNotFoundException("Notification sound provider is not ready")
        val soundFile = prepareSoundFile(appContext)
        if (!soundFile.exists() || soundFile.length() == 0L) {
            throw FileNotFoundException("Notification sound file is missing")
        }
        return soundFile
    }

    private fun isNotificationSoundUri(uri: Uri): Boolean {
        val expectedAuthority = "${context?.packageName}$AUTHORITY_SUFFIX"
        return uri.scheme == ContentResolver.SCHEME_CONTENT &&
            uri.authority == expectedAuthority &&
            uri.pathSegments.size == 1 &&
            uri.pathSegments.firstOrNull() == SOUND_NAME
    }
}
