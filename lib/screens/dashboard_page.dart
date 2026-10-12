
import 'package:flutter/material.dart';

import '../database/local_database.dart';
import '../widgets/section_title.dart';
import '../widgets/stat_card.dart';
import '../widgets/feature_card.dart';
import '../widgets/info_row.dart';

class DashboardPage extends StatefulWidget {
  final ValueChanged<int> onOpen;

  const DashboardPage({
    super.key,
    required this.onOpen,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  static const Color bg = Color(0xFF0B1017);
  static const Color panel = Color(0xFF151E29);
  static const Color accent = Color(0xFF21D6A1);
  static const Color muted = Color(0xFF8D9AAA);
  static const Color blue = Color(0xFF58A6FF);
  static const Color orange = Color(0xFFFFBD69);

  late Future<Map<String, int>> _countsFuture;

  @override
  void initState() {
    super.initState();
    _loadCounts();
  }

  void _loadCounts() {
    _countsFuture = LocalDatabase.instance.getCounts();
  }

  Future<void> _refresh() async {
    setState(_loadCounts);

    try {
      await _countsFuture;
    } catch (_) {
      // يعرض FutureBuilder رسالة الخطأ.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: bg,
      child: RefreshIndicator(
        color: accent,
        backgroundColor: panel,
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          children: [
            _buildWelcomeCard(),
            const SizedBox(height: 26),

            const SectionTitle(
              'نظرة عامة',
              subtitle: 'إحصاءات السجلات المحلية',
              icon: Icons.analytics_rounded,
            ),
            const SizedBox(height: 14),

            FutureBuilder<Map<String, int>>(
              future: _countsFuture,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _buildErrorCard();
                }

                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: accent,
                      ),
                    ),
                  );
                }

                final counts = snapshot.data ?? <String, int>{};

                return GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.12,
                  children: [
                    StatCard(
                      title: 'الأجهزة',
                      value: '${counts['devices'] ?? 0}',
                      icon: Icons.devices_rounded,
                      color: blue,
                      subtitle: 'الأصول المسجلة',
                      onTap: () => widget.onOpen(4),
                    ),
                    StatCard(
                      title: 'المهام',
                      value: '${counts['jobs'] ?? 0}',
                      icon: Icons.assignment_rounded,
                      color: accent,
                      subtitle: 'إجمالي المهام',
                      onTap: () => widget.onOpen(5),
                    ),
                    StatCard(
                      title: 'الثغرات',
                      value: '${counts['vulnerabilities'] ?? 0}',
                      icon: Icons.bug_report_rounded,
                      color: orange,
                      subtitle: 'السجلات المسجلة',
                      onTap: () => widget.onOpen(6),
                    ),
                    StatCard(
                      title: 'القضايا',
                      value: '${counts['incidents'] ?? 0}',
                      icon: Icons.health_and_safety_rounded,
                      color: const Color(0xFFB69CFF),
                      subtitle: 'قضايا الاستجابة',
                      onTap: () => widget.onOpen(3),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 26),

            const SectionTitle(
              'الأنظمة الرئيسية',
              subtitle: 'الوصول السريع إلى أدوات المنصة',
              icon: Icons.grid_view_rounded,
            ),
            const SizedBox(height: 14),

            FeatureCard(
              icon: Icons.radar_rounded,
              color: blue,
              title: 'الاختبار الأمني',
              description:
                  'توثيق الفحوص المصرح بها ومراجعة سجلات التدقيق.',
              badgeText: 'نطاق مصرح به',
              onTap: () => widget.onOpen(1),
            ),
            FeatureCard(
              icon: Icons.shield_rounded,
              color: accent,
              title: 'الحماية والتحليل',
              description:
                  'تحليل الملفات وحساب بصماتها وإدارة الأدلة المحلية.',
              onTap: () => widget.onOpen(2),
            ),
            FeatureCard(
              icon: Icons.health_and_safety_rounded,
              color: orange,
              title: 'التدخل والاستعادة',
              description:
                  'تسجيل الحوادث ومتابعة إجراءات الاستجابة والاستعادة.',
              onTap: () => widget.onOpen(3),
            ),

            const SizedBox(height: 18),

            const SectionTitle(
              'حالة المنصة',
              subtitle: 'الحالة المعروفة من إعداد المشروع الحالي',
              icon: Icons.monitor_heart_rounded,
            ),
            const SizedBox(height: 14),

            const InfoRow(
              icon: Icons.storage_rounded,
              title: 'قاعدة البيانات المحلية',
              subtitle:
                  'يتم تحميل الإحصاءات من قاعدة بيانات التطبيق.',
              color: accent,
              status: 'محلي',
            ),
            const SizedBox(height: 10),

            const InfoRow(
              icon: Icons.cloud_off_rounded,
              title: 'الخادم المركزي',
              subtitle:
                  'الاتصال المركزي غير مفعّل في هذه المرحلة.',
              color: orange,
              status: 'غير مهيأ',
            ),
            const SizedBox(height: 10),

            const InfoRow(
              icon: Icons.fact_check_outlined,
              title: 'سجل التدقيق',
              subtitle:
                  'راجع السجلات المحفوظة لمتابعة الإجراءات الموثقة.',
              color: blue,
              status: 'السجلات',
            ),

            const SizedBox(height: 24),

            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: panel,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: accent.withOpacity(0.16),
                ),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: accent,
                    size: 22,
                  ),
                  SizedBox(width: 11),
                  Expanded(
                    child: Text(
                      'تعرض هذه اللوحة البيانات المحلية المسجلة فقط. '
                      'ظهور عدد أو سجل لا يعني أن فحصًا أمنيًا '
                      'فعليًا قد نُفّذ، كما أن الاتصال بالخادم '
                      'المركزي يحتاج إلى تهيئة مستقلة.',
                      style: TextStyle(
                        color: muted,
                        fontSize: 12,
                        height: 1.7,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      padding: const EdgeInsets.all(21),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF173B39),
            Color(0xFF152330),
            Color(0xFF111923),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: accent.withOpacity(0.28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.security_rounded,
                      color: accent,
                      size: 15,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'NATHR CONTROL',
                      style: TextStyle(
                        color: accent,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.7,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.hub_rounded,
                color: Color(0xFF63CDB4),
                size: 27,
              ),
            ],
          ),
          const SizedBox(height: 23),
          const Text(
            'مركز القيادة الأمنية',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'إدارة الأصول والمهام والأدلة الأمنية '
            'من لوحة قيادة موحّدة.',
            style: TextStyle(
              color: Color(0xFFC0CCD6),
              fontSize: 13,
              height: 1.8,
            ),
          ),
          const SizedBox(height: 19),
          Container(
            height: 1,
            color: Colors.white.withOpacity(0.09),
          ),
          const SizedBox(height: 14),
          const Row(
            children: [
              Icon(
                Icons.phone_android_rounded,
                color: accent,
                size: 17,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'وضع التشغيل المحلي',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ),
              Text(
                'NATHR',
                style: TextStyle(
                  color: accent,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Colors.redAccent.withOpacity(0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.error_outline_rounded,
                color: Colors.redAccent,
              ),
              SizedBox(width: 9),
              Expanded(
                child: Text(
                  'تعذّر تحميل الإحصاءات',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'قد تكون هناك مشكلة في تهيئة قاعدة البيانات. '
            'لن نستبدل البيانات المتعذّر تحميلها بأرقام وهمية.',
            style: TextStyle(
              color: muted,
              fontSize: 12,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('إعادة المحاولة'),
            ),
          ),
        ],
      ),
    );
  }
}