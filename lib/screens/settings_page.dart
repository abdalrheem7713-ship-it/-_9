import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/local_database.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  static const Color _bg = Color(0xFF0B1118);
  static const Color _panel = Color(0xFF17212B);
  static const Color _accent = Color(0xFF00D4AA);
  static const Color _muted = Color(0xFF8D9AAA);

  static const String _confirmKey = 'nathr_confirm_actions';
  static const String _localKey = 'nathr_local_only';

  bool _loading = true;
  bool _saving = false;
  bool _refreshing = false;

  bool _confirmActions = true;
  bool _localOnly = true;

  String? _loadError;

  Map<String, int> _counts = {
    'devices': 0,
    'jobs': 0,
    'vulnerabilities': 0,
    'incidents': 0,
  };

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings({
    bool showLoading = true,
  }) async {
    if (!mounted) return;

    setState(() {
      _loadError = null;

      if (showLoading) {
        _loading = true;
      } else {
        _refreshing = true;
      }
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final counts = await LocalDatabase.instance.getCounts();

      if (!mounted) return;

      setState(() {
        _confirmActions =
            prefs.getBool(_confirmKey) ?? true;

        _localOnly =
            prefs.getBool(_localKey) ?? true;

        _counts = counts;
        _loading = false;
        _refreshing = false;
        _loadError = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _refreshing = false;
        _loadError =
            'تعذر تحميل بعض البيانات. حاول التحديث مرة أخرى.';
      });
    }
  }

  Future<void> _saveBoolean(
    String key,
    bool value,
  ) async {
    if (_saving || !mounted) return;

    setState(() {
      _saving = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setBool(key, value);

      if (!mounted) return;

      setState(() {
        if (key == _confirmKey) {
          _confirmActions = value;
        } else if (key == _localKey) {
          _localOnly = value;
        }
      });

      _message('تم حفظ الإعداد بنجاح');
    } catch (e) {
      _message('تعذر حفظ الإعداد. حاول مرة أخرى.');
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  Future<void> _refresh() async {
    await _loadSettings(showLoading: false);
  }

  void _message(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _showAbout() async {
    showAboutDialog(
      context: context,
      applicationName: 'نَذْر | NATHR',
      applicationVersion: '1.0.0',
      applicationLegalese:
          'منصة لإدارة الاختبارات الأمنية المصرح بها '
          'والتحليل والحماية والاستعادة.',
      children: const [
        SizedBox(height: 12),
        Text(
          'تُحفظ البيانات الحالية محليًا على الجهاز. '
          'الاتصال بخادم مركزي أو وكلاء موثوقين '
          'يتطلب إعدادًا وتنفيذًا مستقلًا.',
        ),
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(
        top: 20,
        bottom: 10,
      ),
      child: Align(
        alignment: Alignment.centerRight,
        child: Text(
          title,
          style: const TextStyle(
            color: _accent,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _settingSwitch({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Card(
      color: _panel,
      child: SwitchListTile(
        secondary: Icon(
          icon,
          color: _accent,
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            color: Colors.white60,
          ),
        ),
        value: value,
        activeThumbColor: _accent,
        onChanged: _saving || _loading
            ? null
            : onChanged,
      ),
    );
  }

  Widget _countTile(
    String title,
    int count,
    IconData icon,
  ) {
    return Card(
      color: _panel,
      child: ListTile(
        leading: Icon(
          icon,
          color: _accent,
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
          ),
        ),
        trailing: Text(
          '$count',
          style: const TextStyle(
            color: _accent,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _errorPanel() {
    return Card(
      color: Colors.redAccent.withOpacity(0.08),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(
              _loadError!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed:
                  _refreshing ? null : _refresh,
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text('الإعدادات'),
        backgroundColor: const Color(0xFF111B25),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _refreshing ? null : _refresh,
            icon: const Icon(Icons.refresh),
            tooltip: 'تحديث',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(12),
          children: [
            if (_refreshing)
              const LinearProgressIndicator(
                color: _accent,
              ),

            if (_loadError != null)
              _errorPanel(),

            Card(
              color: _panel,
              child: const ListTile(
                leading: Icon(
                  Icons.shield_outlined,
                  color: _accent,
                  size: 36,
                ),
                title: Text(
                  'نَذْر | NATHR',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                subtitle: Text(
                  'منصة الاختبار والحماية والاستعادة\n'
                  'الإصدار 1.0.0',
                  style: TextStyle(
                    color: Colors.white60,
                  ),
                ),
              ),
            ),

            _sectionTitle('تفضيلات التطبيق'),

            _settingSwitch(
              icon: Icons.verified_user_outlined,
              title: 'تأكيد العمليات',
              subtitle:
                  'يحفظ تفضيل التأكيد على هذا الجهاز. '
                  'يجب ربط هذا التفضيل بكل عملية '
                  'على حدة حتى يصبح فعالًا.',
              value: _confirmActions,
              onChanged: (value) {
                _saveBoolean(_confirmKey, value);
              },
            ),

            _settingSwitch(
              icon: Icons.phone_android,
              title: 'الوضع المحلي',
              subtitle:
                  'يستخدم التطبيق التخزين المحلي حاليًا. '
                  'الاتصال بخادم مركزي غير منفذ بعد.',
              value: _localOnly,
              onChanged: (value) {
                if (!value) {
                  _message(
                    'لا يمكن تعطيل الوضع المحلي؛ '
                    'الاتصال بالخادم غير منفذ بعد.',
                  );
                  return;
                }

                _saveBoolean(_localKey, true);
              },
            ),

            if (_saving)
              const Padding(
                padding: EdgeInsets.all(8),
                child: LinearProgressIndicator(
                  color: _accent,
                ),
              ),

            _sectionTitle('البيانات المحلية'),

            if (_loading)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Center(
                  child: CircularProgressIndicator(
                    color: _accent,
                  ),
                ),
              )
            else ...[
              _countTile(
                'الأجهزة المسجلة',
                _counts['devices'] ?? 0,
                Icons.devices,
              ),
              _countTile(
                'المهام المسجلة',
                _counts['jobs'] ?? 0,
                Icons.assignment_outlined,
              ),
              _countTile(
                'سجلات الثغرات',
                _counts['vulnerabilities'] ?? 0,
                Icons.gpp_maybe_outlined,
              ),
              _countTile(
                'القضايا الأمنية',
                _counts['incidents'] ?? 0,
                Icons.health_and_safety_outlined,
              ),
            ],

            _sectionTitle('معلومات التطبيق'),

            Card(
              color: _panel,
              child: ListTile(
                leading: const Icon(
                  Icons.info_outline,
                  color: _accent,
                ),
                title: const Text(
                  'حول التطبيق',
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
                trailing: const Icon(
                  Icons.chevron_right,
                  color: Colors.white54,
                ),
                onTap: _showAbout,
              ),
            ),

            const Card(
              color: _panel,
              child: ListTile(
                leading: Icon(
                  Icons.storage_outlined,
                  color: _accent,
                ),
                title: Text(
                  'قاعدة البيانات',
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
                subtitle: Text(
                  'SQLite — تخزين محلي',
                  style: TextStyle(
                    color: Colors.white60,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            const Center(
              child: Text(
                'NATHR',
                style: TextStyle(
                  color: Colors.white38,
                  letterSpacing: 3,
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}