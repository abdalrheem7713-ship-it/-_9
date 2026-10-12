import 'package:flutter/material.dart';

import '../database/local_database.dart';
import '../models/vulnerability.dart';

class VulnerabilitiesPage extends StatefulWidget {
  const VulnerabilitiesPage({super.key});

  @override
  State<VulnerabilitiesPage> createState() =>
      _VulnerabilitiesPageState();
}

class _VulnerabilitiesPageState extends State<VulnerabilitiesPage> {
  static const Color bg = Color(0xFF0B1118);
  static const Color panel = Color(0xFF17212B);
  static const Color accent = Color(0xFF21D6A1);
  static const Color muted = Color(0xFF8D9AAA);

  List<Vulnerability> _items = [];
  bool _loading = true;
  bool _busy = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems({
    bool showMessage = false,
  }) async {
    try {
      final db = await LocalDatabase.instance.database;

      final rows = await db.query(
        'vulnerabilities',
        orderBy: 'id DESC',
      );

      final items = rows
          .map((row) => Vulnerability.fromMap(row))
          .toList();

      if (!mounted) return;

      setState(() {
        _items = items;
        _loading = false;
        _loadError = null;
      });

      if (showMessage) {
        _message('تم تحديث السجلات الأمنية.');
      }
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _loadError =
            'تعذر تحميل السجلات الأمنية من قاعدة البيانات.';
      });

      if (showMessage) {
        _message('تعذر تحديث السجلات الأمنية.');
      }
    }
  }

  void _message(String text) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(text),
        ),
      );
  }

  Future<void> _addItem() async {
    if (_busy) return;

    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    String severity = 'medium';
    String title = '';
    String description = '';
    bool? result;

    try {
      result = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                backgroundColor: panel,
                title: const Text(
                  'إضافة ملاحظة أمنية',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                content: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: titleController,
                          autofocus: true,
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            color: Colors.white,
                          ),
                          decoration: _inputDecoration(
                            'العنوان',
                          ),
                          validator: (value) {
                            if (value == null ||
                                value.trim().isEmpty) {
                              return 'يرجى إدخال العنوان';
                            }

                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: descriptionController,
                          textAlign: TextAlign.right,
                          maxLines: 4,
                          style: const TextStyle(
                            color: Colors.white,
                          ),
                          decoration: _inputDecoration(
                            'الوصف والأدلة (اختياري)',
                          ).copyWith(
                            alignLabelWithHint: true,
                          ),
                        ),
                        const SizedBox(height: 14),
                        DropdownButtonFormField<String>(
                          value: severity,
                          dropdownColor: panel,
                          style: const TextStyle(
                            color: Colors.white,
                          ),
                          decoration: _inputDecoration(
                            'درجة الخطورة',
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'critical',
                              child: Text('حرجة'),
                            ),
                            DropdownMenuItem(
                              value: 'high',
                              child: Text('عالية'),
                            ),
                            DropdownMenuItem(
                              value: 'medium',
                              child: Text('متوسطة'),
                            ),
                            DropdownMenuItem(
                              value: 'low',
                              child: Text('منخفضة'),
                            ),
                            DropdownMenuItem(
                              value: 'info',
                              child: Text('معلوماتية'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setDialogState(() {
                                severity = value;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(dialogContext, false);
                    },
                    child: const Text('إلغاء'),
                  ),
                  FilledButton.icon(
                    onPressed: () {
                      if (formKey.currentState?.validate() ??
                          false) {
                        Navigator.pop(dialogContext, true);
                      }
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: bg,
                    ),
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('حفظ'),
                  ),
                ],
              );
            },
          );
        },
      );

      // قراءة النصوص قبل التخلص من وحدات التحكم.
      title = titleController.text.trim();
      description = descriptionController.text.trim();
    } finally {
      titleController.dispose();
      descriptionController.dispose();
    }

    if (result != true || !mounted) return;

    setState(() => _busy = true);

    try {
      final item = Vulnerability(
        title: title,
        description: description,
        severity: severity,
        status: 'open',
        createdAt: DateTime.now(),
      );

      final db = await LocalDatabase.instance.database;

      final data = item.toMap()..remove('id');

      await db.insert(
        'vulnerabilities',
        data,
      );

      await LocalDatabase.instance.addLog(
        category: 'vulnerability_created',
        message: 'تمت إضافة سجل أمني: ${item.title}',
      );

      if (!mounted) return;

      await _loadItems();

      if (!mounted) return;

      _message(
        _loadError == null
            ? 'تم حفظ السجل الأمني.'
            : 'تم الحفظ، لكن تعذر تحديث القائمة.',
      );
    } catch (_) {
      _message('تعذر حفظ السجل الأمني.');
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _changeStatus(
    Vulnerability item,
    String status,
  ) async {
    if (item.id == null ||
        _busy ||
        item.status == status) {
      return;
    }

    setState(() => _busy = true);

    try {
      final db = await LocalDatabase.instance.database;

      final updated = await db.update(
        'vulnerabilities',
        {'status': status},
        where: 'id = ?',
        whereArgs: [item.id],
      );

      if (updated == 0) {
        throw StateError('لم يتم العثور على السجل.');
      }

      await LocalDatabase.instance.addLog(
        category: 'vulnerability_status_changed',
        message: 'تغيير حالة ${item.title} إلى $status',
      );

      if (!mounted) return;

      await _loadItems();

      if (!mounted) return;

      _message(
        _loadError == null
            ? 'تم تحديث حالة السجل.'
            : 'تم التحديث، لكن تعذر تحديث القائمة.',
      );
    } catch (_) {
      _message('تعذر تحديث حالة السجل.');
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _deleteItem(
    Vulnerability item,
  ) async {
    if (item.id == null || _busy) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: panel,
          title: const Text(
            'حذف السجل',
            style: TextStyle(
              color: Colors.white,
            ),
          ),
          content: Text(
            'هل تريد حذف "${item.title}" من السجلات المحلية؟',
            style: const TextStyle(
              color: muted,
              height: 1.6,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('إلغاء'),
            ),
            TextButton.icon(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.redAccent,
              ),
              icon: const Icon(Icons.delete_outline),
              label: const Text('حذف'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);

    try {
      final db = await LocalDatabase.instance.database;

      final deleted = await db.delete(
        'vulnerabilities',
        where: 'id = ?',
        whereArgs: [item.id],
      );

      if (deleted == 0) {
        throw StateError('لم يتم العثور على السجل.');
      }

      await LocalDatabase.instance.addLog(
        category: 'vulnerability_deleted',
        message: 'تم حذف السجل: ${item.title}',
      );

      if (!mounted) return;

      await _loadItems();

      if (!mounted) return;

      _message(
        _loadError == null
            ? 'تم حذف السجل.'
            : 'تم الحذف، لكن تعذر تحديث القائمة.',
      );
    } catch (_) {
      _message('تعذر حذف السجل الأمني.');
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        color: muted,
      ),
      filled: true,
      fillColor: bg,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: BorderSide.none,
      ),
      errorStyle: const TextStyle(
        color: Colors.redAccent,
      ),
    );
  }

  String _severityLabel(String severity) {
    switch (severity) {
      case 'critical':
        return 'حرجة';
      case 'high':
        return 'عالية';
      case 'medium':
        return 'متوسطة';
      case 'low':
        return 'منخفضة';
      case 'info':
        return 'معلوماتية';
      default:
        return 'غير محددة';
    }
  }

  Color _severityColor(String severity) {
    switch (severity) {
      case 'critical':
        return Colors.purpleAccent;
      case 'high':
        return Colors.redAccent;
      case 'medium':
        return Colors.orangeAccent;
      case 'low':
        return Colors.greenAccent;
      default:
        return Colors.lightBlueAccent;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'resolved':
        return 'تمت المعالجة';
      case 'accepted':
        return 'مقبولة للمراجعة';
      case 'open':
        return 'مفتوحة';
      default:
        return 'غير معروفة';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text('الثغرات الأمنية'),
        backgroundColor: panel,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _busy
                ? null
                : () => _loadItems(showMessage: true),
            icon: const Icon(Icons.refresh),
            tooltip: 'تحديث',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _busy ? null : _addItem,
        backgroundColor: accent,
        foregroundColor: bg,
        icon: const Icon(Icons.add),
        label: const Text('إضافة سجل'),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                color: accent,
              ),
            )
          : _loadError != null
              ? _buildErrorState()
              : _items.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      color: accent,
                      backgroundColor: panel,
                      onRefresh: _loadItems,
                      child: ListView.builder(
                        physics:
                            const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(
                          12,
                          12,
                          12,
                          90,
                        ),
                        itemCount: _items.length,
                        itemBuilder: (context, index) {
                          return _buildItemCard(
                            _items[index],
                          );
                        },
                      ),
                    ),
    );
  }

  Widget _buildItemCard(Vulnerability item) {
    final severityColor = _severityColor(item.severity);

    return Card(
      color: panel,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(
          color: Color(0xFF293443),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(13),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              textDirection: TextDirection.rtl,
              children: [
                Icon(
                  Icons.gpp_maybe_outlined,
                  color: severityColor,
                  size: 25,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    item.title,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _busy
                      ? null
                      : () => _deleteItem(item),
                  tooltip: 'حذف السجل',
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.redAccent,
                  ),
                ),
              ],
            ),
            if (item.description.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                item.description,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  color: Colors.white70,
                  height: 1.6,
                ),
              ),
            ],
            const SizedBox(height: 10),
            Wrap(
              alignment: WrapAlignment.start,
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  label: Text(
                    _severityLabel(item.severity),
                  ),
                  labelStyle: TextStyle(
                    color: severityColor,
                  ),
                  backgroundColor: bg,
                  side: BorderSide(
                    color: severityColor.withOpacity(0.5),
                  ),
                ),
                Chip(
                  label: Text(
                    _statusLabel(item.status),
                  ),
                  labelStyle: const TextStyle(
                    color: Colors.white70,
                  ),
                  backgroundColor: bg,
                  side: const BorderSide(
                    color: Color(0xFF293443),
                  ),
                ),
                PopupMenuButton<String>(
                  enabled: !_busy,
                  tooltip: 'تغيير الحالة',
                  onSelected: (status) {
                    _changeStatus(item, status);
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'open',
                      child: Text('مفتوحة'),
                    ),
                    PopupMenuItem(
                      value: 'resolved',
                      child: Text('تمت المعالجة'),
                    ),
                    PopupMenuItem(
                      value: 'accepted',
                      child: Text('مقبولة للمراجعة'),
                    ),
                  ],
                  child: const Chip(
                    label: Text('تحديث الحالة'),
                    avatar: Icon(
                      Icons.edit_outlined,
                      size: 17,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.verified_user_outlined,
              color: muted,
              size: 48,
            ),
            const SizedBox(height: 14),
            const Text(
              'لا توجد سجلات أمنية بعد',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'يمكنك تسجيل نتائج الفحوصات المصرح بها '
              'والملاحظات الأمنية هنا.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: muted,
                height: 1.7,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _busy ? null : _addItem,
              icon: const Icon(Icons.add),
              label: const Text('إضافة سجل'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.redAccent,
              size: 45,
            ),
            const SizedBox(height: 12),
            const Text(
              'تعذر تحميل السجلات الأمنية',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _loadError ?? 'حدث خطأ غير متوقع.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: muted,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: _busy ? null : _loadItems,
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }
}