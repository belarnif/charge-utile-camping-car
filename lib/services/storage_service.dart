import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/vehicle.dart';

/// Sauvegarde le véhicule localement pour éviter de ressaisir
/// le PTAC/PVOM à chaque ouverture de l'app.
class StorageService {
  static const _vehicleKey = 'saved_vehicle';
  static const _itemsKey = 'saved_charge_items';

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

  /// Sauvegarde la liste des postes de chargement (passagers, options...)
  /// pour que l'inventaire ne se réinitialise pas à chaque ouverture de l'app —
  /// un besoin réel remonté par les camping-caristes ("faire un inventaire
  /// régulier des affaires embarquées").
  static Future<void> saveItems(List<ChargeItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(items.map((item) => item.toJson()).toList());
    await prefs.setString(_itemsKey, raw);
  }

  static Future<List<ChargeItem>> loadItems() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_itemsKey);
    if (raw == null) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((entry) => ChargeItem.fromJson(entry as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
