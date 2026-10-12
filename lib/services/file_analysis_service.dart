
import 'dart:io';

import 'package:crypto/crypto.dart';

enum FileRiskLevel {
  informational,
  low,
  medium,
  high,
}

class FileAnalysisResult {
  final String path;
  final String sha256;
  final int sizeBytes;
  final DateTime analyzedAt;
  final String fileName;
  final String fileType;
  final FileRiskLevel riskLevel;
  final List<String> findings;
  final List<String> warnings;

  const FileAnalysisResult({
    required this.path,
    required this.sha256,
    required this.sizeBytes,
    required this.analyzedAt,
    required this.fileName,
    required this.fileType,
    required this.riskLevel,
    required this.findings,
    required this.warnings,
  });

  bool get hasFindings => findings.isNotEmpty;

  String get riskLabel {
    switch (riskLevel) {
      case FileRiskLevel.informational:
        return 'معلوماتي';
      case FileRiskLevel.low:
        return 'منخفض';
      case FileRiskLevel.medium:
        return 'متوسط';
      case FileRiskLevel.high:
        return 'مرتفع';
    }
  }
}

class FileAnalysisService {
  static const int _maxIndicatorScanBytes = 1024 * 1024;

  Future<FileAnalysisResult> analyzeFile(String path) async {
    if (path.trim().isEmpty) {
      throw ArgumentError('مسار الملف مطلوب');
    }

    final file = File(path);
    final exists = await file.exists();

    if (!exists) {
      throw FileSystemException(
        'الملف غير موجود أو لا يمكن الوصول إليه',
        path,
      );
    }

    final sizeBytes = await file.length();
    final digest = await sha256.bind(file.openRead()).first;
    final fileName = file.uri.pathSegments.isNotEmpty
        ? file.uri.pathSegments.last
        : file.path;
    final extension = _getExtension(fileName);
    final findings = <String>[];
    final warnings = <String>[];

    final fileType = _identifyFileType(extension);

    if (extension == 'apk') {
      findings.add(
        'الملف يبدو أنه حزمة Android APK بحسب امتداده.',
      );
      warnings.add(
        'لم يُحلل محتوى APK أو شهادة التوقيع أو الصلاحيات بعد.',
      );
    } else if (_isExecutableExtension(extension)) {
      findings.add(
        'امتداد الملف يشير إلى ملف تنفيذي أو سكربت.',
      );
      warnings.add(
        'الامتداد وحده لا يثبت أن الملف ضار.',
      );
    }

    warnings.add(
      'حُسبت بصمة SHA-256، لكنها لا تكشف البرمجيات الضارة بمفردها.',
    );
    warnings.add(
      'لم تُجرَ مقارنة مع قاعدة بيانات للبرمجيات الضارة.',
    );

    if (sizeBytes == 0) {
      findings.add('الملف فارغ.');
    }

    if (sizeBytes > _maxIndicatorScanBytes) {
      warnings.add(
        'لم يُنفذ تحليل محتوى متقدم؛ حجم الملف يتجاوز '
        'الحد الأولي البالغ 1 ميغابايت.',
      );
    }

    final riskLevel = _calculateRiskLevel(
      extension: extension,
      sizeBytes: sizeBytes,
      findings: findings,
    );

    return FileAnalysisResult(
      path: file.path,
      sha256: digest.toString(),
      sizeBytes: sizeBytes,
      analyzedAt: DateTime.now(),
      fileName: fileName,
      fileType: fileType,
      riskLevel: riskLevel,
      findings: List.unmodifiable(findings),
      warnings: List.unmodifiable(warnings),
    );
  }

  String _getExtension(String fileName) {
    final dotIndex = fileName.lastIndexOf('.');

    if (dotIndex <= 0 || dotIndex == fileName.length - 1) {
      return '';
    }

    return fileName.substring(dotIndex + 1).toLowerCase();
  }

  String _identifyFileType(String extension) {
    switch (extension) {
      case 'apk':
        return 'حزمة تطبيق أندرويد';
      case 'exe':
      case 'dll':
      case 'msi':
        return 'ملف تنفيذي أو مكتبة أو مُثبّت';
      case 'bat':
      case 'cmd':
      case 'ps1':
      case 'sh':
        return 'ملف سكربت';
      case 'pdf':
        return 'مستند PDF';
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'webp':
        return 'صورة';
      case 'zip':
      case 'rar':
      case '7z':
      case 'tar':
        return 'ملف أرشيف مضغوط';
      case 'txt':
      case 'md':
      case 'csv':
        return 'ملف نصي';
      case 'json':
        return 'ملف بيانات JSON';
      case 'dex':
        return 'ملف تنفيذي خاص بأندرويد';
      default:
        return extension.isEmpty
            ? 'نوع غير معروف'
            : 'ملف بامتداد .$extension';
    }
  }

  bool _isExecutableExtension(String extension) {
    const executableExtensions = {
      'exe',
      'dll',
      'msi',
      'bat',
      'cmd',
      'ps1',
      'sh',
      'dex',
      'jar',
      'so',
    };

    return executableExtensions.contains(extension);
  }

  FileRiskLevel _calculateRiskLevel({
    required String extension,
    required int sizeBytes,
    required List<String> findings,
  }) {
    if (sizeBytes == 0) {
      return FileRiskLevel.informational;
    }

    if (extension == 'apk' ||
        _isExecutableExtension(extension)) {
      return FileRiskLevel.medium;
    }

    if (findings.isNotEmpty) {
      return FileRiskLevel.low;
    }

    return FileRiskLevel.informational;
  }
}