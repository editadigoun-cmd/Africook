class OrderModel {
  final String id;
  final String userId;
  final String orderType;
  final OrderStatus status;
  final double totalAmount;
  final String currency;
  final String? deliveryAddress;
  final String? paymentMethod;
  final String paymentStatus;
  final String? fedapayTransactionId;
  final DateTime createdAt;
  final List<OrderItem> items;

  OrderModel({
    required this.id,
    required this.userId,
    required this.orderType,
    required this.status,
    required this.totalAmount,
    this.currency = 'XOF',
    this.deliveryAddress,
    this.paymentMethod,
    this.paymentStatus = 'unpaid',
    this.fedapayTransactionId,
    required this.createdAt,
    this.items = const [],
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) => OrderModel(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        orderType: json['order_type'] as String,
        status: OrderStatus.fromString(json['status'] as String? ?? 'pending'),
        totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0,
        currency: json['currency'] as String? ?? 'XOF',
        deliveryAddress: json['delivery_address'] as String?,
        paymentMethod: json['payment_method'] as String?,
        paymentStatus: json['payment_status'] as String? ?? 'unpaid',
        fedapayTransactionId: json['fedapay_transaction_id'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
        items: (json['order_items'] as List?)
                ?.map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );
}

enum OrderStatus {
  pending('pending', 'En attente'),
  confirmed('confirmed', 'Confirmée'),
  preparing('preparing', 'En préparation'),
  delivering('delivering', 'En livraison'),
  delivered('delivered', 'Livrée'),
  cancelled('cancelled', 'Annulée');

  final String value;
  final String label;
  const OrderStatus(this.value, this.label);

  static OrderStatus fromString(String v) =>
      OrderStatus.values.firstWhere((e) => e.value == v, orElse: () => OrderStatus.pending);
}

class OrderItem {
  final int id;
  final String orderId;
  final String itemType;
  final String? dishId;
  final String? productId;
  final int quantity;
  final double unitPrice;
  final String? itemName;
  final String? itemImage;

  OrderItem({
    required this.id,
    required this.orderId,
    required this.itemType,
    this.dishId,
    this.productId,
    this.quantity = 1,
    required this.unitPrice,
    this.itemName,
    this.itemImage,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
        id: json['id'] as int,
        orderId: json['order_id'] as String,
        itemType: json['item_type'] as String,
        dishId: json['dish_id'] as String?,
        productId: json['product_id'] as String?,
        quantity: json['quantity'] as int? ?? 1,
        unitPrice: (json['unit_price'] as num?)?.toDouble() ?? 0,
      );

  double get totalPrice => unitPrice * quantity;
}

class CartItem {
  final String id;
  final String name;
  final String? imageUrl;
  final double price;
  int quantity;
  final String type;

  CartItem({
    required this.id,
    required this.name,
    this.imageUrl,
    required this.price,
    this.quantity = 1,
    required this.type,
  });

  double get total => price * quantity;
}
