import 'dart:async';

import 'package:finpat_mobile/core/errors/app_error_mapper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class AppStateController extends ChangeNotifier {
  AppStateController(this._client);

  final SupabaseClient _client;
  bool initializing = true;
  bool loading = false;
  String? error;
  Map<String, dynamic>? profile;
  List<Map<String, dynamic>> centers = [];
  List<Map<String, dynamic>> obligations = [];
  List<Map<String, dynamic>> remittances = [];
  List<Map<String, dynamic>> savings = [];

  User? get currentUser => _client.auth.currentUser;
  bool get isLoggedIn => currentUser != null;
  bool get isOnboarded => (profile?['onboarded'] as bool?) ?? false;

  Future<void> bootstrap() async {
    initializing = true;
    error = null;
    notifyListeners();
    try {
      if (!isLoggedIn) return;
      await refreshAll();
    } catch (e) {
      error = AppErrorMapper.toMessage(e);
    } finally {
      initializing = false;
      notifyListeners();
    }
  }

  Future<void> refreshAll() async {
    final user = currentUser;
    if (user == null) return;
    loading = true;
    error = null;
    notifyListeners();
    try {
      final results = await Future.wait<dynamic>([
        _client.from('profiles').select().eq('id', user.id).maybeSingle(),
        _client.from('responsibility_centers').select().eq('user_id', user.id).order('created_at', ascending: true),
        _client.from('obligations').select().eq('user_id', user.id).order('created_at', ascending: false),
        _client.from('remittances').select().eq('user_id', user.id).order('created_at', ascending: false),
        _client.from('savings_log').select().eq('user_id', user.id).order('created_at', ascending: false),
      ]);
      profile = results[0] as Map<String, dynamic>?;
      centers = (results[1] as List).cast<Map<String, dynamic>>();
      obligations = (results[2] as List).cast<Map<String, dynamic>>();
      remittances = (results[3] as List).cast<Map<String, dynamic>>();
      savings = (results[4] as List).cast<Map<String, dynamic>>();
    } catch (e) {
      error = AppErrorMapper.toMessage(e);
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<String?> signIn(String email, String password) async {
    try {
      await _client.auth.signInWithPassword(email: email, password: password);
      await bootstrap();
      return null;
    } catch (e) {
      return AppErrorMapper.toMessage(e);
    }
  }

  Future<String?> signUp(String name, String email, String password) async {
    try {
      await _client.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': name},
      );
      await bootstrap();
      return null;
    } catch (e) {
      return AppErrorMapper.toMessage(e);
    }
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
    profile = null;
    centers = [];
    obligations = [];
    remittances = [];
    savings = [];
    notifyListeners();
  }

  Future<String?> saveOnboarding({
    required String workLocation,
    required String familyLocation,
    required double incomeAmount,
    required String incomeCurrency,
    required String incomeFrequency,
    required List<Map<String, dynamic>> seedCenters,
  }) async {
    final user = currentUser;
    if (user == null) return 'Session expired. Please sign in again.';
    try {
      await _client.from('profiles').upsert({
        'id': user.id,
        'email': user.email,
        'name': profile?['name'] ?? user.userMetadata?['full_name'],
        'onboarded': true,
        'work_location': workLocation,
        'family_location': familyLocation,
        'income_amount': incomeAmount,
        'income_currency': incomeCurrency.toUpperCase(),
        'income_frequency': incomeFrequency,
      });

      final existingCenters = await _client
          .from('responsibility_centers')
          .select('id')
          .eq('user_id', user.id)
          .limit(1);
      if ((existingCenters as List).isEmpty && seedCenters.isNotEmpty) {
        final payload = seedCenters
            .map((c) => {
                  'user_id': user.id,
                  'name': c['name'],
                  'icon': c['icon'],
                  'color': c['color'],
                  'is_default': c['is_default'] ?? false,
                })
            .toList();
        await _client.from('responsibility_centers').insert(payload);
      }

      await refreshAll();
      return null;
    } catch (e) {
      return AppErrorMapper.toMessage(e);
    }
  }

  Future<String?> addCenter({required String name, required String color, String icon = 'home'}) async {
    final user = currentUser;
    if (user == null) return 'Not authenticated.';
    try {
      await _client.from('responsibility_centers').insert({
        'user_id': user.id,
        'name': name,
        'icon': icon,
        'color': color,
        'is_default': false,
      });
      await refreshAll();
      return null;
    } catch (e) {
      return AppErrorMapper.toMessage(e);
    }
  }

  Future<String?> deleteCenter(String id) async {
    try {
      await _client.from('responsibility_centers').delete().eq('id', id);
      await refreshAll();
      return null;
    } catch (e) {
      return AppErrorMapper.toMessage(e);
    }
  }

  Future<String?> addObligation({
    required String centerId,
    required String title,
    required double amount,
    required String currency,
    required String type,
    String? dueDate,
    double? goalAmount,
  }) async {
    final user = currentUser;
    if (user == null) return 'Not authenticated.';
    try {
      await _client.from('obligations').insert({
        'user_id': user.id,
        'center_id': centerId,
        'title': title,
        'amount': amount,
        'currency': currency.toUpperCase(),
        'type': type,
        'due_date': dueDate,
        'goal_amount': goalAmount,
      });
      await refreshAll();
      return null;
    } catch (e) {
      return AppErrorMapper.toMessage(e);
    }
  }

  Future<String?> deleteObligation(String id) async {
    try {
      await _client.from('obligations').delete().eq('id', id);
      await refreshAll();
      return null;
    } catch (e) {
      return AppErrorMapper.toMessage(e);
    }
  }

  Future<String?> toggleObligation({
    required String obligationId,
    required bool isCompleted,
  }) async {
    try {
      await _client.functions.invoke(
        'toggle-obligation',
        body: {'obligation_id': obligationId, 'is_completed': isCompleted},
      );
      await refreshAll();
      return null;
    } catch (_) {
      try {
        await _client.from('obligations').update({
          'is_completed': isCompleted,
          'completed_at': isCompleted ? DateTime.now().toIso8601String() : null,
        }).eq('id', obligationId);
        await refreshAll();
        return null;
      } catch (e) {
        return AppErrorMapper.toMessage(e);
      }
    }
  }

  Future<String?> addRemittance({
    required String centerId,
    String? obligationId,
    required double amount,
    required String currency,
    String? purpose,
    String? targetCurrency,
    double? exchangeRate,
  }) async {
    final user = currentUser;
    if (user == null) return 'Not authenticated.';
    final now = DateTime.now();
    try {
      await _client.from('remittances').insert({
        'user_id': user.id,
        'center_id': centerId,
        'obligation_id': obligationId,
        'date': '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
        'time': '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
        'amount': amount,
        'currency': currency.toUpperCase(),
        'target_currency': (targetCurrency ?? currency).toUpperCase(),
        'exchange_rate': exchangeRate ?? 1,
        'purpose': purpose,
      });
      await refreshAll();
      return null;
    } catch (e) {
      return AppErrorMapper.toMessage(e);
    }
  }

  Future<String?> deleteRemittance(String id) async {
    try {
      await _client.from('remittances').delete().eq('id', id);
      await refreshAll();
      return null;
    } catch (e) {
      return AppErrorMapper.toMessage(e);
    }
  }

  Future<String?> addSavings({
    required double amount,
    required String currency,
    required String type,
    String? note,
  }) async {
    final user = currentUser;
    if (user == null) return 'Not authenticated.';
    final now = DateTime.now();
    try {
      await _client.from('savings_log').insert({
        'user_id': user.id,
        'date': '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
        'amount': amount,
        'currency': currency.toUpperCase(),
        'type': type,
        'note': note,
      });
      await refreshAll();
      return null;
    } catch (e) {
      return AppErrorMapper.toMessage(e);
    }
  }

  Future<String?> resetCycle(String cycleMonth) async {
    try {
      await _client.functions.invoke('reset-cycle', body: {'cycle_month': cycleMonth});
      await refreshAll();
      return null;
    } catch (e) {
      return AppErrorMapper.toMessage(e);
    }
  }

  Future<String?> resetAllData() async {
    final user = currentUser;
    if (user == null) return 'Not authenticated.';
    try {
      await _client.from('remittances').delete().eq('user_id', user.id);
      await _client.from('savings_log').delete().eq('user_id', user.id);
      await _client.from('obligations').delete().eq('user_id', user.id);
      await _client.from('responsibility_centers').delete().eq('user_id', user.id);
      await _client.from('profiles').update({'onboarded': false}).eq('id', user.id);
      await refreshAll();
      return null;
    } catch (e) {
      return AppErrorMapper.toMessage(e);
    }
  }

  Future<List<Map<String, dynamic>>> loadForecast() async {
    final result = await _client.functions.invoke(
      'forecast',
      method: HttpMethod.get,
      queryParameters: {'months': '6', 'include_probability': 'true'},
    );
    final data = result.data;
    if (data is List) {
      return data.cast<Map<String, dynamic>>();
    }
    return [];
  }
}
