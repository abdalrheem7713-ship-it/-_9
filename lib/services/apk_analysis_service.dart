import 'package:flutter/services.dart';

class ApkAnalysisResult {
  final String fileName;
  final int sizeBytes;
  final bool zipStructureValid;
  final bool hasAndroidManifest;
  final bool hasDexFiles;
  final bool hasResources;
  final int entriesChecked;
  final List<String> entries;
  final String note;

  const ApkAnalysisResult({
    required this.fileName,
    required this.sizeBytes,
    required this.zipStructureValid,
    required this.hasAndroidManifest,
    required this.hasDexFiles,
    required this.hasResources,
    required this.entriesChecked,
    required this.entries,
    required this.note,
  });

  factory ApkAnalysisResult.fromMap(
    Map<Object?, Object?> map,
  ) {
    return ApkAnalysisResult(
      fileName: map['fileName']?.toString() ?? 'غير معروف',
      sizeBytes: (map['sizeBytes'] as num?)?.toInt() ?? 0,
      zipStructureValid: map['zipStructureValid'] == true,
      hasAndroidManifest: map['hasAndroidManifest'] == true,
      hasDexFiles: map['hasDexFiles'] == true,
      hasResources: map['hasResources'] == true,
      entriesChecked:
          (map['entriesChecked'] as num?)?.toInt() ?? 0,
      entries: (map['entries'] as List<dynamic>? ?? [])
          .map((entry) => entry.toString())
          .toList(),
      note: map['note']?.toString() ?? '',
    );
  }
}

class ApkAnalysisService {
  static const MethodChannel _channel =
      MethodChannel('com.nathr.security/apk');

  Future<ApkAnalysisResult> analyze(String path) async {
    final normalizedPath = path.trim();

    if (normalizedPath.isEmpty) {
      throw ArgumentError('مسار ملف APK مطلوب.');
    }

    if (!normalizedPath.toLowerCase().endsWith('.apk')) {
      throw ArgumentError('يرجى اختيار ملف بامتداد APK.');
    }

    final result = await _channel.invokeMapMethod<dynamic, dynamic>(
      'analyzeApk',
      <String, dynamic>{'path': normalizedPath},
    );

    if (result == null) {
      throw StateError('لم يُرجع محلل APK أي نتيجة.');
    }

    return ApkAnalysisResult.fromMap(result);
  }
}