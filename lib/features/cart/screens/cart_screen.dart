import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/fedapay_service.dart';
import '../../../shared/models/order_model.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/providers/cart_provider.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/primary_button.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  bool _paying = false;
  String _deliveryAddress = '';

  Future<void> _checkout() async {
    final uid = SupabaseService.currentUserId;
    if (uid == null) return;
    final cart = ref.read(cartProvider);
    if (cart.isEmpty) return;

    setState(() => _paying = true);

    try {
      final profile = await ref.read(supabaseServiceProvider).getProfile(uid);
      final service = ref.read(supabaseServiceProvider);
      final cartNotifier = ref.read(cartProvider.notifier);
      final total = cartNotifier.total;

      final fedapay = FedaPayService();
      final tx = await fedapay.createTransaction(
        amount: total,
        currency: 'XOF',
        description: 'Commande Africook',
        customerEmail: profile?.email ?? '',
        customerName: profile?.fullName ?? 'Client',
      );

      final txId = tx['v1/transaction']['id'].toString();
      final payUrl = await fedapay.getPaymentUrl(txId);

      if (mounted) {
        await _showPaymentWebView(payUrl, txId, uid, cart, total, service);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur paiement : $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }

  Future<void> _showPaymentWebView(
    String url,
    String txId,
    String uid,
    List<CartItem> cart,
    double total,
    SupabaseService service,
  ) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.9,
        child: Column(
          children: [
            AppBar(
              title: const Text('Paiement FedaPay'),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Expanded(
              child: WebViewWidget(
                controller: WebViewController()
                  ..setJavaScriptMode(JavaScriptMode.unrestricted)
                  ..loadRequest(Uri.parse(url))
                  ..setNavigationDelegate(
                    NavigationDelegate(
                      onNavigationRequest: (req) async {
                        if (req.url.contains('success') ||
                            req.url.contains('approved')) {
                          await _createOrder(
                              uid, cart, total, txId, service);
                          if (mounted) {
                            Navigator.pop(context);
                            context.go('/orders');
                          }
                          return NavigationDecision.prevent;
                        }
                        return NavigationDecision.navigate;
                      },
                    ),
                  ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createOrder(
    String uid,
    List<CartItem> cart,
    double total,
    String txId,
    SupabaseService service,
  ) async {
    final orderId = await service.createOrder({
      'user_id': uid,
      'order_type': 'restaurant',
      'status': 'confirmed',
      'total_amount': total,
      'currency': 'XOF',
      'delivery_address': _deliveryAddress,
      'payment_method': 'fedapay',
      'payment_status': 'paid',
      'fedapay_transaction_id': txId,
    });

    await service.insertOrderItems(
      orderId,
      cart
          .map((item) => {
                'item_type': item.type,
                'dish_id': item.type == 'dish' ? item.id : null,
                'product_id': item.type == 'product' ? item.id : null,
                'quantity': item.quantity,
                'unit_price': item.price,
              })
          .toList(),
    );

    ref.read(cartProvider.notifier).clear();
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final total = ref.read(cartProvider.notifier).total;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon panier'),
        actions: [
          if (cart.isNotEmpty)
            TextButton(
              onPressed: () => ref.read(cartProvider.notifier).clear(),
              child: const Text('Vider',
                  style: TextStyle(color: AppColors.error)),
            ),
        ],
      ),
      body: cart.isEmpty
          ? const EmptyState(
              title: 'Panier vide',
              subtitle: 'Ajoutez des plats ou des ingrédients pour commencer',
              icon: Icons.shopping_cart_outlined,
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: cart.length,
                    itemBuilder: (_, i) {
                      final item = cart[i];
                      return _CartItemTile(
                        item: item,
                        onInc: () => ref
                            .read(cartProvider.notifier)
                            .updateQuantity(item.id, item.quantity + 1),
                        onDec: () => ref
                            .read(cartProvider.notifier)
                            .updateQuantity(item.id, item.quantity - 1),
                        onRemove: () =>
                            ref.read(cartProvider.notifier).removeItem(item.id),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  color: AppColors.white,
                  child: Column(
                    children: [
                      TextField(
                        decoration: const InputDecoration(
                          labelText: 'Adresse de livraison',
                          prefixIcon: Icon(Icons.location_on_outlined),
                        ),
                        onChanged: (v) => _deliveryAddress = v,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Text(
                            'Total :',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${total.toStringAsFixed(0)} XOF',
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w700,
                              fontSize: 20,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      PrimaryButton(
                        label: '💳 Payer avec FedaPay',
                        onPressed: _checkout,
                        isLoading: _paying,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _CartItemTile extends StatelessWidget {
  final CartItem item;
  final VoidCallback onInc;
  final VoidCallback onDec;
  final VoidCallback onRemove;

  const _CartItemTile({
    required this.item,
    required this.onInc,
    required this.onDec,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: item.imageUrl != null
                  ? Image.network(item.imageUrl!,
                      width: 56, height: 56, fit: BoxFit.cover)
                  : Container(
                      width: 56,
                      height: 56,
                      color: AppColors.background,
                      child: const Icon(Icons.fastfood_outlined,
                          color: AppColors.primary),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name,
                      style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                          fontSize: 13)),
                  Text('${item.price.toStringAsFixed(0)} XOF',
                      style: const TextStyle(
                          color: AppColors.primary,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w700,
                          fontSize: 13)),
                ],
              ),
            ),
            Row(
              children: [
                GestureDetector(
                  onTap: onDec,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.divider),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.remove, size: 14),
                  ),
                ),
                SizedBox(
                  width: 32,
                  child: Text(
                    '${item.quantity}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700),
                  ),
                ),
                GestureDetector(
                  onTap: onInc,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add,
                        size: 14, color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
}
