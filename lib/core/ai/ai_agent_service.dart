import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/ai_agent_response.dart';
import '../config/app_config.dart';
import '../services/supabase_service.dart';

/// Calls Edge Function `ai-agent` (OpenAI tool-calling lives server-side only).
abstract interface class AiAgentService {
  Future<AiAgentResponse> ask(String message);
}

/// Offline / mock: never invents products or scores.
class FallbackAiAgentService implements AiAgentService {
  const FallbackAiAgentService();

  @override
  Future<AiAgentResponse> ask(String message) async {
    final trimmed = message.trim();
    if (trimmed.isEmpty) {
      return const AiAgentResponse(
        success: false,
        message: 'Vui lòng nhập câu hỏi.',
        errorCode: 'EMPTY_MESSAGE',
      );
    }
    return const AiAgentResponse(
      success: false,
      message: 'Chốt Hời AI chưa lấy được dữ liệu này. (chế độ offline)',
      intent: 'fallback',
      errorCode: 'AI_OFFLINE',
    );
  }
}

class SupabaseAiAgentService implements AiAgentService {
  const SupabaseAiAgentService(this._db, {AiAgentService? fallback})
      : _fallback = fallback ?? const FallbackAiAgentService();

  final SupabaseService _db;
  final AiAgentService _fallback;

  static const String functionName = 'ai-agent';

  @override
  Future<AiAgentResponse> ask(String message) async {
    final trimmed = message.trim();
    if (trimmed.isEmpty) {
      return const AiAgentResponse(
        success: false,
        message: 'Vui lòng nhập câu hỏi.',
        errorCode: 'EMPTY_MESSAGE',
      );
    }

    try {
      final response = await _db.client.functions.invoke(
        functionName,
        body: {'message': trimmed},
      );

      final data = response.data;
      if (data is! Map) {
        return _toolError();
      }

      final parsed = AiAgentResponse.fromJson(Map<String, dynamic>.from(data));
      if (!parsed.success && parsed.message.isEmpty) {
        return parsed.copyWith(message: 'Chốt Hời AI chưa lấy được dữ liệu này.');
      }
      return parsed;
    } on FunctionException {
      return _openaiError();
    } on Exception {
      return _fallback.ask(trimmed);
    }
  }

  static AiAgentResponse _openaiError() => const AiAgentResponse(
        success: false,
        message: 'Chốt Hời AI chưa lấy được dữ liệu này.',
        intent: 'error',
        errorCode: 'AI_UNAVAILABLE',
      );

  static AiAgentResponse _toolError() => const AiAgentResponse(
        success: false,
        message: 'Chốt Hời AI chưa lấy được dữ liệu này.',
        intent: 'error',
        errorCode: 'TOOL_ERROR',
      );
}

final aiAgentServiceProvider = Provider<AiAgentService>((ref) {
  if (AppConfig.useMockData) return const FallbackAiAgentService();
  return SupabaseAiAgentService(ref.watch(supabaseServiceProvider));
});
