
import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../database/local_database.dart';
import '../models/incident.dart';

class RecoveryPage extends StatefulWidget {
  const RecoveryPage({super.key});

  @override
  State<RecoveryPage> createState() => _RecoveryPageState();
}

class _RecoveryPageState extends State<RecoveryPage> {
  static const Color bg = Color(0xFF0B1017);
  static const Color panel = Color(0xFF151E29);
  static const Color accent = Color(0xFF21D6A1);
  static const Color muted = Color(0xFF8D9AAA);
  static const Color orange = Color(0xFFFFBD69);
  static const Color blue = Color(0xFF58A6FF);

  List<Incident> _incidents = [];
  bool _loading = true;
  bool _creatingBackup = false;

  @override
  void initState() {
    super.initState();
    _loadIncidents();
  }

  Future<void> _loadIncidents() async {
    try {
      final incidents =
          await LocalDatabase.instance.getIncidents();

      if (!mounted) return;

      setState(() {
        _incidents = incidents;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() => _loading = false);
      _showMessage('تعذر تحميل القضايا الأمنية');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message)),
      );
  }

  Future<void> _addIncident() async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();

    String selectedPriority = 'normal';

    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                backgroundColor: panel,
                title: const Text(
                  'تسجيل قضية أمنية',
                  textAlign: TextAlign.right,
                  style: TextStyle(color: Colors.white),
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: titleController,
                        autofocus: true,
                        style: const TextStyle(
                          color: Colors.white,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'عنوان القضية',
                          labelStyle: TextStyle(color: muted),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: descriptionController,
                        maxLines: 3,
                        style: const TextStyle(
                          color: Colors.white,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'التفاصيل',
                          labelStyle: TextStyle(color: muted),
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: selectedPriority,
                        dropdownColor: panel,
                        style: const TextStyle(
                          color: Colors.white,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'الأولوية',
                          labelStyle: TextStyle(color: muted),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'low',
                            child: Text('منخفضة'),
                          ),
                          DropdownMenuItem(
                            value: 'normal',
                            child: Text('عادية'),
                          ),
                          DropdownMenuItem(
                            value: 'high',
                            child: Text('مرتفعة'),
                          ),
                          DropdownMenuItem(
                            value: 'critical',
                            child: Text('حرجة'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;

                          setDialogState(() {
                            selectedPriority = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(dialogContext, false);
                    },
                    child: const Text('إلغاء'),
                  ),
                  FilledButton(
                    onPressed: () {
                      Navigator.pop(
                        dialogContext,
                        titleController.text.trim().isNotEmpty,
                      );
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: bg,
                    ),
                    child: const Text('حفظ'),
                  ),
                ],
              );
            },
          );
        },
      );

      final title = titleController.text.trim();
      final description = descriptionController.text.trim();

      if (confirmed != true || title.isEmpty) return;

      await LocalDatabase.instance.insertIncident(
        Incident(
          title: title,
          description: description,
          priority: selectedPriority,
          createdAt: DateTime.now(),
        ),
      );

      await LocalDatabase.instance.addLog(
        category: 'recovery',
        message: 'تم تسجيل القضية: $title',
      );

      await _loadIncidents();
      _showMessage('تم حفظ القضية بنجاح');
    } catch (_) {
      _showMessage('تعذر حفظ القضية');
    } finally {
      titleController.dispose();
      descriptionController.dispose();
    }
  }

  Future<void> _updateStatus(Incident incident) async {
    if (incident.id == null) {
      _showMessage('تعذر تحديث القضية: المعرف غير موجود');
      return;
    }

    final nextStatus =
        incident.status == 'open' ? 'resolved' : 'open';

    try {
      await LocalDatabase.instance.updateIncident(
        Incident(
          id: incident.id,
          title: incident.title,
          description: incident.description,
          status: nextStatus,
          priority: incident.priority,
          createdAt: incident.createdAt,
        ),
      );

      await LocalDatabase.instance.addLog(
        category: 'recovery',
        message:
            'تم تغيير حالة القضية ${incident.title} إلى $nextStatus',
      );

      await _loadIncidents();

      _showMessage(
        nextStatus == 'resolved'
            ? 'تم تحديد القضية كمعالجة'
            : 'تمت إعادة فتح القضية',
      );
    } catch (_) {
      _showMessage('تعذر تحديث القضية');
    }
  }

  Future<void> _deleteIncident(Incident incident) async {
    if (incident.id == null) {
      _showMessage('تعذر حذف القضية: المعرف غير موجود');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: panel,
          title: const Text(
            'حذف القضية؟',
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            'سيتم حذف "${incident.title}" نهائيًا من قاعدة البيانات.',
            style: const TextStyle(color: muted),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text(
                'حذف',
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await LocalDatabase.instance.deleteIncident(incident.id!);

      await LocalDatabase.instance.addLog(
        category: 'recovery',
        message: 'تم حذف القضية: ${incident.title}',
      );

      await _loadIncidents();
      _showMessage('تم حذف القضية');
    } catch (_) {
      _showMessage('تعذر حذف القضية');
    }
  }

  Future<void> _createBackup() async {
    if (_creatingBackup) return;

    setState(() => _creatingBackup = true);

    try {
      final db = await LocalDatabase.instance.database;

      final backup = <String, dynamic>{
        'app': 'NATHR',
        'formatVersion': 1,
        'createdAt': DateTime.now().toIso8601String(),
        'tables': <String, dynamic>{
          'devices': await db.query('devices'),
          'jobs': await db.query('jobs'),
          'vulnerabilities': await db.query('vulnerabilities'),
          'incidents': await db.query('incidents'),
          'logs': await db.query('logs'),
        },
      };

      final bytes = Uint8List.fromList(
        utf8.encode(
          const JsonEncoder.withIndent('  ').convert(backup),
        ),
      );

      final savedPath = await FilePicker.platform.saveFile(
        dialogTitle: 'حفظ نسخة احتياطية من نذر',
        fileName:
            'nathr_backup_${DateTime.now().millisecondsSinceEpoch}.json',
        type: FileType.custom,
        allowedExtensions: ['json'],
        bytes: bytes,
      );

      if (!mounted) return;

      if (savedPath == null) {
        _showMessage('تم إلغاء إنشاء النسخة الاحتياطية');
      } else {
        _showMessage('تم إنشاء ملف النسخة الاحتياطية');
      }
    } catch (_) {
      _showMessage(
        'تعذر إنشاء النسخة الاحتياطية. تحقق من دعم حفظ الملفات على جهازك.',
      );
    } finally {
      if (mounted) {
        setState(() => _creatingBackup = false);
      }
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'open':
        return 'مفتوحة';
      case 'resolved':
        return 'تمت المعالجة';
      case 'closed':
        return 'مغلقة';
      case 'in_progress':
        return 'قيد المعالجة';
      default:
        return status;
    }
  }

  String _priorityLabel(String priority) {
    switch (priority) {
      case 'low':
        return 'منخفضة';
      case 'normal':
        return 'عادية';
      case 'high':
        return 'مرتفعة';
      case 'critical':
        return 'حرجة';
      default:
        return priority;
    }
  }

  Color _priorityColor(String priority) {
    switch (priority) {
      case 'low':
        return blue;
      case 'normal':
        return muted;
      case 'high':
        return orange;
      case 'critical':
        return Colors.redAccent;
      default:
        return muted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final openCount = _incidents
        .where((incident) => incident.status == 'open')
        .length;

    final resolvedCount = _incidents
        .where((incident) => incident.status == 'resolved')
        .length;

    return Container(
      color: bg,
      child: RefreshIndicator(
        onRefresh: _loadIncidents,
        color: accent,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'التدخل والاستعادة',
              textAlign: TextAlign.right,
              style: TextStyle(
                color: Colors.white,
                fontSize: 23,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'توثيق الحوادث ومتابعة المعالجة وحفظ بيانات التطبيق.',
              textAlign: TextAlign.right,
              style: TextStyle(color: muted, height: 1.6),
            ),
            const SizedBox(height: 20),
            _actionCard(
              icon: Icons.fact_check_outlined,
              title: 'إدارة القضايا',
              description:
                  'سجّل الحوادث، وحدد أولويتها، وتابع حالتها.',
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: panel,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Row(
                    textDirection: TextDirection.rtl,
                    children: [
                      Icon(
                        Icons.backup_outlined,
                        color: accent,
                        size: 28,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'النسخ الاحتياطي',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'أنشئ ملف JSON يحتوي على بيانات الأجهزة والمهام '
                    'والثغرات والقضايا والسجلات.',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: muted,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    onPressed:
                        _creatingBackup ? null : _createBackup,
                    icon: _creatingBackup
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: bg,
                            ),
                          )
                        : const Icon(Icons.save_alt),
                    label: Text(
                      _creatingBackup
                          ? 'جارٍ إنشاء النسخة...'
                          : 'إنشاء نسخة احتياطية',
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: bg,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _countCard(
                    'الإجمالي',
                    _incidents.length,
                    accent,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _countCard(
                    'مفتوحة',
                    openCount,
                    orange,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _countCard(
                    'معالجة',
                    resolvedCount,
                    blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'القضايا المسجلة: ${_incidents.length}',
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                FilledButton.icon(
                  onPressed: _addIncident,
                  icon: const Icon(Icons.add),
                  label: const Text('قضية جديدة'),
                  style: FilledButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: bg,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: CircularProgressIndicator(
                    color: accent,
                  ),
                ),
              )
            else if (_incidents.isEmpty)
              _emptyState()
            else
              ..._incidents.map(_incidentCard),
          ],
        ),
      ),
    );
  }

  Widget _countCard(String title, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 14,
        horizontal: 8,
      ),
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            '$count',
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: muted,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _incidentCard(Incident incident) {
    final isOpen = incident.status == 'open';
    final priorityColor = _priorityColor(incident.priority);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: incident.priority == 'critical'
              ? Colors.redAccent.withOpacity(0.5)
              : Colors.transparent,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            textDirection: TextDirection.rtl,
            children: [
              Icon(
                isOpen
                    ? Icons.warning_amber_rounded
                    : Icons.check_circle_outline,
                color: isOpen ? orange : accent,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  incident.title,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 8,
            runSpacing: 8,
            children: [
              _labelChip(
                'الحالة: ${_statusLabel(incident.status)}',
                isOpen ? orange : accent,
              ),
              _labelChip(
                'الأولوية: ${_priorityLabel(incident.priority)}',
                priorityColor,
              ),
            ],
          ),
          if (incident.description.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              incident.description,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: muted,
                height: 1.5,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            'تاريخ التسجيل: ${_formatDate(incident.createdAt)}',
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: muted,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 8,
            children: [
              TextButton(
                onPressed: () => _updateStatus(incident),
                child: Text(
                  isOpen ? 'تحديد كمعالجة' : 'إعادة فتح',
                ),
              ),
              TextButton(
                onPressed: () => _deleteIncident(incident),
                child: const Text(
                  'حذف',
                  style: TextStyle(color: Colors.redAccent),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _labelChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  static Widget _actionCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Icon(icon, color: accent, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: muted,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _emptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.inbox_outlined,
            color: muted,
            size: 42,
          ),
          SizedBox(height: 10),
          Text(
            'لا توجد قضايا مسجلة حتى الآن.',
            textAlign: TextAlign.center,
            style: TextStyle(color: muted),
          ),
        ],
      ),
    );
  }
}