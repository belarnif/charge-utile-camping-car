import 'package:flutter/material.dart';
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
  final List<ChargeItem> _items = [];

  final _ptacController = TextEditingController();
  final _pvomController = TextEditingController();
  final _nameController = TextEditingController();
  final _placesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSavedVehicle();
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
        onAdd: (item) => setState(() => _items.add(item)),
      ),
    );
  }

  void _removeItem(int index) {
    setState(() => _items.removeAt(index));
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
      appBar: AppBar(title: const Text('Charge utile camping-car')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildVehicleForm(),
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
                label: const Text('Ajouter un poste (passager, option...)'),
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

class _AddItemDialog extends StatefulWidget {
  final void Function(ChargeItem) onAdd;
  const _AddItemDialog({required this.onAdd});

  @override
  State<_AddItemDialog> createState() => _AddItemDialogState();
}

class _AddItemDialogState extends State<_AddItemDialog> {
  final _labelController = TextEditingController();
  final _weightController = TextEditingController();
  bool _isPassenger = false;

  static const double poidsPassagerStandard = 75;

  @override
  void initState() {
    super.initState();
    _weightController.text = poidsPassagerStandard.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _labelController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ajouter un poste'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Passager (75 kg par défaut)'),
            value: _isPassenger,
            onChanged: (value) {
              setState(() {
                _isPassenger = value;
                if (value) {
                  _labelController.text = 'Passager';
                  _weightController.text = poidsPassagerStandard.toStringAsFixed(0);
                }
              });
            },
          ),
          TextField(
            controller: _labelController,
            decoration: const InputDecoration(
              labelText: 'Libellé (ex: porte-vélos, panneau solaire...)',
            ),
          ),
          TextField(
            controller: _weightController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Poids (kg)'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: () {
            final weight = double.tryParse(_weightController.text.replaceAll(',', '.'));
            if (weight == null || weight <= 0 || _labelController.text.isEmpty) return;
            widget.onAdd(ChargeItem(
              label: _labelController.text,
              weightKg: weight,
              isPassenger: _isPassenger,
            ));
            Navigator.pop(context);
          },
          child: const Text('Ajouter'),
        ),
      ],
    );
  }
}
