import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/openai_service.dart';
import '../../../core/services/supabase_service.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/widgets/primary_button.dart';

enum _ScanState { idle, picked, detecting, done, error }

class IngredientScannerScreen extends ConsumerStatefulWidget {
  const IngredientScannerScreen({super.key});

  @override
  ConsumerState<IngredientScannerScreen> createState() =>
      _IngredientScannerScreenState();
}

class _IngredientScannerScreenState
    extends ConsumerState<IngredientScannerScreen> {
  _ScanState _state = _ScanState.idle;
  Uint8List? _imageBytes;
  List<String> _detected = [];
  bool _generating = false;
  String? _errorMsg;

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final xfile = await picker.pickImage(
      source: source,
      imageQuality: 70,
      maxWidth: 1024,
    );
    if (xfile == null) return;
    final bytes = await xfile.readAsBytes();
    setState(() {
      _imageBytes = bytes;
      _state = _ScanState.picked;
      _detected = [];
      _errorMsg = null;
    });
  }

  Future<void> _detectIngredients() async {
    if (_imageBytes == null) return;
    setState(() => _state = _ScanState.detecting);
    try {
      final ingredients =
          await OpenAIService().detectIngredientsFromImage(_imageBytes!);
      setState(() {
        _detected = ingredients;
        _state = _ScanState.done;
      });
    } catch (e) {
      setState(() {
        _errorMsg = e.toString();
        _state = _ScanState.error;
      });
    }
  }

  Future<void> _generateRecipe() async {
    if (_detected.isEmpty) return;
    setState(() => _generating = true);
    try {
      final result = await OpenAIService().generateRecipe(
        ingredients: _detected,
        servings: 4,
      );
      final uid = SupabaseService.currentUserId;
      if (uid != null) {
        await ref.read(supabaseServiceProvider).saveAiGeneration(
              userId: uid,
              ingredientsInput: _detected.join(', '),
              promptUsed: 'scanner',
              result: result,
            );
      }
      if (mounted) {
        context.push('/ai-chef', extra: result);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  void _removeIngredient(int index) {
    setState(() => _detected.removeAt(index));
  }

  void _addIngredient(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty || _detected.contains(trimmed)) return;
    setState(() => _detected.add(trimmed));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Scanner les ingrédients'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildImageArea(),
            const SizedBox(height: 20),
            if (_state == _ScanState.picked)
              PrimaryButton(
                label: '🔍 Détecter les ingrédients',
                onPressed: _detectIngredients,
              ),
            if (_state == _ScanState.detecting)
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(color: AppColors.primary),
                    SizedBox(height: 12),
                    Text('Analyse de l\'image en cours…',
                        style: TextStyle(color: AppColors.textLight)),
                  ],
                ),
              ),
            if (_state == _ScanState.error)
              Text('Erreur : $_errorMsg',
                  style: const TextStyle(color: AppColors.error)),
            if (_state == _ScanState.done) ...[
              _buildDetectedList(),
              const SizedBox(height: 16),
              _AddIngredientField(onAdd: _addIngredient),
              const SizedBox(height: 20),
              _generating
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.primary))
                  : PrimaryButton(
                      label: '🍳 Générer une recette',
                      onPressed: _detected.isEmpty ? null : _generateRecipe,
                    ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildImageArea() {
    return GestureDetector(
      onTap: _state == _ScanState.idle ? () => _showSourcePicker() : null,
      child: Container(
        height: 240,
        decoration: BoxDecoration(
          color: AppColors.divider.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: AppColors.primary.withOpacity(0.4), width: 1.5),
        ),
        child: _imageBytes != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.memory(_imageBytes!, fit: BoxFit.cover,
                    width: double.infinity),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.camera_alt_outlined,
                      size: 56, color: AppColors.primary.withOpacity(0.6)),
                  const SizedBox(height: 12),
                  const Text(
                    'Photographiez votre frigo ou vos placards',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 14,
                        color: AppColors.textLight),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _SourceButton(
                        icon: Icons.camera_alt,
                        label: 'Caméra',
                        onTap: () => _pickImage(ImageSource.camera),
                      ),
                      const SizedBox(width: 16),
                      _SourceButton(
                        icon: Icons.photo_library_outlined,
                        label: 'Galerie',
                        onTap: () => _pickImage(ImageSource.gallery),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }

  void _showSourcePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.primary),
              title: const Text('Prendre une photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined,
                  color: AppColors.primary),
              title: const Text('Choisir depuis la galerie'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetectedList() {
    if (_detected.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.yellow.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.yellow),
        ),
        child: const Text(
          'Aucun ingrédient détecté. Ajoutez-en manuellement ci-dessous.',
          style: TextStyle(
              fontFamily: 'Nunito', fontSize: 13, color: AppColors.brown),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${_detected.length} ingrédient(s) détecté(s)',
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
            fontSize: 15,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _detected.asMap().entries.map((e) {
            return Chip(
              label: Text(e.value,
                  style: const TextStyle(fontFamily: 'Nunito', fontSize: 13)),
              backgroundColor: AppColors.primary.withOpacity(0.1),
              side: BorderSide(color: AppColors.primary.withOpacity(0.3)),
              deleteIcon: const Icon(Icons.close, size: 14),
              onDeleted: () => _removeIngredient(e.key),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _SourceButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SourceButton(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.primary, size: 26),
            ),
            const SizedBox(height: 6),
            Text(label,
                style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 12,
                    color: AppColors.textLight)),
          ],
        ),
      );
}

class _AddIngredientField extends StatefulWidget {
  final ValueChanged<String> onAdd;

  const _AddIngredientField({required this.onAdd});

  @override
  State<_AddIngredientField> createState() => _AddIngredientFieldState();
}

class _AddIngredientFieldState extends State<_AddIngredientField> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _submit() {
    widget.onAdd(_ctrl.text);
    _ctrl.clear();
  }

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
            child: TextField(
              controller: _ctrl,
              decoration: const InputDecoration(
                hintText: 'Ajouter un ingrédient manuellement…',
                prefixIcon: Icon(Icons.add),
              ),
              onSubmitted: (_) => _submit(),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _submit,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, color: Colors.white),
            ),
          ),
        ],
      );
}
