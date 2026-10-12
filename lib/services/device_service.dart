
import '../database/local_database.dart';
import '../models/device.dart';

class DeviceService {
  final LocalDatabase _database = LocalDatabase.instance;

  Future<int> addDevice({
    required String name,
    required String address,
    String notes = '',
    bool authorized = false,
  }) async {
    if (name.trim().isEmpty) {
      throw ArgumentError('اسم الجهاز مطلوب');
    }

    if (address.trim().isEmpty) {
      throw ArgumentError('عنوان الجهاز مطلوب');
    }

    final device = Device(
      name: name.trim(),
      address: address.trim(),
      notes: notes.trim(),
      authorized: authorized,
      createdAt: DateTime.now(),
    );

    final id = await _database.insertDevice(device);

    await _database.addLog(
      category: 'devices',
      message: 'تمت إضافة الجهاز: ${device.name}',
    );

    return id;
  }

  Future<List<Device>> getAllDevices() {
    return _database.getDevices();
  }

  Future<void> updateDevice(Device device) async {
    await _database.updateDevice(device);

    await _database.addLog(
      category: 'devices',
      message: 'تم تحديث الجهاز: ${device.name}',
    );
  }

  Future<void> deleteDevice(int id) async {
    await _database.deleteDevice(id);

    await _database.addLog(
      category: 'devices',
      message: 'تم حذف الجهاز رقم $id',
    );
  }
}