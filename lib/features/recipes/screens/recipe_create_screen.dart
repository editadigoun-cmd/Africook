import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/cloudinary_service.dart';
import '../../../shared/models/recipe_model.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/widgets/primary_button.dart';

class RecipeCreateScreen extends ConsumerStatefulWidget {
  const RecipeCreateScreen({super.key});

  @override
  ConsumerState<RecipeCreateScreen> createState() => _RecipeCreateScreenState();
}

class _RecipeCreateScreenState extends ConsumerState<RecipeCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  int _step = 0;
  bool _loading = false;

  // Step 1 - Basic info
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String? _selectedCategory;
  String _difficulty = 'Facile';
  int _prepTime = 15;
  int _cookTime = 30;
  int _servings = 2;
  String _budget = 'Moins de 5000 XOF';
  String? _imageUrl;
  List<String> _healthTags = [];

  // Step 2 - Ingredients
  final List<Map<String, String>> _ingredients = [];
  final _ingNameCtrl = TextEditingController();
  final _ingQtyCtrl = TextEditingController();
  final _ingUnitCtrl = TextEditingController();

  // Step 3 - Steps + video
  final List<Map<String, String>> _steps = [];
  final _stepCtrl = TextEditingController();
  final _videoUrlCtrl = TextEditingController();

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _ingNameCtrl.dispose();
    _ingQtyCtrl.dispose();
    _ingUnitCtrl.dispose();
    _stepCtrl.dispose();
    _videoUrlCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
        source: ImageSource.gallery, imageQuality: 80);
    if (file == null) return;
    setState(() => _loading = true);
    final url = await CloudinaryService().uploadImage(file, folder: 'recipes');
    setState(() {
      _imageUrl = url;
      _loading = false;
    });
  }

  Future<void> _publish() async {
    final uid = SupabaseService.currentUserId;
    if (uid == null) return;
    setState(() => _loading = true);

    try {
      final service = ref.read(supabaseServiceProvider);
      final recipeId = await service.createRecipe({
        'author_id': uid,
        'title': _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'image_url': _imageUrl,
        'prep_time_minutes': _prepTime,
        'cook_time_minutes': _cookTime,
        'difficulty': _difficulty,
        'servings': _servings,
        'budget_range': _budget,
        'is_community': true,
        'health_tags': _healthTags,
        if (_videoUrlCtrl.text.trim().isNotEmpty)
          'video_url': _videoUrlCtrl.text.trim(),
      });

      if (_ingredients.isNotEmpty) {
        await service.insertIngredients(recipeId, _ingredients);
      }

      if (_steps.isNotEmpty) {
        final stepsData = _steps
            .asMap()
            .entries
            .map((e) => {
                  'step_number': e.key + 1,
                  'instruction': e.value['instruction']!,
                })
            .toList();
        await service.insertSteps(recipeId, stepsData);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recette publiée avec succès !'),
            backgroundColor: AppColors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Publier une recette'),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(4),
            child: LinearProgressIndicator(
              value: (_step + 1) / 3,
              backgroundColor: AppColors.divider,
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
        ),
        body: Form(
          key: _formKey,
          child: [
            _buildStep1(),
            _buildStep2(),
            _buildStep3(),
          ][_step],
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                if (_step > 0)
                  Expanded(
                    child: PrimaryButton(
                      label: 'Précédent',
                      outlined: true,
                      onPressed: () => setState(() => _step--),
                    ),
                  ),
                if (_step > 0) const SizedBox(width: 12),
                Expanded(
                  child: PrimaryButton(
                    label: _step < 2 ? 'Suivant' : 'Publier',
                    isLoading: _loading,
                    onPressed: () {
                      if (_step < 2) {
                        setState(() => _step++);
                      } else {
                        _publish();
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  Widget _buildStep1() => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Étape 1 : Informations générales',
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                  fontSize: 16)),
          const SizedBox(height: 20),

          // Image picker
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              height: 180,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(16),
                image: _imageUrl != null
                    ? DecorationImage(
                        image: NetworkImage(_imageUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: _imageUrl == null
                  ? const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate_outlined,
                            size: 40, color: AppColors.textLight),
                        SizedBox(height: 8),
                        Text('Ajouter une photo',
                            style: TextStyle(color: AppColors.textLight)),
                      ],
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _titleCtrl,
            decoration: const InputDecoration(labelText: 'Titre de la recette'),
            validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _descCtrl,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Description'),
          ),
          const SizedBox(height: 14),

          DropdownButtonFormField<String>(
            value: _difficulty,
            decoration: const InputDecoration(labelText: 'Difficulté'),
            items: const [
              DropdownMenuItem(value: 'easy', child: Text('Facile')),
              DropdownMenuItem(value: 'medium', child: Text('Moyen')),
              DropdownMenuItem(value: 'hard', child: Text('Difficile')),
            ],
            onChanged: (v) => setState(() => _difficulty = v!),
          ),
          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: _NumberField(
                  label: 'Prép. (min)',
                  value: _prepTime,
                  onChanged: (v) => setState(() => _prepTime = v),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _NumberField(
                  label: 'Cuisson (min)',
                  value: _cookTime,
                  onChanged: (v) => setState(() => _cookTime = v),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _NumberField(
                  label: 'Portions',
                  value: _servings,
                  onChanged: (v) => setState(() => _servings = v),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),
          const Text('Tags santé :',
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  fontSize: 13)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: ['végétarien', 'diabète', 'sans gluten', 'sport', 'minceur']
                .map((tag) => FilterChip(
                      label: Text(tag),
                      selected: _healthTags.contains(tag),
                      onSelected: (v) {
                        setState(() {
                          if (v) {
                            _healthTags.add(tag);
                          } else {
                            _healthTags.remove(tag);
                          }
                        });
                      },
                      selectedColor: AppColors.primary.withOpacity(0.15),
                      checkmarkColor: AppColors.primary,
                    ))
                .toList(),
          ),
        ],
      );

  Widget _buildStep2() => Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Étape 2 : Ingrédients',
                    style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                        fontSize: 16)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: _ingNameCtrl,
                        decoration:
                            const InputDecoration(hintText: 'Ingrédient'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _ingQtyCtrl,
                        decoration: const InputDecoration(hintText: 'Qté'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _ingUnitCtrl,
                        decoration: const InputDecoration(hintText: 'Unité'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        if (_ingNameCtrl.text.isEmpty) return;
                        setState(() {
                          _ingredients.add({
                            'name': _ingNameCtrl.text,
                            'quantity': _ingQtyCtrl.text,
                            'unit': _ingUnitCtrl.text,
                          });
                          _ingNameCtrl.clear();
                          _ingQtyCtrl.clear();
                          _ingUnitCtrl.clear();
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
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
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _ingredients.length,
              itemBuilder: (_, i) => ListTile(
                title: Text(_ingredients[i]['name']!),
                subtitle: Text(
                    '${_ingredients[i]['quantity']} ${_ingredients[i]['unit']}'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline,
                      color: AppColors.error),
                  onPressed: () =>
                      setState(() => _ingredients.removeAt(i)),
                ),
              ),
            ),
          ),
        ],
      );

  Widget _buildStep3() => Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Étape 3 : Instructions & Vidéo',
                    style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                        fontSize: 16)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _stepCtrl,
                        maxLines: 2,
                        decoration: const InputDecoration(
                            hintText: 'Décrivez cette étape...'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        if (_stepCtrl.text.isEmpty) return;
                        setState(() {
                          _steps.add({'instruction': _stepCtrl.text});
                          _stepCtrl.clear();
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
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
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 12),
                const Text(
                  '🎥 Vidéo (optionnel)',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _videoUrlCtrl,
                  decoration: const InputDecoration(
                    hintText: 'URL de la vidéo (YouTube, TikTok...)',
                    prefixIcon: Icon(Icons.videocam_outlined),
                  ),
                  keyboardType: TextInputType.url,
                ),
              ],
            ),
          ),
          Expanded(
            child: ReorderableListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _steps.length,
              onReorder: (oldIdx, newIdx) {
                setState(() {
                  if (newIdx > oldIdx) newIdx--;
                  final item = _steps.removeAt(oldIdx);
                  _steps.insert(newIdx, item);
                });
              },
              itemBuilder: (_, i) => ListTile(
                key: ValueKey(i),
                leading: CircleAvatar(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  child: Text('${i + 1}'),
                ),
                title: Text(_steps[i]['instruction']!,
                    style: const TextStyle(fontFamily: 'Nunito', fontSize: 13)),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline,
                      color: AppColors.error),
                  onPressed: () => setState(() => _steps.removeAt(i)),
                ),
              ),
            ),
          ),
        ],
      );
}

class _NumberField extends StatelessWidget {
  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  const _NumberField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => TextFormField(
        initialValue: '$value',
        keyboardType: TextInputType.number,
        decoration: InputDecoration(labelText: label),
        onChanged: (v) => onChanged(int.tryParse(v) ?? value),
      );
}
