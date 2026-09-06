import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class FedaPayService {
  late final Dio _dio;
  static const String _baseUrl = 'https://api.fedapay.com/v1';

  FedaPayService() {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      headers: {
        'Authorization': 'Bearer ${dotenv.env['FEDAPAY_SECRET_KEY']}',
        'Content-Type': 'application/json',
      },
    ));
  }

  Future<Map<String, dynamic>> createTransaction({
    required double amount,
    required String currency,
    required String description,
    required String customerEmail,
    required String customerName,
    String? customerPhone,
  }) async {
    final response = await _dio.post('/transactions', data: {
      'description': description,
      'amount': amount.toInt(),
      'currency': {'iso': currency},
      'customer': {
        'email': customerEmail,
        'firstname': customerName.split(' ').first,
        'lastname': customerName.split(' ').length > 1
            ? customerName.split(' ').last
            : '',
        'phone_number': {
          'number': customerPhone ?? '',
          'country': 'BJ',
        },
      },
    });

    return response.data as Map<String, dynamic>;
  }

  Future<String> getPaymentUrl(String transactionId) async {
    final response = await _dio.get('/transactions/$transactionId/token');
    final token = response.data['token'] as String;
    return 'https://checkout.fedapay.com/$token';
  }

  Future<Map<String, dynamic>> getTransactionStatus(String id) async {
    final response = await _dio.get('/transactions/$id');
    return response.data as Map<String, dynamic>;
  }
}
