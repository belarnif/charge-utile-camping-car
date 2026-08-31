import '../models/vehicle.dart';

enum ChargeLevel { safe, warning, danger }

class ChargeResult {
  final double chargeUtileBrute;
  final double totalCharge;
  final double margeRestante;
  final ChargeLevel level;
  final int passengerCount;
  final bool exceedsDeclaredSeats;

  const ChargeResult({
    required this.chargeUtileBrute,
    required this.totalCharge,
    required this.margeRestante,
    required this.level,
    required this.passengerCount,
    required this.exceedsDeclaredSeats,
  });
}

class ChargeCalculator {
  /// Marge de sécurité conseillée avant d'atteindre le PTAC (en kg).
  static const double margeSecuriteConseillee = 100;

  static ChargeResult calculate({
    required Vehicle vehicle,
    required List<ChargeItem> items,
  }) {
    final chargeUtileBrute = vehicle.chargeUtileBrute;
    final totalCharge = items.fold<double>(0, (sum, item) => sum + item.weightKg);
    final margeRestante = chargeUtileBrute - totalCharge;
    final passengerCount = items.where((item) => item.isPassenger).length;
    // Le conducteur compte comme 1 place — on ne compte ici que les
    // passagers ajoutés en plus, donc le total occupé est passengerCount + 1.
    final exceedsDeclaredSeats = (passengerCount + 1) > vehicle.placesCarteGrise;

    ChargeLevel level;
    if (margeRestante < 0 || exceedsDeclaredSeats) {
      level = ChargeLevel.danger; // PTAC dépassé ou nombre de places dépassé
    } else if (margeRestante < margeSecuriteConseillee) {
      level = ChargeLevel.warning; // sous la marge de sécurité conseillée
    } else {
      level = ChargeLevel.safe;
    }

    return ChargeResult(
      chargeUtileBrute: chargeUtileBrute,
      totalCharge: totalCharge,
      margeRestante: margeRestante,
      level: level,
      passengerCount: passengerCount,
      exceedsDeclaredSeats: exceedsDeclaredSeats,
    );
  }
}
