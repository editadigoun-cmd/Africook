import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class OpenAIService {
  late final Dio _dio;
  static const String _baseUrl = 'https://api.openai.com/v1';

  OpenAIService() {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      headers: {
        'Authorization': 'Bearer ${dotenv.env['OPENAI_API_KEY']}',
        'Content-Type': 'application/json',
      },
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 60),
    ));
  }

  Future<Map<String, dynamic>> generateRecipe({
    required List<String> ingredients,
    String? budget,
    int? servings,
    String? healthMode,
    String? mealType,
    String? quickNote,
  }) async {
    final prompt = _buildRecipePrompt(
      ingredients: ingredients,
      budget: budget,
      servings: servings,
      healthMode: healthMode,
      mealType: mealType,
      quickNote: quickNote,
    );

    final response = await _dio.post('/chat/completions', data: {
      'model': 'gpt-4o',
      'messages': [
        {
          'role': 'system',
          'content':
              'Tu es un chef cuisinier africain expert, spécialisé en cuisine béninoise et africaine. Tu réponds toujours en JSON valide.',
        },
        {'role': 'user', 'content': prompt},
      ],
      'response_format': {'type': 'json_object'},
      'temperature': 0.8,
      'max_tokens': 2000,
    });

    final content =
        response.data['choices'][0]['message']['content'] as String;
    return jsonDecode(content) as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> generateWeekMenu({
    String? healthMode,
    String? budget,
    int servings = 4,
  }) async {
    final prompt = '''
Génère un menu complet pour 7 jours (petit-déjeuner, déjeuner, dîner) avec des recettes africaines et béninoises.
${healthMode != null ? 'Mode santé: $healthMode' : ''}
${budget != null ? 'Budget: $budget' : ''}
Nombre de personnes: $servings

Réponds en JSON avec la clé "menu" contenant un tableau de 7 objets,
chaque objet ayant: day (lundi à dimanche), breakfast (dict recette),
lunch (dict recette), dinner (dict recette).
Chaque recette: title, description, prep_time, difficulty.
    ''';

    final response = await _dio.post('/chat/completions', data: {
      'model': 'gpt-4o',
      'messages': [
        {
          'role': 'system',
          'content': 'Tu es un nutritionniste et chef africain expert. Réponds en JSON valide.',
        },
        {'role': 'user', 'content': prompt},
      ],
      'response_format': {'type': 'json_object'},
      'temperature': 0.7,
      'max_tokens': 3000,
    });

    final content = response.data['choices'][0]['message']['content'] as String;
    final json = jsonDecode(content) as Map<String, dynamic>;
    return (json['menu'] as List).cast<Map<String, dynamic>>();
  }

  Future<String> getCookingAdvice(String question) async {
    final response = await _dio.post('/chat/completions', data: {
      'model': 'gpt-4o',
      'messages': [
        {
          'role': 'system',
          'content':
              'Tu es un chef cuisinier africain bienveillant qui donne des conseils culinaires pratiques en français.',
        },
        {'role': 'user', 'content': question},
      ],
      'temperature': 0.7,
      'max_tokens': 500,
    });

    return response.data['choices'][0]['message']['content'] as String;
  }

  Future<Map<String, dynamic>> generateFromChip(String chip, {String? extra}) async {
    switch (chip) {
      case 'Menu de la semaine':
        final menu = await generateWeekMenu();
        return {'type': 'week_menu', 'menu': menu};
      case 'Recette rapide':
        return generateRecipe(
          ingredients: [],
          mealType: 'rapide',
          quickNote: 'Moins de 30 minutes, simple et délicieux',
        );
      case 'Je suis diabétique':
        return generateRecipe(
          ingredients: [],
          healthMode: 'diabète',
          quickNote: 'Faible indice glycémique, sans sucre ajouté',
        );
      case 'Recette sport':
        return generateRecipe(
          ingredients: [],
          healthMode: 'sport',
          quickNote: 'Riche en protéines, faible en graisses',
        );
      case 'Idée dessert':
        return generateRecipe(
          ingredients: [],
          mealType: 'dessert',
          quickNote: 'Dessert africain traditionnel ou moderne',
        );
      case 'Recette pour enfants':
        return generateRecipe(
          ingredients: [],
          mealType: 'enfant',
          quickNote: 'Adapté aux enfants, peu épicé, coloré et appétissant',
        );
      case 'Boisson africaine':
        return generateRecipe(
          ingredients: [],
          mealType: 'boisson',
          quickNote: 'Boisson traditionnelle africaine ou béninoise',
        );
      case 'Street food':
        return generateRecipe(
          ingredients: [],
          mealType: 'street food',
          quickNote: 'Snack ou plat de rue populaire en Afrique',
        );
      default:
        return generateRecipe(ingredients: [], quickNote: extra ?? chip);
    }
  }

  String _buildRecipePrompt({
    required List<String> ingredients,
    String? budget,
    int? servings,
    String? healthMode,
    String? mealType,
    String? quickNote,
  }) =>
      '''
Tu es un chef cuisinier africain expert. Génère une recette détaillée.
${ingredients.isNotEmpty ? 'Ingrédients disponibles : ${ingredients.join(', ')}' : ''}
${budget != null ? 'Budget : $budget' : ''}
${servings != null ? 'Nombre de personnes : $servings' : ''}
${healthMode != null ? 'Mode santé : $healthMode' : ''}
${mealType != null ? 'Type de repas : $mealType' : ''}
${quickNote != null ? 'Note : $quickNote' : ''}

Cuisine africaine et béninoise en priorité. Langue : français.

Réponds en JSON avec exactement ces champs :
{
  "title": "Nom de la recette",
  "description": "Description courte",
  "category": "catégorie",
  "difficulty": "Facile|Moyen|Difficile",
  "prep_time": nombre_minutes,
  "cook_time": nombre_minutes,
  "servings": nombre,
  "budget_range": "budget estimé",
  "health_tags": ["tag1","tag2"],
  "ingredients": [
    {"name": "ingrédient", "quantity": "quantité", "unit": "unité"}
  ],
  "steps": [
    {"step_number": 1, "instruction": "étape détaillée", "duration_minutes": 5}
  ],
  "nutrition": {
    "calories": 350,
    "proteins_g": 25,
    "carbs_g": 40,
    "fats_g": 12,
    "fiber_g": 5
  },
  "tips": "Conseil du chef"
}
''';
}
