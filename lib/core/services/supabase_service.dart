import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';

/// Table names in the Supabase `public` schema.
abstract final class DbTables {
  static const String profiles = 'profiles';
  static const String marketplaces = 'marketplaces';
  static const String categories = 'categories';
  static const String brands = 'brands';
  static const String products = 'products';
  static const String marketplaceProducts = 'marketplace_products';
  static const String marketplaceProductImages = 'marketplace_product_images';
  static const String productVariants = 'product_variants';
  static const String marketplaceProductVariants = 'marketplace_product_variants';
  static const String priceHistory = 'price_history';
  static const String reviews = 'reviews';
  static const String reviewSummaries = 'review_summaries';
  static const String productMatches = 'product_matches';
  static const String productEmbeddings = 'product_embeddings';
  static const String savedProducts = 'saved_products';
  static const String priceAlerts = 'price_alerts';
  static const String dealCarts = 'deal_carts';
  static const String dealCartItems = 'deal_cart_items';
  static const String searchHistories = 'search_histories';
  static const String notifications = 'notifications';
  static const String aiConversations = 'ai_conversations';
  static const String aiMessages = 'ai_messages';
  static const String affiliateClicks = 'affiliate_clicks';
  static const String affiliateConversions = 'affiliate_conversions';
}

/// User-facing error raised by repositories when a Supabase call fails.
class DataFailure implements Exception {
  const DataFailure(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() => message;
}

/// Raised when a user-owned table is accessed without a signed-in user.
class AuthRequiredFailure extends DataFailure {
  const AuthRequiredFailure() : super('Vui lòng đăng nhập để sử dụng tính năng này.');
}

/// Thin wrapper around [SupabaseClient] used by repositories only.
/// Widgets must go through a repository instead of calling this directly.
class SupabaseService {
  const SupabaseService(this.client);

  final SupabaseClient client;

  static const String _networkMessage = 'Không thể kết nối máy chủ. Vui lòng kiểm tra mạng và thử lại.';
  static const String _genericMessage = 'Không tải được dữ liệu. Vui lòng thử lại.';
  static const String _permissionMessage = 'Bạn không có quyền truy cập dữ liệu này.';

  SupabaseQueryBuilder from(String table) => client.from(table);

  String? get currentUserId => client.auth.currentUser?.id;

  /// Id of the signed-in user; RLS policies compare it with `auth.uid()`.
  String requireUserId() => currentUserId ?? (throw const AuthRequiredFailure());

  /// Runs [body] and converts transport/database errors into [DataFailure].
  Future<T> run<T>(Future<T> Function(SupabaseClient client) body) async {
    try {
      return await body(client);
    } on DataFailure {
      rethrow;
    } on PostgrestException catch (e) {
      // 42501: insufficient_privilege, PGRST301: JWT/RLS rejection.
      final denied = e.code == '42501' || e.code == 'PGRST301';
      throw DataFailure(denied ? _permissionMessage : _genericMessage, e);
    } on AuthException catch (e) {
      throw DataFailure(e.message, e);
    } on Exception catch (e) {
      // SocketException / ClientException / TimeoutException differ per platform (web vs io).
      throw DataFailure(_networkMessage, e);
    }
  }
}

final supabaseServiceProvider = Provider<SupabaseService>((ref) => SupabaseService(ref.watch(supabaseClientProvider)));
