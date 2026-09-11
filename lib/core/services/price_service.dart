import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

// Default prices in XOF for common West African / Beninese ingredients (per unit)
const _defaultPrices = {
  // Viandes & poissons
  'poulet': 2500,
  'bœuf': 3500,
  'porc': 3000,
  'mouton': 4000,
  'poisson': 1500,
  'crevettes': 3000,
  'tilapia': 1200,
  'capitaine': 2000,
  // Légumes
  'tomate': 150,
  'oignon': 100,
  'ail': 50,
  'gingembre': 50,
  'piment': 50,
  'poivron': 200,
  'gombo': 200,
  'épinard': 300,
  'aubergine': 250,
  'courgette': 200,
  'carotte': 150,
  'chou': 300,
  'haricot vert': 400,
  'concombre': 150,
  // Féculents
  'riz': 400,
  'maïs': 200,
  'igname': 500,
  'manioc': 300,
  'patate douce': 250,
  'plantain': 300,
  'banane plantain': 300,
  'farine': 350,
  'farine de maïs': 300,
  'semoule': 400,
  // Légumineuses
  'haricot': 400,
  'niébé': 350,
  'arachide': 300,
  'lentilles': 500,
  // Huiles & condiments
  'huile de palme': 500,
  "huile d'arachide": 600,
  'huile végétale': 500,
  'sel': 50,
  'poivre': 100,
  'cube maggi': 50,
  'bouillon': 50,
  // Produits laitiers
  'œuf': 100,
  'lait': 400,
  'beurre': 600,
  // Épices africaines
  'soumbala': 200,
  'dawadawa': 200,
  'noix de muscade': 150,
  'cannelle': 150,
  'cumin': 150,
  'coriandre': 100,
  'curry': 150,
  'paprika': 150,
  // Autres
  'sucre': 300,
  'tomate concentrée': 200,
  'lait de coco': 500,
  'citron': 100,
};

class PriceService {
  static const _prefsKey = 'ingredient_prices_xof';

  Future<Map<String, int>> _loadCustomPrices() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null) return {};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map((k, v) => MapEntry(k, v as int));
    } catch (_) {
      return {};
    }
  }

  Future<void> savePrice(String ingredient, int priceXof) async {
    final prefs = await SharedPreferences.getInstance();
    final custom = await _loadCustomPrices();
    custom[ingredient.toLowerCase()] = priceXof;
    await prefs.setString(_prefsKey, jsonEncode(custom));
  }

  Future<int?> getPrice(String ingredient) async {
    final key = ingredient.toLowerCase();
    final custom = await _loadCustomPrices();
    if (custom.containsKey(key)) return custom[key];
    // fuzzy match against defaults
    for (final entry in _defaultPrices.entries) {
      if (key.contains(entry.key) || entry.key.contains(key)) {
        return entry.value;
      }
    }
    return null;
  }

  Future<List<IngredientCost>> estimateCost(
      List<({String name, String? quantity, String? unit})> ingredients) async {
    final custom = await _loadCustomPrices();
    return ingredients.map((ing) {
      final key = ing.name.toLowerCase();
      int? unitPrice;
      // custom first
      for (final e in custom.entries) {
        if (key.contains(e.key) || e.key.contains(key)) {
          unitPrice = e.value;
          break;
        }
      }
      // then defaults
      if (unitPrice == null) {
        for (final e in _defaultPrices.entries) {
          if (key.contains(e.key) || e.key.contains(e.key)) {
            unitPrice = e.value;
            break;
          }
        }
        // second pass: exact substring
        if (unitPrice == null) {
          for (final e in _defaultPrices.entries) {
            if (key.contains(e.key)) {
              unitPrice = e.value;
              break;
            }
          }
        }
      }
      final qty = double.tryParse(ing.quantity ?? '1') ?? 1;
      final estimated = unitPrice != null ? (unitPrice * qty).round() as int : null;
      return IngredientCost(
        name: ing.name,
        quantity: ing.quantity,
        unit: ing.unit,
        unitPriceXof: unitPrice,
        totalXof: estimated,
      );
    }).toList();
  }
}

class IngredientCost {
  final String name;
  final String? quantity;
  final String? unit;
  final int? unitPriceXof;
  final int? totalXof;

  IngredientCost({
    required this.name,
    this.quantity,
    this.unit,
    this.unitPriceXof,
    this.totalXof,
  });
}
