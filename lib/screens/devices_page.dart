import 'package:flutter/material.dart';

import '../models/device.dart';
import '../services/device_service.dart';

class DevicesPage extends StatefulWidget {
  const DevicesPage({super.key});

  @override
  State<DevicesPage> createState() => _DevicesPageState();
}

class _DevicesPageState extends State<DevicesPage> {
  static const Color bg = Color(0xFF0B1017);
  static const Color panel = Color(0xFF151E29);
  static const Color accent = Color(0xFF21D6A1);
  static const Color muted = Color(0xFF8D9AAA);
  static const Color blue = Color(0xFF58A6FF);

  final DeviceService _service = DeviceService();

  List<Device> _devices = [];
  bool _loading = true;
  bool _saving = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadDevices();
  }

  Future<void> _loadDevices({bool showMessage = false}) async {
    try {
      final devices = await _service.getAllDevices();

      if (!mounted) return;

      setState(() {
        _devices = devices;
        _loading = false;
        _loadError = null;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _loadError = 'تعذر تحميل الأجهزة من قاعدة البيانات.';
      });

      if (showMessage) {
        _showMessage('تعذر تحديث قائمة الأجهزة.');
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

  Future<void> _showDeviceForm({Device? device}) async {
    if (_saving) return;

    final nameController = TextEditingController(
      text: device?.name ?? '',
    );

    final addressController = TextEditingController(
      text: device?.address ?? '',
    );

    final notesController = TextEditingController(
      text: device?.notes ?? '',
    );

    bool authorized = device?.authorized ?? false;
    String? validationError;
    bool? result;

    // نحفظ النصوص قبل التخلص من وحدات التحكم.
    String name = '';
    String address = '';
    String notes = '';

    try {
      result = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                backgroundColor: panel,
                title: Text(
                  device == null ? 'إضافة جهاز' : 'تعديل الجهاز',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _field(nameController, 'اسم الجهاز'),
                      const SizedBox(height: 12),
                      _field(
                        addressController,
                        'عنوان الجهاز أو الأصل',
                        ltr: true,
                      ),
                      const SizedBox(height: 12),
                      _field(
                        notesController,
                        'ملاحظات',
                        maxLines: 3,
                      ),
                      const SizedBox(height: 8),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        controlAffinity:
                            ListTileControlAffinity.leading,
                        activeColor: accent,
                        checkColor: bg,
                        value: authorized,
                        onChanged: (value) {
                          setDialogState(() {
                            authorized = value ?? false;
                          });
                        },
                        title: const Text(
                          'لدي تصريح باختبار هذا الأصل',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                        ),
                        subtitle: const Text(
                          'هذا الخيار يسجل إقرارك فقط ولا يتحقق '
                          'من الموافقة بصورة مستقلة.',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            color: muted,
                            fontSize: 11,
                            height: 1.5,
                          ),
                        ),
                      ),
                      if (validationError != null) ...[
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            validationError!,
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
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
                  FilledButton.icon(
                    onPressed: () {
                      final enteredName =
                          nameController.text.trim();
                      final enteredAddress =
                          addressController.text.trim();

                      if (enteredName.isEmpty ||
                          enteredAddress.isEmpty) {
                        setDialogState(() {
                          validationError =
                              'يرجى إدخال اسم الجهاز وعنوانه.';
                        });
                        return;
                      }

                      Navigator.pop(dialogContext, true);
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

      // قراءة القيم هنا قبل التخلص من وحدات التحكم.
      if (result == true) {
        name = nameController.text.trim();
        address = addressController.text.trim();
        notes = notesController.text.trim();
      }
    } finally {
      nameController.dispose();
      addressController.dispose();
      notesController.dispose();
    }

    if (result != true || !mounted) return;

    setState(() {
      _saving = true;
    });

    try {
      if (device == null) {
        await _service.addDevice(
          name: name,
          address: address,
          notes: notes,
          authorized: authorized,
        );
      } else {
        await _service.updateDevice(
          Device(
            id: device.id,
            name: name,
            address: address,
            notes: notes,
            authorized: authorized,
            createdAt: device.createdAt,
          ),
        );
      }

      if (!mounted) return;

      await _loadDevices();

      if (!mounted) return;

      if (_loadError == null) {
        _showMessage(
          device == null
              ? 'تمت إضافة الجهاز.'
              : 'تم تحديث بيانات الجهاز.',
        );
      } else {
        _showMessage(
          'تم حفظ البيانات، لكن تعذر تحديث القائمة.',
        );
      }
    } catch (_) {
      _showMessage('تعذر حفظ بيانات الجهاز.');
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  Future<void> _deleteDevice(Device device) async {
    if (device.id == null || _saving) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: panel,
          title: const Text(
            'تأكيد حذف الجهاز',
            textAlign: TextAlign.right,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'هل تريد حذف "${device.name}" من السجلات المحلية؟',
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
      _saving = true;
    });

    try {
      await _service.deleteDevice(device.id!);

      if (!mounted) return;

      await _loadDevices();

      if (!mounted) return;

      if (_loadError == null) {
        _showMessage('تم حذف الجهاز.');
      } else {
        _showMessage('تم الحذف، لكن تعذر تحديث القائمة.');
      }
    } catch (_) {
      _showMessage('تعذر حذف الجهاز.');
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: bg,
      child: RefreshIndicator(
        onRefresh: () => _loadDevices(showMessage: true),
        color: accent,
        backgroundColor: panel,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            _buildSummary(),
            const SizedBox(height: 18),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                  child: CircularProgressIndicator(
                    color: accent,
                  ),
                ),
              )
            else if (_loadError != null)
              _buildErrorState()
            else if (_devices.isEmpty)
              _emptyState()
            else ...[
              Row(
                textDirection: TextDirection.rtl,
                children: [
                  const Icon(
                    Icons.devices_rounded,
                    color: accent,
                    size: 19,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'الأصول المسجلة',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  Text(
                    '${_devices.length} جهاز',
                    style: const TextStyle(
                      color: muted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ..._devices.map(_deviceCard),
            ],
            if (_saving) ...[
              const SizedBox(height: 8),
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
            Icons.devices_other_rounded,
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
                'إدارة الأجهزة',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 5),
              Text(
                'إدارة الأصول المسجلة محليًا',
                style: TextStyle(
                  color: muted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        FilledButton.icon(
          onPressed: _saving ? null : () => _showDeviceForm(),
          style: FilledButton.styleFrom(
            backgroundColor: accent,
            foregroundColor: bg,
            disabledBackgroundColor: muted,
          ),
          icon: const Icon(Icons.add_rounded, size: 19),
          label: const Text('إضافة'),
        ),
      ],
    );
  }

  Widget _buildSummary() {
    final authorizedCount =
        _devices.where((device) => device.authorized).length;

    return Row(
      children: [
        Expanded(
          child: _summaryCard(
            title: 'إجمالي الأجهزة',
            value: '${_devices.length}',
            icon: Icons.devices_rounded,
            color: blue,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _summaryCard(
            title: 'تصريح مسجل',
            value: '$authorizedCount',
            icon: Icons.verified_user_outlined,
            color: accent,
          ),
        ),
      ],
    );
  }

  Widget _summaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: color.withOpacity(0.15),
        ),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Icon(icon, color: color, size: 23),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  title,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: muted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _deviceCard(Device device) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: device.authorized
              ? accent.withOpacity(0.16)
              : const Color(0xFF293443),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            textDirection: TextDirection.rtl,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: device.authorized
                      ? accent.withOpacity(0.12)
                      : blue.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.devices_rounded,
                  color: device.authorized ? accent : blue,
                  size: 23,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  device.name,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
              Icon(
                device.authorized
                    ? Icons.verified_user_rounded
                    : Icons.help_outline_rounded,
                color: device.authorized ? accent : muted,
                size: 21,
              ),
            ],
          ),
          const SizedBox(height: 13),
          const Text(
            'العنوان',
            textAlign: TextAlign.right,
            style: TextStyle(
              color: muted,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 4),
          SelectableText(
            device.address,
            textAlign: TextAlign.left,
            textDirection: TextDirection.ltr,
            style: const TextStyle(
              color: blue,
              fontSize: 13,
            ),
          ),
          if (device.notes.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'ملاحظات',
              textAlign: TextAlign.right,
              style: TextStyle(
                color: muted,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              device.notes,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Colors.white70,
                height: 1.6,
                fontSize: 13,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: device.authorized
                  ? accent.withOpacity(0.08)
                  : bg,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Row(
              textDirection: TextDirection.rtl,
              children: [
                Icon(
                  device.authorized
                      ? Icons.check_circle_outline_rounded
                      : Icons.info_outline_rounded,
                  color: device.authorized ? accent : muted,
                  size: 17,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    device.authorized
                        ? 'التصريح مسجل من المستخدم'
                        : 'لم يُسجل تصريح لهذا الأصل',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: device.authorized ? accent : muted,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Divider(color: Color(0xFF293443)),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 8,
            runSpacing: 4,
            children: [
              TextButton.icon(
                onPressed: _saving
                    ? null
                    : () => _showDeviceForm(device: device),
                icon: const Icon(
                  Icons.edit_outlined,
                  size: 18,
                ),
                label: const Text('تعديل'),
              ),
              TextButton.icon(
                onPressed: _saving
                    ? null
                    : () => _deleteDevice(device),
                icon: const Icon(
                  Icons.delete_outline,
                  size: 18,
                ),
                label: const Text('حذف'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF293443),
        ),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.devices_other_rounded,
            color: muted,
            size: 44,
          ),
          SizedBox(height: 14),
          Text(
            'لا توجد أجهزة مسجلة',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 7),
          Text(
            'يمكنك إضافة أصل تملكه أو لديك تصريح '
            'بإدارته واختباره.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: muted,
              fontSize: 12,
              height: 1.7,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'اسحب الشاشة إلى الأسفل لتحديث القائمة.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: blue,
              fontSize: 11,
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
            'تعذر تحميل الأجهزة',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 7),
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
            onPressed: () => _loadDevices(showMessage: true),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }

  static Widget _field(
    TextEditingController controller,
    String label, {
    bool ltr = false,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      textDirection:
          ltr ? TextDirection.ltr : TextDirection.rtl,
      textAlign: ltr ? TextAlign.left : TextAlign.right,
      maxLines: maxLines,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 13,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: muted),
        filled: true,
        fillColor: bg,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 13,
          vertical: 13,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}