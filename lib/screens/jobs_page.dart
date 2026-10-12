
import 'package:flutter/material.dart';

import '../database/local_database.dart';
import '../models/job.dart';

class JobsPage extends StatefulWidget {
  const JobsPage({super.key});

  @override
  State<JobsPage> createState() => _JobsPageState();
}

class _JobsPageState extends State<JobsPage> {
  static const Color bg = Color(0xFF0B1017);
  static const Color panel = Color(0xFF151E29);
  static const Color accent = Color(0xFF21D6A1);
  static const Color muted = Color(0xFF8D9AAA);
  static const Color blue = Color(0xFF58A6FF);
  static const Color orange = Color(0xFFFFBD69);

  List<Job> _jobs = [];
  bool _loading = true;
  bool _busy = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadJobs();
  }

  Future<void> _loadJobs({bool showMessage = false}) async {
    try {
      final jobs = await LocalDatabase.instance.getJobs();

      if (!mounted) return;

      setState(() {
        _jobs = jobs;
        _loading = false;
        _loadError = null;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _loadError = 'تعذر تحميل المهام من قاعدة البيانات.';
      });

      if (showMessage) {
        _showMessage('تعذر تحديث قائمة المهام.');
      }
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

  Future<void> _addJob() async {
    if (_busy) return;

    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    bool? confirmed;
    String title = '';
    String description = '';

    try {
      confirmed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return AlertDialog(
            backgroundColor: panel,
            title: const Text(
              'إضافة مهمة',
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
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration('عنوان المهمة'),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'يرجى إدخال عنوان المهمة';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: descriptionController,
                      textAlign: TextAlign.right,
                      maxLines: 3,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration(
                        'وصف المهمة (اختياري)',
                      ),
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
                  if (formKey.currentState?.validate() ?? false) {
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

      if (confirmed == true) {
        title = titleController.text.trim();
        description = descriptionController.text.trim();
      }
    } finally {
      titleController.dispose();
      descriptionController.dispose();
    }

    if (confirmed != true || !mounted) return;

    setState(() {
      _busy = true;
    });

    try {
      final job = Job(
        title: title,
        description: description,
        createdAt: DateTime.now(),
      );

      await LocalDatabase.instance.insertJob(job);

      await LocalDatabase.instance.addLog(
        category: 'job_created',
        message: 'تم إنشاء المهمة: ${job.title}',
      );

      if (!mounted) return;

      await _loadJobs();

      if (!mounted) return;

      _showMessage(
        _loadError == null
            ? 'تمت إضافة المهمة بنجاح.'
            : 'تم الحفظ، لكن تعذر تحديث القائمة.',
      );
    } catch (_) {
      _showMessage('تعذرت إضافة المهمة. تحقق من قاعدة البيانات.');
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  Future<void> _changeStatus(Job job, String status) async {
    if (job.id == null || _busy || job.status == status) return;

    setState(() {
      _busy = true;
    });

    try {
      final db = await LocalDatabase.instance.database;

      final updated = await db.update(
        'jobs',
        {'status': status},
        where: 'id = ?',
        whereArgs: [job.id],
      );

      if (updated == 0) {
        throw StateError('لم يتم العثور على المهمة.');
      }

      await LocalDatabase.instance.addLog(
        category: 'job_status_changed',
        message: 'تغيير حالة المهمة ${job.title} إلى $status',
      );

      if (!mounted) return;

      await _loadJobs();

      if (!mounted) return;

      _showMessage(
        _loadError == null
            ? 'تم تحديث حالة المهمة.'
            : 'تم تحديث الحالة، لكن تعذر تحديث القائمة.',
      );
    } catch (_) {
      _showMessage('تعذر تحديث حالة المهمة.');
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  Future<void> _deleteJob(Job job) async {
    if (job.id == null || _busy) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: panel,
          title: const Text(
            'حذف المهمة',
            textAlign: TextAlign.right,
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            'هل تريد حذف "${job.title}" من السجلات المحلية؟',
            textAlign: TextAlign.right,
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
              icon: const Icon(Icons.delete_outline),
              label: const Text('حذف'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.redAccent,
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _busy = true;
    });

    try {
      final deleted =
          await LocalDatabase.instance.deleteJob(job.id!);

      if (deleted == 0) {
        throw StateError('لم يتم العثور على المهمة.');
      }

      await LocalDatabase.instance.addLog(
        category: 'job_deleted',
        message: 'تم حذف المهمة: ${job.title}',
      );

      if (!mounted) return;

      await _loadJobs();

      if (!mounted) return;

      _showMessage(
        _loadError == null
            ? 'تم حذف المهمة.'
            : 'تم الحذف، لكن تعذر تحديث القائمة.',
      );
    } catch (_) {
      _showMessage('تعذر حذف المهمة.');
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: muted),
      filled: true,
      fillColor: bg,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: BorderSide.none,
      ),
      errorStyle: const TextStyle(color: Colors.redAccent),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'completed':
        return accent;
      case 'running':
        return blue;
      case 'failed':
        return Colors.redAccent;
      default:
        return orange;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'completed':
        return 'مكتملة';
      case 'running':
        return 'قيد التنفيذ';
      case 'failed':
        return 'فشلت';
      case 'pending':
        return 'معلقة';
      default:
        return 'غير معروفة';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: bg,
      child: RefreshIndicator(
        color: accent,
        backgroundColor: panel,
        onRefresh: () => _loadJobs(showMessage: true),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: [
            _buildHeader(),
            const SizedBox(height: 18),
            _buildSummary(),
            const SizedBox(height: 22),
            Row(
              textDirection: TextDirection.rtl,
              children: [
                const Icon(
                  Icons.assignment_outlined,
                  color: accent,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'قائمة المهام',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  '${_jobs.length} مهمة',
                  style: const TextStyle(
                    color: muted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                  child: CircularProgressIndicator(color: accent),
                ),
              )
            else if (_loadError != null)
              _buildErrorState()
            else if (_jobs.isEmpty)
              _buildEmptyState()
            else
              ..._jobs.map(_jobCard),
            if (_busy) ...[
              const SizedBox(height: 10),
              const LinearProgressIndicator(
                color: accent,
                backgroundColor: panel,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      textDirection: TextDirection.rtl,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: accent.withOpacity(0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.assignment_rounded,
            color: accent,
            size: 25,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'إدارة المهام',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 5),
              Text(
                'تنظيم المهام ومتابعة حالتها محليًا',
                style: TextStyle(color: muted, fontSize: 12),
              ),
            ],
          ),
        ),
        FilledButton.icon(
          onPressed: _busy ? null : _addJob,
          style: FilledButton.styleFrom(
            backgroundColor: accent,
            foregroundColor: bg,
          ),
          icon: const Icon(Icons.add_rounded, size: 19),
          label: const Text('إضافة'),
        ),
      ],
    );
  }

  Widget _buildSummary() {
    final pending =
        _jobs.where((job) => job.status == 'pending').length;
    final running =
        _jobs.where((job) => job.status == 'running').length;
    final completed =
        _jobs.where((job) => job.status == 'completed').length;

    return Row(
      children: [
        Expanded(
          child: _summaryCard(
            'معلقة',
            pending,
            orange,
            Icons.schedule_rounded,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _summaryCard(
            'قيد التنفيذ',
            running,
            blue,
            Icons.play_circle_outline_rounded,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _summaryCard(
            'مكتملة',
            completed,
            accent,
            Icons.check_circle_outline_rounded,
          ),
        ),
      ],
    );
  }

  Widget _summaryCard(
    String title,
    int count,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 13,
      ),
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 21),
          const SizedBox(height: 8),
          Text(
            '$count',
            style: TextStyle(
              color: color,
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(color: muted, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _jobCard(Job job) {
    final color = _statusColor(job.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFF293443)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            textDirection: TextDirection.rtl,
            children: [
              Container(
                width: 39,
                height: 39,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.assignment_outlined,
                  color: accent,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  job.title,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed: _busy ? null : () => _deleteJob(job),
                tooltip: 'حذف المهمة',
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.redAccent,
                ),
              ),
            ],
          ),
          if (job.description.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              job.description,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Colors.white70,
                height: 1.6,
                fontSize: 13,
              ),
            ),
          ],
          const SizedBox(height: 13),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Row(
              textDirection: TextDirection.rtl,
              children: [
                Icon(Icons.circle, color: color, size: 9),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    _statusLabel(job.status),
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  enabled: !_busy,
                  tooltip: 'تغيير الحالة',
                  icon: const Icon(
                    Icons.more_horiz_rounded,
                    color: Colors.white70,
                  ),
                  onSelected: (status) {
                    _changeStatus(job, status);
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'pending',
                      child: Text('معلقة'),
                    ),
                    PopupMenuItem(
                      value: 'running',
                      child: Text('قيد التنفيذ'),
                    ),
                    PopupMenuItem(
                      value: 'completed',
                      child: Text('مكتملة'),
                    ),
                    PopupMenuItem(
                      value: 'failed',
                      child: Text('فشلت'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFF293443)),
      ),
      child: const Column(
        children: [
          Icon(Icons.assignment_add, color: muted, size: 43),
          SizedBox(height: 13),
          Text(
            'لا توجد مهام مسجلة',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          SizedBox(height: 7),
          Text(
            'أضف مهمة جديدة لتسجيل العمل ومتابعة حالته. '
            'إنشاء المهمة لا يعني تنفيذها تلقائيًا.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: muted,
              fontSize: 12,
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Colors.redAccent.withOpacity(0.25),
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Colors.redAccent,
            size: 36,
          ),
          const SizedBox(height: 10),
          const Text(
            'تعذر تحميل المهام',
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
              fontSize: 12,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _loadJobs(showMessage: true),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }
}