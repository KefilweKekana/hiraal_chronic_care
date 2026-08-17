import 'dart:convert';
import 'package:dio/dio.dart';

import '../../core/network/api_client.dart';
import '../../core/utils/app_logger.dart';
import '../../core/utils/result.dart';
import '../../models/subscription.dart';
import '../payment_service.dart';

/// ERPNext implementation: calls the hiraal_emr scoped payment endpoints, which
/// drive the mobile_payments (WaafiPay / eDahab) gateway.
class ErpNextPaymentService implements PaymentService {
  final ApiClient _api;

  ErpNextPaymentService(this._api);

  /// Pull a human message out of Frappe's _server_messages (so a thrown
  /// "No subscription found" reaches the user instead of a generic error).
  String _parseServerError(dynamic data, String fallback) {
    try {
      final raw = data?['_server_messages']?.toString();
      if (raw != null && raw.isNotEmpty) {
        final List msgs = json.decode(raw);
        if (msgs.isNotEmpty) {
          final inner = json.decode(msgs.first.toString());
          return (inner['message']?.toString() ?? fallback).replaceAll(RegExp(r'<[^>]*>'), '');
        }
      }
      // Unhandled Frappe exceptions carry their message in 'exception', e.g.
      // "frappe.exceptions.ValidationError: Payment declined: ..." — strip the
      // class prefix so the user sees the actual reason.
      final exc = data?['exception']?.toString();
      if (exc != null && exc.isNotEmpty) {
        final i = exc.indexOf(': ');
        return (i > 0 ? exc.substring(i + 2) : exc).replaceAll(RegExp(r'<[^>]*>'), '');
      }
      return data?['message']?.toString() ?? fallback;
    } catch (_) {
      return data?['message']?.toString() ?? fallback;
    }
  }

  @override
  Future<Result<List<PaymentMethodOption>>> getMethods() async {
    try {
      final r = await _api.dio.post('/method/hiraal_emr.api.get_payment_methods');
      final msg = r.data?['message'] as Map<String, dynamic>?;
      final list = (msg?['methods'] as List?) ?? [];
      final methods = list
          .whereType<Map>()
          .map((e) => PaymentMethodOption.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      return Success(methods);
    } on DioException catch (e) {
      log.e('getMethods failed', error: e);
      return Failure(_parseServerError(e.response?.data, 'Failed to load payment methods'),
          statusCode: e.response?.statusCode);
    } catch (e) {
      return Failure(e.toString());
    }
  }

  @override
  Future<Result<String>> paySubscription({
    required String provider,
    required String method,
    required String phone,
  }) async {
    try {
      final r = await _api.dio.post(
        '/method/hiraal_emr.api.pay_my_subscription',
        data: {'provider': provider, 'method': method, 'phone': phone},
        // The wallet gateway holds this request open until the customer
        // approves/declines on their phone — a short receive timeout would
        // report failure while the charge silently completes server-side.
        options: Options(receiveTimeout: const Duration(seconds: 120)),
      );
      final msg = r.data?['message'] as Map<String, dynamic>?;
      final txn = msg?['transaction_log']?.toString() ?? '';
      if (msg?['success'] == true && txn.isNotEmpty) return Success(txn);
      return Failure(msg?['message']?.toString() ?? 'Could not start the payment');
    } on DioException catch (e) {
      log.e('paySubscription failed', error: e);
      if (e.type == DioExceptionType.receiveTimeout) {
        return const Failure(
            'The payment is taking longer than usual. If you approved it on your phone, it will complete automatically — check again in a few minutes.');
      }
      return Failure(_parseServerError(e.response?.data, 'Could not start the payment'),
          statusCode: e.response?.statusCode);
    } catch (e) {
      return Failure(e.toString());
    }
  }

  @override
  Future<Result<String>> checkStatus(String transactionLog) async {
    try {
      final r = await _api.dio.post(
        '/method/hiraal_emr.api.check_my_payment',
        data: {'transaction_log': transactionLog},
      );
      final msg = r.data?['message'] as Map<String, dynamic>?;
      return Success(msg?['status']?.toString() ?? 'Pending');
    } on DioException catch (e) {
      log.e('checkStatus failed', error: e);
      return Failure(_parseServerError(e.response?.data, 'Could not check the payment'),
          statusCode: e.response?.statusCode);
    } catch (e) {
      return Failure(e.toString());
    }
  }

  @override
  Future<Result<String>> payOrder({
    required String orderId,
    required String provider,
    required String method,
    required String phone,
  }) async {
    try {
      final r = await _api.dio.post(
        '/method/hiraal_emr.api.pay_my_order',
        data: {'order': orderId, 'provider': provider, 'method': method, 'phone': phone},
        // The wallet gateway holds this request open until the customer
        // approves/declines on their phone — a short receive timeout would
        // report failure while the charge silently completes server-side.
        options: Options(receiveTimeout: const Duration(seconds: 120)),
      );
      final msg = r.data?['message'] as Map<String, dynamic>?;
      final txn = msg?['transaction_log']?.toString() ?? '';
      if (msg?['success'] == true && txn.isNotEmpty) return Success(txn);
      return Failure(msg?['message']?.toString() ?? 'Could not start the payment');
    } on DioException catch (e) {
      log.e('payOrder failed', error: e);
      if (e.type == DioExceptionType.receiveTimeout) {
        return const Failure(
            'The payment is taking longer than usual. If you approved it on your phone, it will complete automatically — check again in a few minutes.');
      }
      return Failure(_parseServerError(e.response?.data, 'Could not start the payment'),
          statusCode: e.response?.statusCode);
    } catch (e) {
      return Failure(e.toString());
    }
  }

  @override
  Future<Result<String>> checkOrderStatus({
    required String orderId,
    required String transactionLog,
  }) async {
    try {
      final r = await _api.dio.post(
        '/method/hiraal_emr.api.check_my_order_payment',
        data: {'order': orderId, 'transaction_log': transactionLog},
      );
      final msg = r.data?['message'] as Map<String, dynamic>?;
      return Success(msg?['status']?.toString() ?? 'Pending');
    } on DioException catch (e) {
      log.e('checkOrderStatus failed', error: e);
      return Failure(_parseServerError(e.response?.data, 'Could not check the payment'),
          statusCode: e.response?.statusCode);
    } catch (e) {
      return Failure(e.toString());
    }
  }

  @override
  Future<Result<SubscriptionInfo>> getSubscription() async {
    try {
      final r = await _api.dio.post('/method/hiraal_emr.api.get_my_subscription');
      final msg = r.data?['message'] as Map<String, dynamic>?;
      return Success(SubscriptionInfo.fromJson(msg ?? const {}));
    } on DioException catch (e) {
      log.e('getSubscription failed', error: e);
      return Failure(_parseServerError(e.response?.data, 'Failed to load your subscription'),
          statusCode: e.response?.statusCode);
    } catch (e) {
      return Failure(e.toString());
    }
  }

  @override
  Future<Result<SubscribeResult>> subscribe(String plan, {bool startTrial = false}) async {
    try {
      final r = await _api.dio.post(
        '/method/hiraal_emr.api.subscribe_my_plan',
        data: {
          'plan': plan,
          'start_trial': startTrial ? 1 : 0,
        },
      );
      final msg = r.data?['message'] as Map<String, dynamic>?;
      if (msg == null) return const Failure('Could not start your subscription');
      return Success(SubscribeResult.fromJson(msg));
    } on DioException catch (e) {
      log.e('subscribe failed', error: e);
      return Failure(_parseServerError(e.response?.data, 'Could not start your subscription'),
          statusCode: e.response?.statusCode);
    } catch (e) {
      return Failure(e.toString());
    }
  }
}
