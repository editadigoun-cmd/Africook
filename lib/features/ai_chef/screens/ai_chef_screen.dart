import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/services/openai_service.dart';
import '../../../core/services/supabase_service.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/widgets/primary_button.dart';

final _aiLoadingProvider = StateProvider<bool>((ref) => false);
final _aiResultProvider = StateProvider<Map<String, dynamic>?>((ref) => null);
final _aiModeProvider = StateProvider<String>((ref) => 'ingredients');

class AiChefScreen extends ConsumerStatefulWidget {
  const AiChefScreen({super.key});

  @override
  ConsumerState<AiChefScreen> createState() => _AiChefScreenState();
}

class _AiChefScreenState extends ConsumerState<AiChefScreen> {
  final _ingredientCtrl = TextEditingController();
  final List<String> _ingredients = [];
  final _chatCtrl = TextEditingController();
  final List<Map<String, String>> _chatMessages = [];
  String _selectedHealthMode = '';
  String _selectedBudget = '';

  @override
  void dispose() {
    _ingredientCtrl.dispose();
    _chatCtrl.dispose();
    super.dispose();
  }

  Future<void> _generateFromIngredients() async {
    if (_ingredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Ajoutez au moins un ingrédient")),
      );
      return;
    }
    ref.read(_aiLoadingProvider.notifier).state = true;
    ref.read(_aiResultProvider.notifier).state = null;

    try {
      final result = await OpenAIService().generateRecipe(
        ingredients: _ingredients,
        healthMode:
            _selectedHealthMode.isEmpty ? null : _selectedHealthMode,
        budget: _selectedBudget.isEmpty ? null : _selectedBudget,
        servings: 4,
      );
      ref.read(_aiResultProvider.notifier).state = result;
      _saveToHistory(result);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur IA : $e')),
        );
      }
    } finally {
      ref.read(_aiLoadingProvider.notifier).state = false;
    }
  }

  Future<void> _generateFromChip(String chip) async {
    ref.read(_aiLoadingProvider.notifier).state = true;
    ref.read(_aiResultProvider.notifier).state = null;

    try {
      final result = await OpenAIService().generateFromChip(chip);
      ref.read(_aiResultProvider.notifier).state = result;
      if (result['type'] != 'week_menu') _saveToHistory(result);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur IA : $e')),
        );
      }
    } finally {
      ref.read(_aiLoadingProvider.notifier).state = false;
    }
  }

  Future<void> _sendChatMessage() async {
    final msg = _chatCtrl.text.trim();
    if (msg.isEmpty) return;
    _chatCtrl.clear();
    setState(() {
      _chatMessages.add({'role': 'user', 'content': msg});
    });

    try {
      final answer = await OpenAIService().getCookingAdvice(msg);
      setState(() {
        _chatMessages.add({'role': 'assistant', 'content': answer});
      });
    } catch (e) {
      setState(() {
        _chatMessages.add({
          'role': 'assistant',
          'content': 'Désolé, une erreur est survenue. Réessayez.',
        });
      });
    }
  }

  Future<void> _saveToHistory(Map<String, dynamic> result) async {
    final uid = SupabaseService.currentUserId;
    if (uid == null) return;
    await ref.read(supabaseServiceProvider).saveAiGeneration(
          userId: uid,
          ingredientsInput: _ingredients.join(', '),
          promptUsed: 'ingredients',
          result: result,
        );
  }

  Future<void> _saveRecipe(Map<String, dynamic> result) async {
    final uid = SupabaseService.currentUserId;
    if (uid == null) return;

    try {
      final service = ref.read(supabaseServiceProvider);
      await service.createRecipe({
        'author_id': uid,
        'title': result['title'],
        'description': result['description'],
        'prep_time_minutes': result['prep_time'],
        'cook_time_minutes': result['cook_time'],
        'difficulty': result['difficulty'],
        'servings': result['servings'] ?? 4,
        'budget_range': result['budget_range'],
        'is_ai_generated': true,
        'health_tags': result['health_tags'] ?? [],
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recette sauvegardée !'),
            backgroundColor: AppColors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(_aiLoadingProvider);
    final result = ref.watch(_aiResultProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 120,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1F2937), Color(0xFF374151)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(20, 56, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: const [
                    Text(
                      '✨ IA Chef',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                        fontSize: 24,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Votre assistant culinaire africain intelligent',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        color: Colors.white54,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Quick chips
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    'Démarrage rapide',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
                SizedBox(
                  height: 44,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: AppStrings.aiChips.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final chip = AppStrings.aiChips[i];
                      return GestureDetector(
                        onTap: () => _generateFromChip(chip),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: Text(
                            chip,
                            style: const TextStyle(
                              color: Colors.white,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 20),

                // Ingredients input
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Mes ingrédients disponibles",
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _ingredientCtrl,
                              decoration: const InputDecoration(
                                hintText: "Ex : tomate, oignon, poisson...",
                                prefixIcon: Icon(Icons.eco_outlined),
                              ),
                              onSubmitted: (v) {
                                if (v.trim().isNotEmpty) {
                                  setState(() {
                                    _ingredients.add(v.trim());
                                    _ingredientCtrl.clear();
                                  });
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () {
                              final v = _ingredientCtrl.text.trim();
                              if (v.isNotEmpty) {
                                setState(() {
                                  _ingredients.add(v);
                                  _ingredientCtrl.clear();
                                });
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.add,
                                  color: Colors.white, size: 20),
                            ),
                          ),
                        ],
                      ),

                      if (_ingredients.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: _ingredients
                              .map((ing) => Chip(
                                    label: Text(ing),
                                    deleteIcon: const Icon(Icons.close, size: 14),
                                    onDeleted: () => setState(
                                        () => _ingredients.remove(ing)),
                                    backgroundColor:
                                        AppColors.primary.withOpacity(0.1),
                                    labelStyle: const TextStyle(
                                      color: AppColors.primary,
                                      fontFamily: 'Nunito',
                                      fontSize: 12,
                                    ),
                                  ))
                              .toList(),
                        ),
                      ],

                      const SizedBox(height: 12),

                      // Options
                      Row(
                        children: [
                          Expanded(
                            child: _SmallSelect(
                              value: _selectedHealthMode,
                              hint: 'Mode santé',
                              options: const [
                                '',
                                'diabète',
                                'végétarien',
                                'sport',
                                'minceur'
                              ],
                              labels: const [
                                'Aucun',
                                'Diabète',
                                'Végétarien',
                                'Sport',
                                'Minceur'
                              ],
                              onChanged: (v) =>
                                  setState(() => _selectedHealthMode = v),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _SmallSelect(
                              value: _selectedBudget,
                              hint: 'Budget',
                              options: const [
                                '',
                                '< 2000 XOF',
                                '< 5000 XOF',
                                '< 10000 XOF'
                              ],
                              labels: const [
                                'Aucun',
                                'Moins de 2000',
                                'Moins de 5000',
                                'Moins de 10000'
                              ],
                              onChanged: (v) =>
                                  setState(() => _selectedBudget = v),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),
                      PrimaryButton(
                        label: '✨ Générer une recette',
                        onPressed: _generateFromIngredients,
                        isLoading: isLoading,
                        icon: isLoading ? null : Icons.auto_awesome,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Loading indicator
                if (isLoading)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Column(
                      children: [
                        CircularProgressIndicator(color: AppColors.primary),
                        SizedBox(height: 16),
                        Text(
                          "L'IA prépare votre recette...",
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            color: AppColors.textLight,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Result
                if (result != null && !isLoading)
                  _AIResultCard(
                    result: result,
                    onSave: () => _saveRecipe(result),
                  ).animate().fadeIn().slideY(begin: 0.2),

                // Chat section
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
                  child: Text(
                    '💬 Conseils culinaires',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),

                if (_chatMessages.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.divider),
                    ),
                    constraints: const BoxConstraints(maxHeight: 300),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(12),
                      shrinkWrap: true,
                      itemCount: _chatMessages.length,
                      itemBuilder: (_, i) {
                        final msg = _chatMessages[i];
                        final isUser = msg['role'] == 'user';
                        return Align(
                          alignment: isUser
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            constraints: BoxConstraints(
                              maxWidth:
                                  MediaQuery.of(context).size.width * 0.75,
                            ),
                            decoration: BoxDecoration(
                              color: isUser
                                  ? AppColors.primary
                                  : AppColors.background,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              msg['content']!,
                              style: TextStyle(
                                color: isUser
                                    ? Colors.white
                                    : AppColors.textDark,
                                fontFamily: 'Nunito',
                                fontSize: 13,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _chatCtrl,
                          decoration: const InputDecoration(
                            hintText: 'Posez une question culinaire...',
                            prefixIcon: Icon(Icons.chat_outlined),
                          ),
                          onSubmitted: (_) => _sendChatMessage(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _sendChatMessage,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.send,
                              color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AIResultCard extends StatelessWidget {
  final Map<String, dynamic> result;
  final VoidCallback onSave;

  const _AIResultCard({required this.result, required this.onSave});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome,
                      color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Recette générée par IA',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: onSave,
                    child: const Icon(Icons.bookmark_border,
                        color: Colors.white),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    result['title'] ?? 'Recette africaine',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (result['description'] != null)
                    Text(
                      result['description'],
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        color: AppColors.textLight,
                        fontSize: 13,
                      ),
                    ),
                  const SizedBox(height: 12),

                  // Quick stats
                  Row(
                    children: [
                      _Stat('⏱️', '${result['prep_time'] ?? 0} min', 'Prép.'),
                      _Stat('🔥', '${result['cook_time'] ?? 0} min', 'Cuisson'),
                      _Stat('📊', result['difficulty'] ?? '-', 'Niveau'),
                    ],
                  ),

                  const SizedBox(height: 16),

                  if (result['ingredients'] != null) ...[
                    const Text(
                      'Ingrédients :',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ...(result['ingredients'] as List).take(5).map(
                          (ing) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              children: [
                                const Text('• ',
                                    style: TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w700)),
                                Expanded(
                                  child: Text(
                                    '${ing['name']} — ${ing['quantity'] ?? ''} ${ing['unit'] ?? ''}',
                                    style: const TextStyle(
                                      fontFamily: 'Nunito',
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    if ((result['ingredients'] as List).length > 5)
                      Text(
                        '+ ${(result['ingredients'] as List).length - 5} autres ingrédients',
                        style: const TextStyle(
                          color: AppColors.textLight,
                          fontSize: 12,
                          fontFamily: 'Nunito',
                        ),
                      ),
                  ],

                  if (result['tips'] != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.yellow.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border:
                            Border.all(color: AppColors.yellow.withOpacity(0.3)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('💡 ', style: TextStyle(fontSize: 16)),
                          Expanded(
                            child: Text(
                              result['tips'],
                              style: const TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 13,
                                color: AppColors.brown,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),
                  PrimaryButton(
                    label: '💾 Sauvegarder cette recette',
                    onPressed: onSave,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _Stat extends StatelessWidget {
  final String emoji;
  final String value;
  final String label;

  const _Stat(this.emoji, this.value, this.label);

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            Text(
              value,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: AppColors.textDark,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 11,
                color: AppColors.textLight,
              ),
            ),
          ],
        ),
      );
}

class _SmallSelect extends StatelessWidget {
  final String value;
  final String hint;
  final List<String> options;
  final List<String> labels;
  final ValueChanged<String> onChanged;

  const _SmallSelect({
    required this.value,
    required this.hint,
    required this.options,
    required this.labels,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.divider),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            hint: Text(hint,
                style:
                    const TextStyle(fontSize: 12, color: AppColors.textLight)),
            items: List.generate(
              options.length,
              (i) => DropdownMenuItem(
                value: options[i],
                child: Text(
                  labels[i],
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            onChanged: (v) => onChanged(v ?? ''),
            style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 12,
                color: AppColors.textDark),
            icon: const Icon(Icons.keyboard_arrow_down,
                size: 16, color: AppColors.textLight),
            isDense: true,
          ),
        ),
      );
}
