import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/vehicle.dart';

/// Sauvegarde le véhicule localement pour éviter de ressaisir
/// le PTAC/PVOM à chaque ouverture de l'app.
class StorageService {
  static const _vehicleKey = 'saved_vehicle';

  static Future<void> saveVehicle(Vehicle vehicle) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_vehicleKey, jsonEncode(vehicle.toJson()));
  }

  static Future<Vehicle?> loadVehicle() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_vehicleKey);
    if (raw == null) return null;
    try {
      return Vehicle.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  static Future<void> clearVehicle() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_vehicleKey);
  }
}
