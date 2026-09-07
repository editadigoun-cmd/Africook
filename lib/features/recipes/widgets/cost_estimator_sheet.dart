import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/price_service.dart';
import '../../../shared/models/recipe_model.dart';

Future<void> showCostEstimator(
    BuildContext context, RecipeModel recipe) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => _CostSheet(recipe: recipe),
  );
}

class _CostSheet extends StatefulWidget {
  final RecipeModel recipe;
  const _CostSheet({required this.recipe});

  @override
  State<_CostSheet> createState() => _CostSheetState();
}

class _CostSheetState extends State<_CostSheet> {
  final _service = PriceService();
  List<IngredientCost>? _costs;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final items = widget.recipe.ingredients.map((ing) => (
          name: ing.name,
          quantity: ing.quantity,
          unit: ing.unit,
        )).toList();
    final costs = await _service.estimateCost(items);
    if (mounted) setState(() { _costs = costs; _loading = false; });
  }

  int get _total => _costs?.fold<int>(0, (s, c) => s + (c.totalXof ?? 0)) ?? 0;
  int get _known => _costs?.where((c) => c.totalXof != null).length ?? 0;

  String _fmt(int xof) {
    if (xof >= 1000) {
      return '${(xof / 1000).toStringAsFixed(xof % 1000 == 0 ? 0 : 1)} k';
    }
    return '$xof';
  }

  Future<void> _editPrice(IngredientCost cost) async {
    final ctrl = TextEditingController(
        text: cost.unitPriceXof?.toString() ?? '');
    final result = await showDialog<int>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Prix de "${cost.name}"',
            style: const TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
                fontSize: 15)),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Prix unitaire en XOF',
            suffixText: 'XOF',
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler')),
          TextButton(
            onPressed: () {
              final v = int.tryParse(ctrl.text);
              Navigator.pop(context, v);
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
    if (result != null) {
      await _service.savePrice(cost.name, result);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxH = MediaQuery.of(context).size.height * 0.85;
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxH),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                const Text(
                  '💰 Estimation du coût',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                    color: AppColors.textDark,
                  ),
                ),
                const Spacer(),
                Text(
                  '${widget.recipe.servings} portions',
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 12,
                    color: AppColors.textLight,
                  ),
                ),
              ],
            ),
          ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          else ...[
            Flexible(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shrinkWrap: true,
                itemCount: _costs!.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, indent: 16),
                itemBuilder: (_, i) {
                  final c = _costs![i];
                  return ListTile(
                    dense: true,
                    title: Text(
                      c.name,
                      style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 14,
                          color: AppColors.textDark),
                    ),
                    subtitle: Text(
                      '${c.quantity ?? ''} ${c.unit ?? ''}'.trim().isEmpty
                          ? '1 unité'
                          : '${c.quantity ?? ''} ${c.unit ?? ''}'.trim(),
                      style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 12,
                          color: AppColors.textLight),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        c.totalXof != null
                            ? Text(
                                '~${_fmt(c.totalXof!)} XOF',
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: AppColors.primary,
                                ),
                              )
                            : const Text(
                                '? XOF',
                                style: TextStyle(
                                    fontFamily: 'Nunito',
                                    fontSize: 13,
                                    color: AppColors.textLight),
                              ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () => _editPrice(c),
                          child: const Icon(Icons.edit_outlined,
                              size: 16, color: AppColors.textLight),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            // Total
            Container(
              margin: const EdgeInsets.all(16),
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, Color(0xFF2d6a4f)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Coût total estimé',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                        Text(
                          'Prix du marché local',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 11,
                            color: Colors.white38,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${_total.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ')} XOF',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w800,
                          fontSize: 22,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '$_known / ${_costs!.length} prix connus',
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 11,
                          color: Colors.white60,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).padding.bottom + 8,
                  left: 16,
                  right: 16),
              child: Text(
                'Tapez ✏️ sur un ingrédient pour ajuster son prix. Les prix sont sauvegardés localement.',
                style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 11,
                    color: AppColors.textLight),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
