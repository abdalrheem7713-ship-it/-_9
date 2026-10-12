import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../services/apk_analysis_service.dart';
import '../services/device_capabilities_service.dart';
import '../services/installed_apps_service.dart';

class AdvancedScanPage extends StatefulWidget {
  const AdvancedScanPage({super.key});

  @override
  State<AdvancedScanPage> createState() => _AdvancedScanPageState();
}

class _AdvancedScanPageState extends State<AdvancedScanPage> {
  static const Color bg = Color(0xFF0B1017);
  static const Color panel = Color(0xFF151E29);
  static const Color accent = Color(0xFF21D6A1);
  static const Color muted = Color(0xFF8D9AAA);
  static const Color blue = Color(0xFF58A6FF);
  static const Color orange = Color(0xFFFFBD69);
  static const Color danger = Color(0xFFFF7777);

  final DeviceCapabilitiesService _deviceService =
      DeviceCapabilitiesService();

  final InstalledAppsService _appsService =
      InstalledAppsService();

  final ApkAnalysisService _apkService =
      ApkAnalysisService();

  DeviceCapabilities? _device;
  List<InstalledApp> _apps = [];
  ApkAnalysisResult? _apkResult;

  int _selectedLevel = 1;
  bool _loading = false;
  String? _error;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _loadDevice();
  }

  Future<void> _loadDevice() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final device = await _deviceService.inspect();

      if (!mounted) return;

      setState(() {
        _device = device;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = 'تعذر قراءة قدرات الجهاز: $e';
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _scanApps() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final apps = await _appsService.getInstalledApps();

      if (!mounted) return;

      setState(() {
        _apps = apps;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = 'تعذر جرد التطبيقات. تحقق من إعدادات أندرويد.';
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _selectAndAnalyzeApk() async {
    setState(() {
      _loading = true;
      _error = null;
      _apkResult = null;
    });

    try {
      final selection = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['apk'],
        allowMultiple: false,
        withData: false,
      );

      if (selection == null || selection.files.isEmpty) {
        return;
      }

      final path = selection.files.single.path;

      if (path == null || path.isEmpty) {
        throw Exception(
          'لم يُرجع منتقي الملفات مسارًا مباشرًا. '
          'قد يحتاج هذا الملف إلى طريقة قراءة بديلة.',
        );
      }

      final result = await _apkService.analyze(path);

      if (!mounted) return;

      setState(() {
        _apkResult = result;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = 'تعذر تحليل ملف APK: $e';
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  List<InstalledApp> get _filteredApps {
    final query = _search.trim().toLowerCase();

    if (query.isEmpty) return _apps;

    return _apps.where((app) {
      return app.name.toLowerCase().contains(query) ||
          app.packageName.toLowerCase().contains(query);
    }).toList();
  }

  String _selectedLevelName() {
    switch (_selectedLevel) {
      case 1:
        return 'الفحص الأساسي';
      case 2:
        return 'الفحص الموسّع';
      case 3:
        return 'الباحث المتقدم';
      default:
        return 'الفحص الأساسي';
    }
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes بايت';

    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(2)} كيلوبايت';
    }

    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} ميغابايت';
    }

    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} غيغابايت';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        foregroundColor: Colors.white,
        title: const Text('الباحث الأمني'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _loadDevice,
            icon: const Icon(Icons.refresh),
            tooltip: 'تحديث معلومات الجهاز',
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _header(),
            const SizedBox(height: 20),

            _sectionTitle('مستوى الفحص'),
            const SizedBox(height: 10),

            _levelCard(
              level: 1,
              title: 'الفحص الأساسي',
              description:
                  'تحليل الملفات المتاحة وبصماتها الرقمية.',
              icon: Icons.shield_outlined,
              color: accent,
            ),

            _levelCard(
              level: 2,
              title: 'الفحص الموسّع',
              description:
                  'فحوص إضافية حسب الصلاحيات والإمكانات المتاحة.',
              icon: Icons.manage_search,
              color: blue,
            ),

            _levelCard(
              level: 3,
              title: 'الباحث المتقدم',
              description:
                  'فحوص إضافية بحسب بيئة الجهاز والصلاحيات الفعلية.',
              icon: Icons.biotech_outlined,
              color: orange,
            ),

            const SizedBox(height: 20),

            _sectionTitle('قدرات الجهاز'),
            const SizedBox(height: 10),
            _deviceCard(),

            if (_error != null) ...[
              const SizedBox(height: 12),
              _errorCard(_error!),
            ],

            const SizedBox(height: 22),

            _sectionTitle('تحليل ملفات APK'),
            const SizedBox(height: 8),

            const Text(
              'اختر ملف APK من الملفات المتاحة على جهازك '
              'لفحص بنية الحزمة ووجود الملفات الأساسية.',
              style: TextStyle(
                color: muted,
                height: 1.6,
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed:
                    _loading ? null : _selectAndAnalyzeApk,
                icon: const Icon(Icons.policy_outlined),
                label: const Text('اختيار APK وتحليله'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: blue,
                  foregroundColor: bg,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            if (_apkResult != null) ...[
              const SizedBox(height: 14),
              _apkResultCard(_apkResult!),
            ],

            const SizedBox(height: 24),

            _sectionTitle('التطبيقات المثبتة'),
            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _loading ? null : _scanApps,
                icon: const Icon(Icons.phone_android),
                label: const Text('جرد التطبيقات'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: bg,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),

            if (_apps.isNotEmpty) ...[
              const SizedBox(height: 12),

              TextField(
                onChanged: (value) {
                  setState(() => _search = value);
                },
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'ابحث بالاسم أو معرّف الحزمة',
                  hintStyle: const TextStyle(color: muted),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: muted,
                  ),
                  filled: true,
                  fillColor: panel,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'عدد النتائج: ${_filteredApps.length}',
                style: const TextStyle(color: muted),
              ),

              const SizedBox(height: 8),

              ..._filteredApps.map(_appTile),
            ],

            if (_loading) ...[
              const SizedBox(height: 18),
              const Center(
                child: CircularProgressIndicator(color: accent),
              ),
              const SizedBox(height: 8),
              const Center(
                child: Text(
                  'جارٍ تنفيذ العملية...',
                  style: TextStyle(color: muted),
                ),
              ),
            ],

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accent.withOpacity(0.3),
        ),
      ),
      child: const Row(
        children: [
          Icon(Icons.security, color: accent, size: 38),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'نَذْر | محرك الفحص',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'اختر مستوى الفحص واستعرض قدرات الجهاز '
                  'وحلل ملفات APK.',
                  style: TextStyle(
                    color: muted,
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

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 17,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _levelCard({
    required int level,
    required String title,
    required String description,
    required IconData icon,
    required Color color,
  }) {
    final selected = _selectedLevel == level;

    return Card(
      color: selected
          ? color.withOpacity(0.12)
          : panel,
      margin: const EdgeInsets.only(bottom: 9),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: selected ? color : Colors.transparent,
        ),
      ),
      child: RadioListTile<int>(
        value: level,
        groupValue: _selectedLevel,
        activeColor: color,
        onChanged: (value) {
          if (value != null) {
            setState(() => _selectedLevel = value);
          }
        },
        secondary: Icon(icon, color: color, size: 29),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          description,
          style: const TextStyle(
            color: muted,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  Widget _deviceCard() {
    final device = _device;

    if (device == null) {
      return _infoPanel(
        _loading
            ? 'جارٍ قراءة معلومات الجهاز...'
            : 'معلومات الجهاز غير متاحة حتى الآن.',
        Icons.info_outline,
      );
    }

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          _infoRow('إصدار النظام', device.androidVersion),
          _infoRow('مستوى SDK', '${device.androidSdk}'),
          _infoRow(
            'جرد التطبيقات',
            device.appInventoryAvailable
                ? 'متاح مبدئيًا'
                : 'غير متاح',
          ),
          _infoRow(
            'مؤشرات Root',
            device.rootAvailable
                ? 'عُثر على مؤشرات'
                : 'لم يُعثر على مؤشرات',
          ),
          _infoRow(
            'البيئة المتقدمة',
            device.advancedEnvironmentAvailable
                ? 'مؤشر متاح'
                : 'غير مؤكدة',
          ),

          const Divider(color: muted),

          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'المستوى المختار: ${_selectedLevelName()}',
              style: const TextStyle(
                color: accent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'اختيار المستوى يحدد الوضع المختار في الواجهة. '
            'لا يعني ذلك أن كل الفحوص المتقدمة قد نُفذت.',
            style: TextStyle(
              color: muted,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _apkResultCard(ApkAnalysisResult result) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: blue.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.insert_drive_file_outlined,
                color: blue,
                size: 30,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  result.fileName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          _infoRow('حجم الملف', _formatSize(result.sizeBytes)),
          _infoRow(
            'بنية ZIP',
            result.zipStructureValid ? 'قابلة للقراءة' : 'غير صالحة',
          ),
          _infoRow(
            'AndroidManifest.xml',
            result.hasAndroidManifest ? 'موجود' : 'غير موجود',
          ),
          _infoRow(
            'ملفات DEX',
            result.hasDexFiles ? 'موجودة' : 'غير موجودة',
          ),
          _infoRow(
            'resources.arsc',
            result.hasResources ? 'موجود' : 'غير موجود',
          ),
          _infoRow(
            'عدد العناصر المفحوصة',
            '${result.entriesChecked}',
          ),

          const SizedBox(height: 12),

          const Text(
            'أسماء الملفات المكتشفة',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          if (result.entries.isEmpty)
            const Text(
              'لم تُعرض أسماء ملفات.',
              style: TextStyle(color: muted),
            )
          else
            ...result.entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: SelectableText(
                  entry,
                  style: const TextStyle(
                    color: muted,
                    fontSize: 12,
                  ),
                ),
              ),
            ),

          const SizedBox(height: 12),

          _messageCard(
            result.note,
            blue,
            Icons.info_outline,
          ),

          const SizedBox(height: 8),

          _messageCard(
            'هذه النتيجة تفحص بنية الحزمة فقط؛ '
            'ولا تستخرج حاليًا اسم الحزمة أو الأذونات من '
            'الـ Manifest الثنائي، ولا تثبت خلو التطبيق من البرمجيات الخبيثة.',
            orange,
            Icons.warning_amber_rounded,
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: muted),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoPanel(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: accent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: muted),
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorCard(String message) {
    return _messageCard(
      message,
      danger,
      Icons.error_outline,
    );
  }

  Widget _messageCard(
    String message,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: color,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _appTile(InstalledApp app) {
    return Card(
      color: panel,
      margin: const EdgeInsets.only(bottom: 7),
      child: ListTile(
        leading: Icon(
          app.isSystemApp
              ? Icons.settings_suggest
              : Icons.apps,
          color: app.isSystemApp ? muted : accent,
        ),
        title: Text(
          app.name,
          style: const TextStyle(color: Colors.white),
        ),
        subtitle: Text(
          '${app.packageName}\nالإصدار: ${app.version}',
          style: const TextStyle(
            color: muted,
            height: 1.5,
          ),
        ),
        isThreeLine: true,
        trailing: app.isSystemApp
            ? const Text(
                'نظام',
                style: TextStyle(
                  color: muted,
                  fontSize: 11,
                ),
              )
            : null,
      ),
    );
  }
}