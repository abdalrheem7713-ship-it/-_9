import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../services/advanced_file_analysis_service.dart';

class ProtectionPage extends StatefulWidget {
  const ProtectionPage({super.key});

  @override
  State<ProtectionPage> createState() => _ProtectionPageState();
}

class _ProtectionPageState extends State<ProtectionPage> {
  static const Color bg = Color(0xFF0B1017);
  static const Color panel = Color(0xFF151E29);
  static const Color accent = Color(0xFF21D6A1);
  static const Color muted = Color(0xFF8D9AAA);
  static const Color blue = Color(0xFF58A6FF);
  static const Color orange = Color(0xFFFFBD69);

  final AdvancedFileAnalysisService _service =
      AdvancedFileAnalysisService();

  AdvancedFileAnalysisResult? _result;
  bool _loading = false;
  String? _error;

  Future<void> _selectAndAnalyze() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final selection = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
        withData: false,
      );

      if (selection == null || selection.files.isEmpty) {
        if (mounted) setState(() => _loading = false);
        return;
      }

      final path = selection.files.single.path;

      if (path == null || path.isEmpty) {
        throw Exception(
          'تعذر الوصول إلى مسار الملف المحدد.',
        );
      }

      final result = await _service.analyze(path);

      if (!mounted) return;

      setState(() {
        _result = result;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = 'تعذر تحليل الملف: $e';
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
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

  String _riskLabel(FileRiskLevel risk) {
    switch (risk) {
      case FileRiskLevel.low:
        return 'مؤشرات أولية منخفضة';
      case FileRiskLevel.medium:
        return 'يحتاج إلى مراجعة';
      case FileRiskLevel.high:
        return 'خطورة مرتفعة';
      case FileRiskLevel.unknown:
        return 'النتيجة غير محسومة';
    }
  }

  Color _riskColor(FileRiskLevel risk) {
    switch (risk) {
      case FileRiskLevel.low:
        return accent;
      case FileRiskLevel.medium:
        return orange;
      case FileRiskLevel.high:
        return const Color(0xFFFF7777);
      case FileRiskLevel.unknown:
        return muted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _introCard(),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _loading ? null : _selectAndAnalyze,
              icon: const Icon(Icons.folder_open_rounded),
              label: Text(
                _loading ? 'جارٍ التحليل...' : 'اختيار ملف وتحليله',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: bg,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
            ),
          ),
          if (_loading) ...[
            const SizedBox(height: 20),
            const Center(
              child: CircularProgressIndicator(color: accent),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 16),
            _messageCard(
              _error!,
              const Color(0xFFFF7777),
              Icons.error_outline,
            ),
          ],
          if (_result != null) ...[
            const SizedBox(height: 22),
            _sectionTitle('نتيجة التحليل'),
            const SizedBox(height: 10),
            _resultCard(_result!),
          ],
        ],
      ),
    );
  }

  Widget _introCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accent.withOpacity(0.25),
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.shield_rounded,
            color: accent,
            size: 38,
          ),
          SizedBox(height: 12),
          Text(
            'الحماية وتحليل الملفات',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'اختر ملفًا متاحًا على الجهاز لفحص بصمته الرقمية '
            'والتعرف على نوعه الأولي ورصد بعض مؤشرات الاشتباه.',
            style: TextStyle(
              color: muted,
              height: 1.6,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'هذا الفحص أولي ولا يثبت سلامة الملف أو إصابته.',
            style: TextStyle(
              color: orange,
              fontSize: 12,
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

  Widget _resultCard(AdvancedFileAnalysisResult result) {
    final riskColor = _riskColor(result.riskLevel);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.insert_drive_file_rounded,
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
          const SizedBox(height: 15),
          _infoRow('نوع المحتوى', result.detectedType),
          _infoRow('حجم الملف', _formatSize(result.sizeBytes)),
          _infoRow(
            'وقت التحليل',
            result.analyzedAt.toLocal().toString().split('.').first,
          ),
          const Divider(color: Color(0xFF334353), height: 26),
          const Text(
            'المسار',
            style: TextStyle(color: muted),
          ),
          const SizedBox(height: 5),
          SelectableText(
            result.path,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'بصمة SHA-256',
            style: TextStyle(
              color: muted,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 7),
          SelectableText(
            result.sha256,
            style: const TextStyle(
              color: accent,
              fontSize: 12,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: riskColor.withOpacity(0.09),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: riskColor.withOpacity(0.4),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.analytics_outlined, color: riskColor),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _riskLabel(result.riskLevel),
                    style: TextStyle(
                      color: riskColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'المؤشرات والملاحظات',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ...result.findings.map(
            (finding) => Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.fiber_manual_record,
                    color: orange,
                    size: 9,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      finding,
                      style: const TextStyle(
                        color: muted,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          _messageCard(
            'البصمة الرقمية وسيلة للتحقق من تطابق الملفات، '
            'وليست وحدها وسيلة لاكتشاف البرمجيات الخبيثة.',
            blue,
            Icons.info_outline,
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
          const SizedBox(width: 12),
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

  Widget _messageCard(
    String message,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
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
}