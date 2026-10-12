
import 'package:flutter/foundation.dart';

import '../database/local_database.dart';

class AuditService {
  final LocalDatabase _database = LocalDatabase.instance;

  Future<void> recordCheck({
    required String target,
    required String checkName,
    required bool authorized,
  }) async {
    if (target.trim().isEmpty) {
      throw ArgumentError('يجب تحديد الهدف');
    }

    if (!authorized) {
      throw StateError(
        'يجب تأكيد وجود تصريح قبل تسجيل الفحص',
      );
    }

    final message =
        'الفحص: ${checkName.trim()} | الهدف: ${target.trim()}';

    await _database.addLog(
      category: 'security_audit',
      message: message,
    );

    debugPrint('NATHR audit recorded: $message');
  }

  Future<List<Map<String, Object?>>> getAuditLogs() async {
    final logs = await _database.getLogs();

    return logs.where((log) {
      return log['category'] == 'security_audit';
    }).toList();
  }
}