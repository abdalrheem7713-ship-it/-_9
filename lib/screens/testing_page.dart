
import 'package:flutter/material.dart';

import '../services/audit_service.dart';

class TestingPage extends StatefulWidget {
  const TestingPage({super.key});

  @override
  State<TestingPage> createState() => _TestingPageState();
}

class _TestingPageState extends State<TestingPage> {
  static const Color bg = Color(0xFF0B1017);
  static const Color panel = Color(0xFF151E29);
  static const Color accent = Color(0xFF21D6A1);
  static const Color muted = Color(0xFF8D9AAA);
  static const Color blue = Color(0xFF58A6FF);

  final AuditService _auditService = AuditService();
  final TextEditingController _targetController =
      TextEditingController();

  String _selectedCheck = 'فحص إعدادات الخدمة';
  bool _authorized = false;
  bool _saving = false;

  final List<String> _checks = const [
    'فحص إعدادات الخدمة',
    'مراجعة إعدادات TLS',
    'مراجعة إعدادات الويب',
    'مراجعة سطح التعرض',
    'مراجعة مرجع CVE',
  ];

  @override
  void dispose() {
    _targetController.dispose();
    super.dispose();
  }

  Future<void> _recordCheck() async {
    if (_saving) return;

    if (_targetController.text.trim().isEmpty) {
      _showMessage('أدخل اسم الأصل أو عنوانه أولًا.');
      return;
    }

    if (!_authorized) {
      _showMessage('أكد وجود تصريح قبل تسجيل الفحص.');
      return;
    }

    setState(() => _saving = true);

    try {
      await _auditService.recordCheck(
        target: _targetController.text,
        checkName: _selectedCheck,
        authorized: _authorized,
      );

      if (!mounted) return;

      _showMessage('تم تسجيل الفحص في السجلات المحلية.');
      _targetController.clear();
    } catch (error) {
      if (!mounted) return;
      _showMessage('تعذر تسجيل الفحص: $error');
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: bg,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'الاختبار الأمني المتقدم',
            textAlign: TextAlign.right,
            style: TextStyle(
              color: Colors.white,
              fontSize: 23,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'إدارة الفحوصات وتوثيق نتائجها للأصول المصرح بها.',
            textAlign: TextAlign.right,
            style: TextStyle(color: muted, height: 1.6),
          ),
          const SizedBox(height: 20),
          _sectionCard(
            title: 'مجالات الاختبار',
            icon: Icons.security,
            child: Column(
              children: const [
                _FeatureRow(
                  title: 'استطلاع الأصول والخدمات',
                  subtitle: 'تحديد الأصول المعتمدة ونطاق الاختبار.',
                  icon: Icons.travel_explore,
                ),
                _FeatureRow(
                  title: 'تحليل TLS والويب',
                  subtitle: 'مراجعة الإعدادات والأخطاء الشائعة.',
                  icon: Icons.language,
                ),
                _FeatureRow(
                  title: 'مراجعة الثغرات',
                  subtitle: 'تسجيل النتائج وربطها بمراجع CVE.',
                  icon: Icons.bug_report_outlined,
                ),
                _FeatureRow(
                  title: 'الاختبارات المختبرية',
                  subtitle: 'تجارب محددة ضمن بيئة اختبار معزولة.',
                  icon: Icons.science_outlined,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _sectionCard(
            title: 'تسجيل فحص جديد',
            icon: Icons.playlist_add_check,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'الأصل أو عنوان الهدف',
                  textAlign: TextAlign.right,
                  style: TextStyle(color: muted),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _targetController,
                  textDirection: TextDirection.ltr,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration(
                    'مثال: lab.example.test',
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'نوع الفحص',
                  textAlign: TextAlign.right,
                  style: TextStyle(color: muted),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedCheck,
                  dropdownColor: panel,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('اختر نوع الفحص'),
                  items: _checks.map((check) {
                    return DropdownMenuItem<String>(
                      value: check,
                      child: Text(
                        check,
                        textAlign: TextAlign.right,
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedCheck = value);
                    }
                  },
                ),
                const SizedBox(height: 14),
                CheckboxListTile(
                  value: _authorized,
                  onChanged: (value) {
                    setState(() {
                      _authorized = value ?? false;
                    });
                  },
                  activeColor: accent,
                  checkColor: bg,
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: const Text(
                    'أؤكد أن لدي تصريحًا لاختبار هذا الأصل.',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _saving ? null : _recordCheck,
                  style: FilledButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: bg,
                    padding: const EdgeInsets.all(14),
                  ),
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(
                    _saving ? 'جارٍ الحفظ...' : 'تسجيل الفحص',
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'هذا الإجراء يسجل الفحص فقط ولا ينفذ مسحًا للشبكة.',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: muted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: muted),
      filled: true,
      fillColor: bg,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
    );
  }

  static Widget _sectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            textDirection: TextDirection.rtl,
            children: [
              Icon(icon, color: accent),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _FeatureRow({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        textDirection: TextDirection.rtl,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(width: 2),
          Icon(icon, color: _TestingPageState.blue, size: 25),
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
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: _TestingPageState.muted,
                    fontSize: 12,
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
}