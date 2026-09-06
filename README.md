# 🍽️ Africook — Application Mobile Flutter

> **Cuisinez. Partagez. Régalez-vous.**
> Assistant intelligent de cuisine africaine

## Stack Technique
- **Frontend** : Flutter (Android + iOS)
- **Backend** : Supabase (Auth, DB, Realtime, Storage)
- **Base de données** : PostgreSQL via Supabase
- **Médias** : Cloudinary
- **Paiement** : FedaPay (Mobile Money + Carte)
- **IA** : OpenAI GPT-4o
- **Notifications** : Firebase Cloud Messaging

---

## 🚀 Installation

### 1. Prérequis
```bash
flutter --version  # >= 3.19
dart --version     # >= 3.3
```

### 2. Dépendances
```bash
cd AfriCook
flutter pub get
```

### 3. Configuration `.env`
Renseignez les clés dans `.env` :
```
SUPABASE_URL=https://xxxxx.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJ...
OPENAI_API_KEY=sk-...
CLOUDINARY_CLOUD_NAME=africook
CLOUDINARY_API_KEY=...
CLOUDINARY_API_SECRET=...
FEDAPAY_PUBLIC_KEY=pk_...
FEDAPAY_SECRET_KEY=sk_...
```

### 4. Supabase
1. Créez un projet sur [supabase.com](https://supabase.com)
2. Exécutez `supabase_schema.sql` dans l'éditeur SQL
3. Activez Realtime sur la table `messages`
4. Créez un upload preset `africook_unsigned` dans Cloudinary

### 5. Firebase
1. Créez un projet Firebase
2. Ajoutez l'app Android (package: `com.africook.africook`)
3. Téléchargez `google-services.json` → `android/app/`
4. Ajoutez l'app iOS et téléchargez `GoogleService-Info.plist` → `ios/Runner/`

### 6. Fonts
Téléchargez et placez dans `assets/fonts/` :
- **Poppins** : Regular, SemiBold, Bold ([fonts.google.com](https://fonts.google.com/specimen/Poppins))
- **Nunito** : Regular, Bold ([fonts.google.com](https://fonts.google.com/specimen/Nunito))

### 7. Lancer l'app
```bash
flutter run -d android
# ou
flutter run -d ios
```

---

## 📁 Structure
```
lib/
├── main.dart              # Point d'entrée
├── app.dart               # MaterialApp + GoRouter
├── core/
│   ├── constants/         # Couleurs, strings, dimensions
│   ├── theme/             # Thème Flutter global
│   ├── services/          # Supabase, OpenAI, Cloudinary, FedaPay, FCM
│   └── router/            # GoRouter navigation
├── features/
│   ├── onboarding/        # 5 slides premier lancement
│   ├── auth/              # Login, Register, Forgot password
│   ├── home/              # Accueil + catégories + bannière IA
│   ├── recipes/           # Liste, détail, création recette
│   ├── ai_chef/           # Interface IA GPT-4o
│   ├── messaging/         # Chat temps réel Supabase Realtime
│   ├── orders/            # Restaurants + commandes
│   ├── cart/              # Panier + paiement FedaPay
│   ├── community/         # Feed social + likes + commentaires
│   ├── favorites/         # Recettes sauvegardées
│   ├── shopping_list/     # Liste de courses
│   ├── notifications/     # Notifications push + in-app
│   └── profile/           # Profil + paramètres
└── shared/
    ├── models/            # RecipeModel, UserModel, MessageModel...
    ├── providers/         # Riverpod providers
    └── widgets/           # RecipeCard, MessageBubble, HealthBadge...
```

---

## 🎨 Identité visuelle
| Couleur | Hex |
|---------|-----|
| Orange principal | `#F97316` |
| Vert | `#22C55E` |
| Jaune accent | `#FACC15` |
| Fond chaud | `#FFF8F0` |
| Texte sombre | `#1F2937` |

---

## 🗺️ Roadmap
- [x] Phase 1 : Onboarding + Auth + Accueil + Recettes
- [x] Phase 2 : IA Chef + Cloudinary + Liste de courses
- [x] Phase 3 : Messagerie Realtime + Communauté + Commandes + FedaPay
- [ ] Phase 4 : Mode Santé avancé + Reconnaissance photo + IA vocale
