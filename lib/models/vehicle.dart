/// Représente un camping-car / fourgon aménagé et ses données de poids
/// telles qu'elles figurent sur la carte grise.
class Vehicle {
  final String name;
  final double ptac; // Poids Total Autorisé en Charge (champ F1/F2 carte grise), en kg
  final double pvom; // Poids à Vide en Ordre de Marche (champ G carte grise), en kg
  final int placesCarteGrise; // Nombre de places déclarées sur la carte grise

  const Vehicle({
    required this.name,
    required this.ptac,
    required this.pvom,
    required this.placesCarteGrise,
  });

  /// Charge utile brute = PTAC - PVOM
  double get chargeUtileBrute => ptac - pvom;

  Map<String, dynamic> toJson() => {
        'name': name,
        'ptac': ptac,
        'pvom': pvom,
        'placesCarteGrise': placesCarteGrise,
      };

  factory Vehicle.fromJson(Map<String, dynamic> json) => Vehicle(
        name: json['name'] as String,
        ptac: (json['ptac'] as num).toDouble(),
        pvom: (json['pvom'] as num).toDouble(),
        placesCarteGrise: json['placesCarteGrise'] as int,
      );
}

/// Un poste de chargement additionnel (passager, option, accessoire...)
class ChargeItem {
  final String label;
  final double weightKg;
  final bool isPassenger;

  const ChargeItem({
    required this.label,
    required this.weightKg,
    this.isPassenger = false,
  });
}
