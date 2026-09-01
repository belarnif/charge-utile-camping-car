import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/vehicle.dart';
import '../services/charge_calculator.dart';
import '../services/storage_service.dart';
import '../widgets/adaptive_banner_ad.dart';

// ID de test AdMob — à remplacer par le vrai ad unit ID avant publication.
const String kBannerAdUnitId = 'ca-app-pub-3940256099942544/9214589741';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Vehicle? _vehicle;
  List<ChargeItem> _items = [];

  final _ptacController = TextEditingController();
  final _pvomController = TextEditingController();
  final _nameController = TextEditingController();
  final _placesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSavedVehicle();
    _loadSavedItems();
  }

  Future<void> _loadSavedVehicle() async {
    final saved = await StorageService.loadVehicle();
    if (saved != null && mounted) {
      setState(() {
        _vehicle = saved;
        _nameController.text = saved.name;
        _ptacController.text = saved.ptac.toStringAsFixed(0);
        _pvomController.text = saved.pvom.toStringAsFixed(0);
        _placesController.text = saved.placesCarteGrise.toString();
      });
    }
  }

  Future<void> _loadSavedItems() async {
    final saved = await StorageService.loadItems();
    if (mounted) {
      setState(() => _items = saved);
    }
  }

  Future<void> _saveVehicle() async {
    final ptac = double.tryParse(_ptacController.text.replaceAll(',', '.'));
    final pvom = double.tryParse(_pvomController.text.replaceAll(',', '.'));
    final places = int.tryParse(_placesController.text);

    if (ptac == null || pvom == null || places == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Merci de remplir tous les champs correctement.')),
      );
      return;
    }
    if (ptac <= 0 || pvom <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le PTAC et le PVOM doivent être des valeurs positives.')),
      );
      return;
    }
    if (places < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le nombre de places doit être d\'au moins 1.')),
      );
      return;
    }
    if (pvom >= ptac) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le PVOM doit être inférieur au PTAC.')),
      );
      return;
    }

    final name = _nameController.text.trim();
    final vehicle = Vehicle(
      name: name.isEmpty ? 'Mon véhicule' : name,
      ptac: ptac,
      pvom: pvom,
      placesCarteGrise: places,
    );

    await StorageService.saveVehicle(vehicle);
    setState(() => _vehicle = vehicle);
  }

  void _addItem() {
    showDialog(
      context: context,
      builder: (context) => _AddItemDialog(
        onAdd: (item) {
          setState(() => _items.add(item));
          StorageService.saveItems(_items);
        },
      ),
    );
  }

  void _removeItem(int index) {
    setState(() => _items.removeAt(index));
    StorageService.saveItems(_items);
  }

  /// Ouvre une recherche Google Maps pour trouver un point de pesée
  /// (pont-bascule, déchetterie, garage...) à proximité. C'est le besoin
  /// le plus cité par les camping-caristes sur le sujet du poids : savoir
  /// où peser concrètement leur véhicule.
  Future<void> _findWeighingPoints() async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent('pont bascule pesée camion')}',
    );
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible d\'ouvrir Google Maps.')),
      );
    }
  }

  @override
  void dispose() {
    _ptacController.dispose();
    _pvomController.dispose();
    _nameController.dispose();
    _placesController.dispose();
    super.dispose();
  }

  Color _colorForLevel(ChargeLevel level) {
    switch (level) {
      case ChargeLevel.safe:
        return Colors.green;
      case ChargeLevel.warning:
        return Colors.orange;
      case ChargeLevel.danger:
        return Colors.red;
    }
  }

  String _labelForLevel(ChargeResult result) {
    if (result.exceedsDeclaredSeats) {
      return 'Trop de passagers pour les places déclarées à la carte grise';
    }
    switch (result.level) {
      case ChargeLevel.safe:
        return 'Marge confortable';
      case ChargeLevel.warning:
        return 'Marge faible — sous les 100 kg conseillés';
      case ChargeLevel.danger:
        return 'PTAC dépassé — risque d\'amende';
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = _vehicle != null
        ? ChargeCalculator.calculate(vehicle: _vehicle!, items: _items)
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Charge utile camping-car'),
        actions: [
          IconButton(
            tooltip: 'Trouver un point de pesée',
            icon: const Icon(Icons.scale_outlined),
            onPressed: _findWeighingPoints,
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildVehicleForm(),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _findWeighingPoints,
              icon: const Icon(Icons.location_on_outlined),
              label: const Text('Trouver un point de pesée à proximité'),
            ),
            const SizedBox(height: 24),
            if (_vehicle != null) ...[
              Text(
                'Charge utile brute : ${_vehicle!.chargeUtileBrute.toStringAsFixed(0)} kg',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              _buildItemsList(),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _addItem,
                icon: const Icon(Icons.add),
                label: const Text('Ajouter un poste (passager, eau, gaz...)'),
              ),
              const SizedBox(height: 24),
              if (result != null) _buildResultCard(result),
            ],
          ],
        ),
      ),
      bottomNavigationBar: const AdaptiveBannerAd(
        adUnitId: kBannerAdUnitId,
        collapsiblePosition: 'bottom',
      ),
    );
  }

  Widget _buildVehicleForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Mon véhicule', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nom du véhicule (optionnel)'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _ptacController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'PTAC (kg) — champ F1/F2 carte grise',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _pvomController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'PVOM (kg) — champ G carte grise',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _placesController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Nombre de places carte grise'),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _saveVehicle,
              child: const Text('Enregistrer le véhicule'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsList() {
    if (_items.isEmpty) {
      return const Text('Aucun poste ajouté pour le moment.');
    }
    return Column(
      children: List.generate(_items.length, (index) {
        final item = _items[index];
        return ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(item.label),
          subtitle: Text('${item.weightKg.toStringAsFixed(1)} kg'),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _removeItem(index),
          ),
        );
      }),
    );
  }

  Widget _buildResultCard(ChargeResult result) {
    final color = _colorForLevel(result.level);
    return Card(
      color: color.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  result.level == ChargeLevel.safe
                      ? Icons.check_circle
                      : Icons.warning_amber,
                  color: color,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _labelForLevel(result),
                    style: TextStyle(color: color, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text('Total chargé : ${result.totalCharge.toStringAsFixed(1)} kg'),
            Text('Marge restante : ${result.margeRestante.toStringAsFixed(1)} kg'),
            Text(
              'Occupants : ${result.passengerCount + 1} / ${_vehicle!.placesCarteGrise} places déclarées',
              style: result.exceedsDeclaredSeats
                  ? const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

/// Type de poste, pour proposer le bon mode de saisie (kg direct, ou
/// litres convertis automatiquement en kg pour les liquides).
enum _ItemType { passenger, water, diesel, gas, other }

class _AddItemDialog extends StatefulWidget {
  final void Function(ChargeItem) onAdd;
  const _AddItemDialog({required this.onAdd});

  @override
  State<_AddItemDialog> createState() => _AddItemDialogState();
}

class _AddItemDialogState extends State<_AddItemDialog> {
  final _labelController = TextEditingController();
  final _weightController = TextEditingController();
  final _volumeController = TextEditingController();

  _ItemType _type = _ItemType.other;

  static const double poidsPassagerStandard = 75;
  static const double densiteEauKgParLitre = 1.0;
  static const double densiteGasoilKgParLitre = 0.84;
  static const double poidsBouteilleGazStandard = 13; // kg, bouteille 13kg standard

  void _selectType(_ItemType type) {
    setState(() {
      _type = type;
      switch (type) {
        case _ItemType.passenger:
          _labelController.text = 'Passager';
          _weightController.text = poidsPassagerStandard.toStringAsFixed(0);
          break;
        case _ItemType.water:
          _labelController.text = 'Eau';
          _volumeController.clear();
          break;
        case _ItemType.diesel:
          _labelController.text = 'Gasoil';
          _volumeController.clear();
          break;
        case _ItemType.gas:
          _labelController.text = 'Bouteille de gaz';
          _weightController.text = poidsBouteilleGazStandard.toStringAsFixed(0);
          break;
        case _ItemType.other:
          _labelController.clear();
          _weightController.clear();
          break;
      }
    });
  }

  void _onVolumeChanged(String value) {
    final volume = double.tryParse(value.replaceAll(',', '.'));
    if (volume == null) return;
    final densite =
        _type == _ItemType.water ? densiteEauKgParLitre : densiteGasoilKgParLitre;
    _weightController.text = (volume * densite).toStringAsFixed(1);
  }

  bool get _isLiquid => _type == _ItemType.water || _type == _ItemType.diesel;

  @override
  void dispose() {
    _labelController.dispose();
    _weightController.dispose();
    _volumeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ajouter un poste'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Passager'),
                  selected: _type == _ItemType.passenger,
                  onSelected: (_) => _selectType(_ItemType.passenger),
                ),
                ChoiceChip(
                  label: const Text('Eau'),
                  selected: _type == _ItemType.water,
                  onSelected: (_) => _selectType(_ItemType.water),
                ),
                ChoiceChip(
                  label: const Text('Gasoil'),
                  selected: _type == _ItemType.diesel,
                  onSelected: (_) => _selectType(_ItemType.diesel),
                ),
                ChoiceChip(
                  label: const Text('Gaz'),
                  selected: _type == _ItemType.gas,
                  onSelected: (_) => _selectType(_ItemType.gas),
                ),
                ChoiceChip(
                  label: const Text('Autre'),
                  selected: _type == _ItemType.other,
                  onSelected: (_) => _selectType(_ItemType.other),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _labelController,
              decoration: const InputDecoration(
                labelText: 'Libellé (ex: porte-vélos, panneau solaire...)',
              ),
            ),
            if (_isLiquid) ...[
              const SizedBox(height: 8),
              TextField(
                controller: _volumeController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: _onVolumeChanged,
                decoration: InputDecoration(
                  labelText: 'Volume (litres)',
                  helperText: _type == _ItemType.water
                      ? '1 L d\'eau = 1 kg'
                      : '1 L de gasoil ≈ 0,84 kg',
                ),
              ),
            ],
            const SizedBox(height: 8),
            TextField(
              controller: _weightController,
              enabled: !_isLiquid,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Poids (kg)',
                helperText: _isLiquid ? 'Calculé automatiquement à partir du volume' : null,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: () {
            final weight = double.tryParse(_weightController.text.replaceAll(',', '.'));
            if (_labelController.text.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Merci d\'indiquer un libellé.')),
              );
              return;
            }
            if (weight == null || weight <= 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    _isLiquid
                        ? 'Merci d\'indiquer un volume valide.'
                        : 'Merci d\'indiquer un poids valide.',
                  ),
                ),
              );
              return;
            }
            widget.onAdd(ChargeItem(
              label: _labelController.text,
              weightKg: weight,
              isPassenger: _type == _ItemType.passenger,
            ));
            Navigator.pop(context);
          },
          child: const Text('Ajouter'),
        ),
      ],
    );
  }
}
