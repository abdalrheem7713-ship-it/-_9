import 'dart:io';

import 'package:crypto/crypto.dart';

enum FileRiskLevel {
  low,
  medium,
  high,
  unknown,
}

class AdvancedFileAnalysisResult {
  final String path;
  final String fileName;
  final String detectedType;
  final String sha256;
  final int sizeBytes;
  final DateTime analyzedAt;
  final List<String> findings;
  final FileRiskLevel riskLevel;

  const AdvancedFileAnalysisResult({
    required this.path,
    required this.fileName,
    required this.detectedType,
    required this.sha256,
    required this.sizeBytes,
    required this.analyzedAt,
    required this.findings,
    required this.riskLevel,
  });
}

class AdvancedFileAnalysisService {
  Future<AdvancedFileAnalysisResult> analyze(String path) async {
    if (path.trim().isEmpty) {
      throw ArgumentError('مسار الملف مطلوب.');
    }

    final file = File(path);

    if (!await file.exists()) {
      throw FileSystemException(
        'الملف غير موجود أو لا يمكن الوصول إليه.',
        path,
      );
    }

    final stat = await file.stat();

    if (stat.type != FileSystemEntityType.file) {
      throw FileSystemException(
        'المسار لا يشير إلى ملف عادي.',
        path,
      );
    }

    final size = stat.size;
    final findings = <String>[];

    if (size == 0) {
      findings.add('الملف فارغ ولا يحتوي على بيانات.');
    }

    final header = await _readHeader(file);
    final detectedType = _detectType(header, path);

    final extension = _extensionOf(path);
    final expectedType = _typeFromExtension(extension);

    if (expectedType != null &&
        detectedType != 'غير معروف' &&
        expectedType != detectedType) {
      findings.add(
        'امتداد الملف لا يتوافق مع نوع المحتوى المكتشف.',
      );
    }

    if (extension == 'apk' && detectedType != 'ZIP/APK') {
      findings.add(
        'امتداد APK موجود، لكن توقيع ZIP المعتاد لم يُكتشف. '
        'قد يكون الملف تالفًا أو ليس APK صالحًا.',
      );
    }

    if (detectedType == 'ZIP/APK') {
      findings.add(
        'تم اكتشاف بنية ZIP. يلزم تحليل محتويات الحزمة '
        'للتحقق من كونها APK صالحًا.',
      );
    }

    if (size > 100 * 1024 * 1024) {
      findings.add(
        'الملف كبير نسبيًا؛ جرى حساب البصمة باستخدام القراءة المتدفقة.',
      );
    }

    final digest = await sha256.bind(file.openRead()).first;

    if (findings.isEmpty) {
      findings.add(
        'لم تظهر مؤشرات أولية على عدم تطابق نوع الملف. '
        'هذا لا يثبت أن الملف آمن.',
      );
    }

    return AdvancedFileAnalysisResult(
      path: file.path,
      fileName: _fileName(path),
      detectedType: detectedType,
      sha256: digest.toString(),
      sizeBytes: size,
      analyzedAt: DateTime.now(),
      findings: List.unmodifiable(findings),
      riskLevel: _assessRisk(
        findings: findings,
        detectedType: detectedType,
        size: size,
      ),
    );
  }

  Future<List<int>> _readHeader(File file) async {
    final handle = await file.open();

    try {
      return await handle.read(16);
    } finally {
      await handle.close();
    }
  }

  String _detectType(List<int> bytes, String path) {
    if (_startsWith(bytes, [0x50, 0x4B, 0x03, 0x04]) ||
        _startsWith(bytes, [0x50, 0x4B, 0x05, 0x06]) ||
        _startsWith(bytes, [0x50, 0x4B, 0x07, 0x08])) {
      return 'ZIP/APK';
    }

    if (_startsWith(bytes, [0x25, 0x50, 0x44, 0x46])) {
      return 'PDF';
    }

    if (_startsWith(bytes, [0x89, 0x50, 0x4E, 0x47])) {
      return 'PNG';
    }

    if (_startsWith(bytes, [0xFF, 0xD8, 0xFF])) {
      return 'JPEG';
    }

    if (_startsWith(bytes, [0x7F, 0x45, 0x4C, 0x46])) {
      return 'ELF';
    }

    if (_startsWith(bytes, [0x4D, 0x5A])) {
      return 'PE/EXE';
    }

    if (_startsWith(bytes, [0x64, 0x65, 0x78, 0x0A])) {
      return 'DEX';
    }

    if (_startsWith(bytes, [0x52, 0x61, 0x72, 0x21])) {
      return 'RAR';
    }

    if (_startsWith(bytes, [0x37, 0x7A, 0xBC, 0xAF, 0x27, 0x1C])) {
      return '7Z';
    }

    if (_startsWith(bytes, [0x1F, 0x8B])) {
      return 'GZIP';
    }

    if (_looksLikeText(bytes)) {
      final extension = _extensionOf(path);

      if (extension == 'xml') return 'XML/نص';
      if (extension == 'json') return 'JSON/نص';
      if (extension == 'txt') return 'نص';

      return 'نص محتمل';
    }

    return 'غير معروف';
  }

  bool _startsWith(List<int> bytes, List<int> signature) {
    if (bytes.length < signature.length) return false;

    for (var i = 0; i < signature.length; i++) {
      if (bytes[i] != signature[i]) return false;
    }

    return true;
  }

  bool _looksLikeText(List<int> bytes) {
    if (bytes.isEmpty) return false;

    var printable = 0;

    for (final byte in bytes) {
      if (byte == 9 || byte == 10 || byte == 13 ||
          (byte >= 32 && byte <= 126) ||
          byte >= 128) {
        printable++;
      }
    }

    return printable / bytes.length >= 0.85;
  }

  String _extensionOf(String path) {
    final name = _fileName(path);
    final dot = name.lastIndexOf('.');

    if (dot < 0 || dot == name.length - 1) return '';

    return name.substring(dot + 1).toLowerCase();
  }

  String _fileName(String path) {
    return path.split(RegExp(r'[/\\]')).last;
  }

  String? _typeFromExtension(String extension) {
    switch (extension) {
      case 'apk':
      case 'zip':
        return 'ZIP/APK';
      case 'pdf':
        return 'PDF';
      case 'png':
        return 'PNG';
      case 'jpg':
      case 'jpeg':
        return 'JPEG';
      case 'exe':
      case 'dll':
        return 'PE/EXE';
      case 'dex':
        return 'DEX';
      case 'rar':
        return 'RAR';
      case '7z':
        return '7Z';
      case 'gz':
      case 'gzip':
        return 'GZIP';
      case 'xml':
      case 'json':
      case 'txt':
        return 'نص';
      default:
        return null;
    }
  }

  FileRiskLevel _assessRisk({
    required List<String> findings,
    required String detectedType,
    required int size,
  }) {
    if (findings.any((item) =>
        item.contains('لا يتوافق') ||
        item.contains('تالفًا'))) {
      return FileRiskLevel.medium;
    }

    if (size == 0 || detectedType == 'غير معروف') {
      return FileRiskLevel.unknown;
    }

    return FileRiskLevel.low;
  }
}