class AppStrings {
  // App
  static const String appName = 'Africook';
  static const String tagline = 'Cuisinez. Partagez. Régalez-vous.';

  // Onboarding
  static const List<Map<String, String>> onboardingSlides = [
    {
      'title': 'Bienvenue sur Africook',
      'subtitle': 'Votre assistant culinaire africain intelligent',
    },
    {
      'title': 'Recettes Authentiques',
      'subtitle': 'Découvrez des centaines de recettes béninoises et africaines',
    },
    {
      'title': 'IA Chef Personnalisé',
      'subtitle': 'Générez des recettes avec vos ingrédients disponibles',
    },
    {
      'title': 'Commandez en Ligne',
      'subtitle': 'Des plats préparés ou des ingrédients livrés chez vous',
    },
    {
      'title': 'Communauté Culinaire',
      'subtitle': 'Partagez vos créations et connectez-vous avec des chefs',
    },
  ];

  // Auth
  static const String login = 'Connexion';
  static const String register = "S'inscrire";
  static const String email = 'Email';
  static const String phone = 'Téléphone';
  static const String password = 'Mot de passe';
  static const String forgotPassword = 'Mot de passe oublié ?';
  static const String noAccount = "Pas encore de compte ? ";
  static const String hasAccount = 'Déjà un compte ? ';
  static const String fullName = 'Nom complet';
  static const String confirmPassword = 'Confirmer le mot de passe';

  // Navigation
  static const String home = 'Accueil';
  static const String recipes = 'Recettes';
  static const String aiChef = 'IA Chef';
  static const String orders = 'Commandes';
  static const String profile = 'Profil';

  // Home
  static const String goodMorning = 'Bonjour';
  static const String goodAfternoon = 'Bon après-midi';
  static const String goodEvening = 'Bonsoir';
  static const String searchHint = 'Rechercher une recette...';
  static const String popularThisWeek = 'Populaires cette semaine';
  static const String newVideos = 'Nouvelles vidéos';
  static const String aiSuggestions = 'Suggestions IA pour vous';
  static const String seeAll = 'Voir tout';

  // Categories
  static const List<Map<String, String>> categories = [
    // Cuisine africaine
    {'name': 'Béninoises', 'emoji': '🇧🇯', 'slug': 'beninoise'},
    {'name': 'Africaines', 'emoji': '🌍', 'slug': 'africaine'},
    {'name': 'Sénégalaise', 'emoji': '🇸🇳', 'slug': 'senegalaise'},
    {'name': 'Ivoirienne', 'emoji': '🇨🇮', 'slug': 'ivoirienne'},
    {'name': 'Ghanéenne', 'emoji': '🇬🇭', 'slug': 'ghaneenne'},
    {'name': 'Nigériane', 'emoji': '🇳🇬', 'slug': 'nigeriane'},
    {'name': 'Camerounaise', 'emoji': '🇨🇲', 'slug': 'camerounaise'},
    {'name': 'Maghrébine', 'emoji': '🌙', 'slug': 'maghrebine'},
    {'name': 'Asiatique fusion', 'emoji': '🥢', 'slug': 'asiatique'},
    // Protéines
    {'name': 'Poissons & Fruits de mer', 'emoji': '🐟', 'slug': 'poisson'},
    {'name': 'Viandes & Grillades', 'emoji': '🥩', 'slug': 'viande'},
    {'name': 'Volailles', 'emoji': '🍗', 'slug': 'volaille'},
    {'name': 'Végétariennes', 'emoji': '🥗', 'slug': 'vegetarienne'},
    {'name': 'Vegan', 'emoji': '🌱', 'slug': 'vegan'},
    {'name': 'Légumineuses', 'emoji': '🫘', 'slug': 'legumineuse'},
    // Féculents & bases
    {'name': 'Riz & Céréales', 'emoji': '🍚', 'slug': 'riz'},
    {'name': 'Pâtes & Fufu', 'emoji': '🍝', 'slug': 'pate-fufu'},
    {'name': 'Ignames & Tubercules', 'emoji': '🍠', 'slug': 'igname'},
    {'name': 'Plantains & Bananes', 'emoji': '🍌', 'slug': 'plantain'},
    {'name': 'Pain & Viennoiseries', 'emoji': '🍞', 'slug': 'pain'},
    // Plats & préparations
    {'name': 'Soupes & Sauces', 'emoji': '🥘', 'slug': 'soupe'},
    {'name': 'Grillades & Brochettes', 'emoji': '🔥', 'slug': 'grillade'},
    {'name': 'Mijotés & Ragoûts', 'emoji': '🫕', 'slug': 'mijote'},
    {'name': 'Fritures', 'emoji': '🍳', 'slug': 'friture'},
    {'name': 'Recettes vapeur', 'emoji': '♨️', 'slug': 'vapeur'},
    {'name': 'Recettes au four', 'emoji': '🫙', 'slug': 'four'},
    {'name': 'Street food & Snacks', 'emoji': '🍢', 'slug': 'street-food'},
    {'name': 'Beignets & Frits', 'emoji': '🧆', 'slug': 'beignet'},
    // Repas du jour
    {'name': 'Petit-déjeuner', 'emoji': '🥣', 'slug': 'petit-dejeuner'},
    {'name': 'Bouillies & Porridges', 'emoji': '🥛', 'slug': 'bouillie'},
    {'name': 'Salades & Crudités', 'emoji': '🥙', 'slug': 'salade'},
    // Boissons
    {'name': 'Boissons traditionnelles', 'emoji': '🍵', 'slug': 'boisson-traditionnelle'},
    {'name': 'Jus de fruits', 'emoji': '🍊', 'slug': 'jus-de-fruits'},
    {'name': 'Smoothies & Shakes', 'emoji': '🥤', 'slug': 'smoothie'},
    {'name': 'Boissons chaudes', 'emoji': '☕', 'slug': 'boisson-chaude'},
    {'name': 'Cocktails & Mocktails', 'emoji': '🍹', 'slug': 'cocktail'},
    {'name': 'Boissons fermentées', 'emoji': '🫗', 'slug': 'boisson-fermentee'},
    // Desserts & sucreries
    {'name': 'Pâtisseries & Gâteaux', 'emoji': '🎂', 'slug': 'patisserie'},
    {'name': 'Desserts & Sucreries', 'emoji': '🍰', 'slug': 'dessert'},
    {'name': 'Glaces & Sorbets', 'emoji': '🍦', 'slug': 'glace'},
    // Santé & régimes
    {'name': 'Sans gluten', 'emoji': '🌾', 'slug': 'sans-gluten'},
    {'name': 'Protéiné', 'emoji': '💪', 'slug': 'proteine'},
    {'name': 'Léger & Diététique', 'emoji': '🩺', 'slug': 'dietetique'},
    {'name': 'Enfants & Bébés', 'emoji': '🧒', 'slug': 'enfant'},
    // Occasions & pratique
    {'name': 'Fêtes & Cérémonies', 'emoji': '🎉', 'slug': 'fete'},
    {'name': 'Ramadan & Jeûne', 'emoji': '🌙', 'slug': 'ramadan'},
    {'name': 'Repas rapides (< 30 min)', 'emoji': '⚡', 'slug': 'rapide'},
    {'name': 'Batch cooking', 'emoji': '📦', 'slug': 'batch-cooking'},
    {'name': 'Économiques', 'emoji': '💰', 'slug': 'economique'},
    // Condiments
    {'name': 'Condiments & Épices', 'emoji': '🌶️', 'slug': 'condiment'},
    {'name': 'Conserves & Marinades', 'emoji': '🫙', 'slug': 'conserve'},
  ];

  // AI Chef chips
  static const List<String> aiChips = [
    "J'ai ces ingrédients",
    'Menu de la semaine',
    'Petit budget',
    'Recette rapide',
    'Mode santé',
    'Je suis diabétique',
    'Recette sport',
    'Repas familial',
    'Idée dessert',
    'Recette pour enfants',
    'Boisson africaine',
    'Street food',
  ];

  // Errors
  static const String networkError = 'Erreur de connexion. Vérifiez votre internet.';
  static const String genericError = 'Une erreur est survenue. Réessayez.';
  static const String invalidEmail = 'Email invalide';
  static const String passwordTooShort = 'Mot de passe trop court (min. 6 caractères)';
  static const String passwordMismatch = 'Les mots de passe ne correspondent pas';
}
