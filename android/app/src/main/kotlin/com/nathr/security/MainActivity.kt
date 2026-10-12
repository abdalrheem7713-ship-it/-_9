package com.nathr.security

import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.content.pm.PackageInfo
import android.content.pm.PackageInfoFlags
import android.os.Build
import android.net.Uri
import android.content.Intent
import android.provider.OpenableColumns
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.zip.ZipFile

class MainActivity : FlutterActivity() {

    private val appsChannel = "com.nathr.security/apps"
    private val deviceChannel = "com.nathr.security/device"
    private val apkChannel = "com.nathr.security/apk"

    override fun configureFlutterEngine(
        flutterEngine: FlutterEngine
    ) {
        super.configureFlutterEngine(flutterEngine)

        val messenger = flutterEngine.dartExecutor.binaryMessenger

        MethodChannel(messenger, appsChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getInstalledApps" -> {
                        try {
                            result.success(getInstalledApps())
                        } catch (e: Exception) {
                            result.error(
                                "APP_SCAN_ERROR",
                                e.message ?: "تعذر جرد التطبيقات",
                                null
                            )
                        }
                    }
                    else -> result.notImplemented()
                }
            }

        MethodChannel(messenger, deviceChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getDeviceCapabilities" ->
                        result.success(getDeviceCapabilities())
                    else -> result.notImplemented()
                }
            }

        MethodChannel(messenger, apkChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "analyzeApk" -> {
                        val path = call.argument<String>("path")

                        if (path.isNullOrBlank()) {
                            result.error(
                                "INVALID_PATH",
                                "مسار ملف APK مطلوب",
                                null
                            )
                        } else {
                            try {
                                result.success(analyzeApk(path))
                            } catch (e: Exception) {
                                result.error(
                                    "APK_ANALYSIS_ERROR",
                                    e.message ?: "تعذر تحليل ملف APK",
                                    null
                                )
                            }
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun getInstalledApps(): List<Map<String, Any>> {
        val pm = packageManager

        val applications =
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                pm.getInstalledApplications(
                    PackageManager.ApplicationInfoFlags.of(0)
                )
            } else {
                @Suppress("DEPRECATION")
                pm.getInstalledApplications(0)
            }

        return applications.map { app ->
            val version = try {
                getPackageInfoCompat(app.packageName).versionName
                    ?: "غير معروف"
            } catch (_: Exception) {
                "غير معروف"
            }

            mapOf(
                "name" to pm.getApplicationLabel(app).toString(),
                "packageName" to app.packageName,
                "version" to version,
                "isSystemApp" to (
                    app.flags and ApplicationInfo.FLAG_SYSTEM != 0
                )
            )
        }.sortedBy {
            it["name"].toString().lowercase()
        }
    }

    private fun getPackageInfoCompat(
        packageName: String
    ): PackageInfo {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            packageManager.getPackageInfo(
                packageName,
                PackageManager.PackageInfoFlags.of(
                    PackageManager.GET_PERMISSIONS.toLong()
                )
            )
        } else {
            @Suppress("DEPRECATION")
            packageManager.getPackageInfo(
                packageName,
                PackageManager.GET_PERMISSIONS
            )
        }
    }

    private fun getDeviceCapabilities(): Map<String, Any> {
        val rootAvailable = detectRootIndicators()

        return mapOf(
            "androidSdk" to Build.VERSION.SDK_INT,
            "rootAvailable" to rootAvailable,
            "appInventoryAvailable" to true,
            "advancedEnvironmentAvailable" to rootAvailable
        )
    }

    private fun detectRootIndicators(): Boolean {
        val suPaths = listOf(
            "/system/bin/su",
            "/system/xbin/su",
            "/sbin/su",
            "/system/sbin/su",
            "/vendor/bin/su",
            "/su/bin/su",
            "/data/adb/magisk"
        )

        return suPaths.any { path ->
            try {
                File(path).exists()
            } catch (_: Exception) {
                false
            }
        }
    }

    private fun analyzeApk(path: String): Map<String, Any?> {
        val file = File(path)

        if (!file.exists() || !file.isFile) {
            throw IllegalArgumentException(
                "الملف غير موجود أو ليس ملفًا عاديًا"
            )
        }

        val zipEntries = mutableListOf<String>()

        ZipFile(file).use { zip ->
            val entries = zip.entries()

            while (entries.hasMoreElements()) {
                val entry = entries.nextElement()

                if (zipEntries.size < 5000) {
                    zipEntries.add(entry.name)
                }
            }
        }

        val hasManifest =
            zipEntries.contains("AndroidManifest.xml")

        val hasDex =
            zipEntries.any {
                it.matches(Regex("classes(\\d*)\\.dex"))
            }

        val hasResources =
            zipEntries.contains("resources.arsc")

        return mapOf(
            "fileName" to file.name,
            "sizeBytes" to file.length(),
            "zipStructureValid" to true,
            "hasAndroidManifest" to hasManifest,
            "hasDexFiles" to hasDex,
            "hasResources" to hasResources,
            "entriesChecked" to zipEntries.size,
            "entries" to zipEntries.take(100),
            "note" to
                "هذا فحص أولي لبنية APK، وليس إثباتًا لسلامته."
        )
    }
}