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
    {'name': 'Béninoises', 'emoji': '🇧🇯', 'slug': 'beninoise'},
    {'name': 'Africaines', 'emoji': '🌍', 'slug': 'africaine'},
    {'name': 'Internationales', 'emoji': '🌐', 'slug': 'internationale'},
    {'name': 'Végétariennes', 'emoji': '🥗', 'slug': 'vegetarienne'},
    {'name': 'Poissons & Fruits de mer', 'emoji': '🐟', 'slug': 'poisson'},
    {'name': 'Viandes & Grillades', 'emoji': '🥩', 'slug': 'viande'},
    {'name': 'Volailles', 'emoji': '🍗', 'slug': 'volaille'},
    {'name': 'Soupes & Sauces', 'emoji': '🥘', 'slug': 'soupe'},
    {'name': 'Riz & Céréales', 'emoji': '🍚', 'slug': 'riz'},
    {'name': 'Légumineuses', 'emoji': '🫘', 'slug': 'legumineuse'},
    {'name': 'Petit-déjeuner', 'emoji': '🥣', 'slug': 'petit-dejeuner'},
    {'name': 'Boissons & Jus', 'emoji': '🥤', 'slug': 'boisson'},
    {'name': 'Desserts & Pâtisseries', 'emoji': '🍰', 'slug': 'dessert'},
    {'name': 'Street food & Snacks', 'emoji': '🍢', 'slug': 'street-food'},
    {'name': 'Rapides', 'emoji': '⚡', 'slug': 'rapide'},
    {'name': 'Économiques', 'emoji': '💰', 'slug': 'economique'},
    {'name': 'Sport & Fitness', 'emoji': '🏃', 'slug': 'sport'},
    {'name': 'Diabète & Santé', 'emoji': '🩺', 'slug': 'sante'},
    {'name': 'Épicées', 'emoji': '🌶️', 'slug': 'epicee'},
    {'name': 'Pour enfants', 'emoji': '🧒', 'slug': 'enfant'},
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
