-- ════════════════════════════════════════
-- AFRICOOK — Schéma PostgreSQL Supabase
-- ════════════════════════════════════════

-- Utilisateurs
CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT UNIQUE,
  phone TEXT UNIQUE,
  full_name TEXT NOT NULL,
  avatar_url TEXT,
  bio TEXT,
  is_premium BOOLEAN DEFAULT false,
  health_profile JSONB,
  default_servings INT DEFAULT 2,
  default_budget TEXT,
  language TEXT DEFAULT 'fr',
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Catégories de recettes
CREATE TABLE IF NOT EXISTS categories (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  icon TEXT,
  slug TEXT UNIQUE
);

INSERT INTO categories (name, icon, slug) VALUES
  ('Béninoises', '🇧🇯', 'beninoise'),
  ('Africaines', '🌍', 'africaine'),
  ('Internationales', '🌐', 'internationale'),
  ('Végétariennes', '🥗', 'vegetarienne'),
  ('Poissons & Fruits de mer', '🐟', 'poisson'),
  ('Viandes & Grillades', '🥩', 'viande'),
  ('Volailles', '🍗', 'volaille'),
  ('Soupes & Sauces', '🥘', 'soupe'),
  ('Riz & Céréales', '🍚', 'riz'),
  ('Légumineuses', '🫘', 'legumineuse'),
  ('Petit-déjeuner', '🥣', 'petit-dejeuner'),
  ('Boissons & Jus', '🥤', 'boisson'),
  ('Desserts & Pâtisseries', '🍰', 'dessert'),
  ('Street food & Snacks', '🍢', 'street-food'),
  ('Rapides', '⚡', 'rapide'),
  ('Économiques', '💰', 'economique'),
  ('Sport & Fitness', '🏃', 'sport'),
  ('Diabète & Santé', '🩺', 'sante'),
  ('Épicées', '🌶️', 'epicee'),
  ('Pour enfants', '🧒', 'enfant')
ON CONFLICT (slug) DO NOTHING;

-- Recettes
CREATE TABLE IF NOT EXISTS recipes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  author_id UUID REFERENCES users(id),
  title TEXT NOT NULL,
  description TEXT,
  category_id INT REFERENCES categories(id),
  image_url TEXT,
  video_url TEXT,
  prep_time_minutes INT,
  cook_time_minutes INT,
  difficulty TEXT CHECK (difficulty IN ('Facile','Moyen','Difficile')),
  servings INT DEFAULT 2,
  budget_range TEXT,
  is_ai_generated BOOLEAN DEFAULT false,
  is_community BOOLEAN DEFAULT false,
  is_published BOOLEAN DEFAULT true,
  health_tags TEXT[],
  average_rating DECIMAL(3,2) DEFAULT 0,
  ratings_count INT DEFAULT 0,
  views_count INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Ingrédients
CREATE TABLE IF NOT EXISTS recipe_ingredients (
  id SERIAL PRIMARY KEY,
  recipe_id UUID REFERENCES recipes(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  quantity TEXT,
  unit TEXT,
  is_optional BOOLEAN DEFAULT false
);

-- Étapes
CREATE TABLE IF NOT EXISTS recipe_steps (
  id SERIAL PRIMARY KEY,
  recipe_id UUID REFERENCES recipes(id) ON DELETE CASCADE,
  step_number INT NOT NULL,
  instruction TEXT NOT NULL,
  image_url TEXT,
  duration_minutes INT
);

-- Nutrition
CREATE TABLE IF NOT EXISTS nutrition_info (
  id SERIAL PRIMARY KEY,
  recipe_id UUID REFERENCES recipes(id) ON DELETE CASCADE,
  calories INT,
  proteins_g DECIMAL,
  carbs_g DECIMAL,
  fats_g DECIMAL,
  fiber_g DECIMAL
);

-- Notes
CREATE TABLE IF NOT EXISTS ratings (
  id SERIAL PRIMARY KEY,
  recipe_id UUID REFERENCES recipes(id) ON DELETE CASCADE,
  user_id UUID REFERENCES users(id),
  score INT CHECK (score BETWEEN 1 AND 5),
  comment TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(recipe_id, user_id)
);

-- Favoris
CREATE TABLE IF NOT EXISTS favorites (
  user_id UUID REFERENCES users(id),
  recipe_id UUID REFERENCES recipes(id),
  created_at TIMESTAMPTZ DEFAULT now(),
  PRIMARY KEY (user_id, recipe_id)
);

-- Historique
CREATE TABLE IF NOT EXISTS recipe_history (
  user_id UUID REFERENCES users(id),
  recipe_id UUID REFERENCES recipes(id),
  viewed_at TIMESTAMPTZ DEFAULT now(),
  PRIMARY KEY (user_id, recipe_id)
);

-- Liste de courses
CREATE TABLE IF NOT EXISTS shopping_list_items (
  id SERIAL PRIMARY KEY,
  user_id UUID REFERENCES users(id),
  recipe_id UUID REFERENCES recipes(id),
  ingredient_name TEXT NOT NULL,
  quantity TEXT,
  unit TEXT,
  is_checked BOOLEAN DEFAULT false,
  category TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Restaurants
CREATE TABLE IF NOT EXISTS restaurants (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  logo_url TEXT,
  cover_url TEXT,
  address TEXT,
  city TEXT,
  phone TEXT,
  rating DECIMAL(3,2) DEFAULT 0,
  delivery_time_minutes INT,
  is_open BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Plats restaurant
CREATE TABLE IF NOT EXISTS restaurant_dishes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  restaurant_id UUID REFERENCES restaurants(id),
  recipe_id UUID REFERENCES recipes(id),
  price DECIMAL(10,2) NOT NULL,
  currency TEXT DEFAULT 'XOF',
  is_available BOOLEAN DEFAULT true
);

-- Boutiques partenaires
CREATE TABLE IF NOT EXISTS partner_shops (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  logo_url TEXT,
  city TEXT,
  delivery_available BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Produits boutique
CREATE TABLE IF NOT EXISTS shop_products (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  shop_id UUID REFERENCES partner_shops(id),
  name TEXT NOT NULL,
  image_url TEXT,
  price DECIMAL(10,2),
  unit TEXT,
  is_available BOOLEAN DEFAULT true
);

-- Commandes
CREATE TABLE IF NOT EXISTS orders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id),
  order_type TEXT CHECK (order_type IN ('restaurant','ingredients')),
  status TEXT DEFAULT 'pending'
    CHECK (status IN ('pending','confirmed','preparing','delivering','delivered','cancelled')),
  total_amount DECIMAL(10,2),
  currency TEXT DEFAULT 'XOF',
  delivery_address TEXT,
  payment_method TEXT,
  payment_status TEXT DEFAULT 'unpaid',
  fedapay_transaction_id TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Lignes de commande
CREATE TABLE IF NOT EXISTS order_items (
  id SERIAL PRIMARY KEY,
  order_id UUID REFERENCES orders(id) ON DELETE CASCADE,
  item_type TEXT CHECK (item_type IN ('dish','product')),
  dish_id UUID REFERENCES restaurant_dishes(id),
  product_id UUID REFERENCES shop_products(id),
  quantity INT DEFAULT 1,
  unit_price DECIMAL(10,2)
);

-- Conversations
CREATE TABLE IF NOT EXISTS conversations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_a_id UUID REFERENCES users(id),
  user_b_id UUID REFERENCES users(id),
  recipe_id UUID REFERENCES recipes(id),
  last_message_at TIMESTAMPTZ DEFAULT now(),
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(user_a_id, user_b_id)
);

-- Messages
CREATE TABLE IF NOT EXISTS messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id UUID REFERENCES conversations(id) ON DELETE CASCADE,
  sender_id UUID REFERENCES users(id),
  content TEXT NOT NULL,
  message_type TEXT DEFAULT 'text'
    CHECK (message_type IN ('text','image','recipe_share')),
  image_url TEXT,
  shared_recipe_id UUID REFERENCES recipes(id),
  is_read BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Notifications
CREATE TABLE IF NOT EXISTS notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id),
  type TEXT,
  title TEXT,
  body TEXT,
  data JSONB,
  is_read BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Abonnements
CREATE TABLE IF NOT EXISTS follows (
  follower_id UUID REFERENCES users(id),
  following_id UUID REFERENCES users(id),
  created_at TIMESTAMPTZ DEFAULT now(),
  PRIMARY KEY (follower_id, following_id)
);

-- Commentaires
CREATE TABLE IF NOT EXISTS comments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  recipe_id UUID REFERENCES recipes(id) ON DELETE CASCADE,
  user_id UUID REFERENCES users(id),
  content TEXT NOT NULL,
  parent_id UUID REFERENCES comments(id),
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Likes
CREATE TABLE IF NOT EXISTS likes (
  user_id UUID REFERENCES users(id),
  recipe_id UUID REFERENCES recipes(id),
  created_at TIMESTAMPTZ DEFAULT now(),
  PRIMARY KEY (user_id, recipe_id)
);

-- Historique IA
CREATE TABLE IF NOT EXISTS ai_generated_recipes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id),
  ingredients_input TEXT,
  prompt_used TEXT,
  result_recipe JSONB,
  saved_as_recipe_id UUID REFERENCES recipes(id),
  created_at TIMESTAMPTZ DEFAULT now()
);

-- ════════════════════════════════════════
-- ROW LEVEL SECURITY
-- ════════════════════════════════════════

ALTER TABLE users ENABLE ROW LEVEL SECURITY;
CREATE POLICY "users_read" ON users FOR SELECT USING (true);
CREATE POLICY "users_insert" ON users FOR INSERT WITH CHECK (auth.uid() = id);
CREATE POLICY "users_update" ON users FOR UPDATE USING (auth.uid() = id);

ALTER TABLE recipes ENABLE ROW LEVEL SECURITY;
CREATE POLICY "recipes_read" ON recipes FOR SELECT USING (is_published = true);
CREATE POLICY "recipes_insert" ON recipes FOR INSERT WITH CHECK (auth.uid() = author_id);
CREATE POLICY "recipes_update" ON recipes FOR UPDATE USING (auth.uid() = author_id);
CREATE POLICY "recipes_delete" ON recipes FOR DELETE USING (auth.uid() = author_id);

ALTER TABLE recipe_ingredients ENABLE ROW LEVEL SECURITY;
CREATE POLICY "ingredients_read" ON recipe_ingredients FOR SELECT USING (true);
CREATE POLICY "ingredients_write" ON recipe_ingredients FOR ALL
  USING (auth.uid() IN (SELECT author_id FROM recipes WHERE id = recipe_id));

ALTER TABLE recipe_steps ENABLE ROW LEVEL SECURITY;
CREATE POLICY "steps_read" ON recipe_steps FOR SELECT USING (true);
CREATE POLICY "steps_write" ON recipe_steps FOR ALL
  USING (auth.uid() IN (SELECT author_id FROM recipes WHERE id = recipe_id));

ALTER TABLE nutrition_info ENABLE ROW LEVEL SECURITY;
CREATE POLICY "nutrition_read" ON nutrition_info FOR SELECT USING (true);

ALTER TABLE favorites ENABLE ROW LEVEL SECURITY;
CREATE POLICY "favorites_all" ON favorites FOR ALL USING (auth.uid() = user_id);

ALTER TABLE shopping_list_items ENABLE ROW LEVEL SECURITY;
CREATE POLICY "shopping_all" ON shopping_list_items FOR ALL USING (auth.uid() = user_id);

ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
CREATE POLICY "messages_access" ON messages FOR ALL
  USING (
    auth.uid() IN (
      SELECT user_a_id FROM conversations WHERE id = conversation_id
      UNION
      SELECT user_b_id FROM conversations WHERE id = conversation_id
    )
  );

ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;
CREATE POLICY "conversations_access" ON conversations FOR ALL
  USING (auth.uid() = user_a_id OR auth.uid() = user_b_id);

ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
CREATE POLICY "orders_access" ON orders FOR ALL USING (auth.uid() = user_id);

ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;
CREATE POLICY "order_items_access" ON order_items FOR ALL
  USING (auth.uid() IN (SELECT user_id FROM orders WHERE id = order_id));

ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
CREATE POLICY "notifications_access" ON notifications FOR ALL USING (auth.uid() = user_id);

ALTER TABLE ratings ENABLE ROW LEVEL SECURITY;
CREATE POLICY "ratings_read" ON ratings FOR SELECT USING (true);
CREATE POLICY "ratings_write" ON ratings FOR ALL USING (auth.uid() = user_id);

ALTER TABLE comments ENABLE ROW LEVEL SECURITY;
CREATE POLICY "comments_read" ON comments FOR SELECT USING (true);
CREATE POLICY "comments_write" ON comments FOR ALL USING (auth.uid() = user_id);

ALTER TABLE likes ENABLE ROW LEVEL SECURITY;
CREATE POLICY "likes_read" ON likes FOR SELECT USING (true);
CREATE POLICY "likes_write" ON likes FOR ALL USING (auth.uid() = user_id);

ALTER TABLE follows ENABLE ROW LEVEL SECURITY;
CREATE POLICY "follows_read" ON follows FOR SELECT USING (true);
CREATE POLICY "follows_write" ON follows FOR ALL USING (auth.uid() = follower_id);

ALTER TABLE ai_generated_recipes ENABLE ROW LEVEL SECURITY;
CREATE POLICY "ai_history_access" ON ai_generated_recipes FOR ALL USING (auth.uid() = user_id);

-- ════════════════════════════════════════
-- REALTIME (activer pour les messages)
-- ════════════════════════════════════════
-- Dans Supabase Dashboard > Database > Replication, activer la table 'messages'

-- ════════════════════════════════════════
-- INDEXES
-- ════════════════════════════════════════
CREATE INDEX IF NOT EXISTS idx_recipes_category ON recipes(category_id);
CREATE INDEX IF NOT EXISTS idx_recipes_author ON recipes(author_id);
CREATE INDEX IF NOT EXISTS idx_recipes_published ON recipes(is_published);
CREATE INDEX IF NOT EXISTS idx_messages_conversation ON messages(conversation_id);
CREATE INDEX IF NOT EXISTS idx_messages_created ON messages(created_at);
CREATE INDEX IF NOT EXISTS idx_notifications_user ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_orders_user ON orders(user_id);
