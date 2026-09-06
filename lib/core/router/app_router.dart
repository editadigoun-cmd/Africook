import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/onboarding/screens/onboarding_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/recipes/screens/recipes_screen.dart';
import '../../features/recipes/screens/recipe_detail_screen.dart';
import '../../features/recipes/screens/recipe_create_screen.dart';
import '../../features/ai_chef/screens/ai_chef_screen.dart';
import '../../features/orders/screens/orders_screen.dart';
import '../../features/orders/screens/restaurants_screen.dart';
import '../../features/orders/screens/restaurant_detail_screen.dart';
import '../../features/cart/screens/cart_screen.dart';
import '../../features/community/screens/community_screen.dart';
import '../../features/messaging/screens/conversations_screen.dart';
import '../../features/messaging/screens/chat_screen.dart';
import '../../features/favorites/screens/favorites_screen.dart';
import '../../features/shopping_list/screens/shopping_list_screen.dart';
import '../../features/notifications/screens/notifications_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/profile/screens/edit_profile_screen.dart';
import '../../features/boutique/screens/boutique_screen.dart';
import '../../features/boutique/screens/store_detail_screen.dart';
import '../../shared/widgets/main_scaffold.dart';
import '../services/supabase_service.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isLoggedIn = SupabaseService.currentUser != null;
      final isAuthRoute = state.matchedLocation.startsWith('/auth') ||
          state.matchedLocation == '/onboarding';

      if (!isLoggedIn && !isAuthRoute && state.matchedLocation != '/onboarding') {
        return '/auth/login';
      }
      if (isLoggedIn && isAuthRoute) {
        return '/home';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        redirect: (_, __) => '/onboarding',
      ),
      GoRoute(
        path: '/onboarding',
        builder: (_, __) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/auth/login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: '/auth/register',
        builder: (_, __) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/auth/forgot-password',
        builder: (_, __) => const ForgotPasswordScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainScaffold(child: child),
        routes: [
          GoRoute(
            path: '/home',
            builder: (_, __) => const HomeScreen(),
          ),
          GoRoute(
            path: '/recipes',
            builder: (_, __) => const RecipesScreen(),
          ),
          GoRoute(
            path: '/ai-chef',
            builder: (_, __) => const AiChefScreen(),
          ),
          GoRoute(
            path: '/orders',
            builder: (_, __) => const OrdersScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (_, __) => const ProfileScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/recipe/create',
        builder: (_, __) => const RecipeCreateScreen(),
      ),
      GoRoute(
        path: '/recipe/:id',
        builder: (_, state) => RecipeDetailScreen(
          recipeId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/restaurants',
        builder: (_, __) => const RestaurantsScreen(),
      ),
      GoRoute(
        path: '/restaurant/:id',
        builder: (_, state) => RestaurantDetailScreen(
          restaurantId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/cart',
        builder: (_, __) => const CartScreen(),
      ),
      GoRoute(
        path: '/community',
        builder: (_, __) => const CommunityScreen(),
      ),
      GoRoute(
        path: '/messages',
        builder: (_, __) => const ConversationsScreen(),
      ),
      GoRoute(
        path: '/messages/:conversationId',
        builder: (_, state) => ChatScreen(
          conversationId: state.pathParameters['conversationId']!,
        ),
      ),
      GoRoute(
        path: '/favorites',
        builder: (_, __) => const FavoritesScreen(),
      ),
      GoRoute(
        path: '/shopping-list',
        builder: (_, __) => const ShoppingListScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (_, __) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/profile/edit',
        builder: (_, __) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/boutique',
        builder: (_, __) => const BoutiqueScreen(),
      ),
      GoRoute(
        path: '/boutique/:id',
        builder: (_, state) => StoreDetailScreen(
          store: {'id': state.pathParameters['id']!},
        ),
      ),
    ],
  );
});
