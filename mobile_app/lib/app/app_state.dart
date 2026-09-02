import 'dart:async';

import 'package:finpat_mobile/core/errors/app_error_mapper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class AppStateController extends ChangeNotifier {
  AppStateController(this._client);

  final SupabaseClient _client;

  // ── Loading / error ───────────────────────────────────────────────────────
  bool initializing = true;
  bool loading = false;
  bool summaryLoading = false;
  String? error;

  // ── Data ──────────────────────────────────────────────────────────────────
  Map<String, dynamic>? profile;
  List<Map<String, dynamic>> centers = [];
  List<Map<String, dynamic>> obligations = [];
  List<Map<String, dynamic>> remittances = [];
  List<Map<String, dynamic>> savings = [];

  /// Pre-aggregated, FX-adjusted Home screen data from `dashboard-summary`.
  /// Always prefer these values over client-side recomputation.
  Map<String, dynamic>? dashboardSummary;

  /// Tracks whether the FX cache has been warmed this session.
  bool _fxWarmed = false;

  /// Guard against concurrent bootstrap() runs.
  /// The supabase auth stream fires immediately on subscribe, which would cause
  /// a second bootstrap() to launch before the first one finishes.
  bool _bootstrapping = false;

  // ── Auth helpers ──────────────────────────────────────────────────────────
  User? get currentUser => _client.auth.currentUser;
  bool get isLoggedIn => currentUser != null;
  bool get isOnboarded => (profile?['onboarded'] as bool?) ?? false;

  // ── Bootstrap ─────────────────────────────────────────────────────────────
  Future<void> bootstrap() async {
    // Prevent a second concurrent bootstrap (e.g. from the auth stream firing
    // immediately on subscribe while initState also calls bootstrap).
    if (_bootstrapping) return;
    _bootstrapping = true;
    initializing = true;
    error = null;
    notifyListeners();
    try {
      if (!isLoggedIn) return;
      // refreshAll already runs the summary in parallel — no extra call needed.
      await refreshAll();
      await warmExchangeRates();
    } catch (e) {
      error = AppErrorMapper.toMessage(e);
    } finally {
      initializing = false;
      _bootstrapping = false;
      notifyListeners();
    }
  }

  // ── FX cache warm ─────────────────────────────────────────────────────────
  /// Warms the server-side `currency_rates` cache used by `toggle-obligation`.
  /// Best-effort — failure is silent so it never blocks sign-in.
  Future<void> warmExchangeRates() async {
    if (_fxWarmed) return;
    try {
      final incomeCurrency =
          (profile?['income_currency'] as String?)?.toUpperCase() ?? 'USD';
      await _client.functions.invoke(
        'exchange-rates',
        method: HttpMethod.get,
        queryParameters: {'base': incomeCurrency},
      );
      _fxWarmed = true;
    } catch (_) {
      // Best-effort; don't surface this error to the user.
    }
  }

  // ── Dashboard summary ─────────────────────────────────────────────────────
  /// Loads pre-aggregated, FX-adjusted Home metrics for [cycleMonth].
  /// Defaults to the current month (YYYY-MM).
  Future<void> loadDashboardSummary([String? cycleMonth]) async {
    final now = DateTime.now();
    final cycle = cycleMonth ??
        '${now.year}-${now.month.toString().padLeft(2, '0')}';
    summaryLoading = true;
    notifyListeners();
    try {
      final result = await _client.functions.invoke(
        'dashboard-summary',
        method: HttpMethod.get,
        queryParameters: {'cycle': cycle},
      );
      final data = result.data;
      if (data is Map<String, dynamic>) {
        dashboardSummary = data;
      }
    } catch (_) {
      // Silent — summary is derived data; a failure here should never
      // surface an error banner or block the Home screen.
    } finally {
      summaryLoading = false;
      notifyListeners();
    }
  }

  // ── Full refresh ──────────────────────────────────────────────────────────
  /// Fetches all tables AND dashboard-summary in one parallel batch.
  /// A summary failure is non-fatal — it won't surface an error banner.
  Future<void> refreshAll() async {
    final user = currentUser;
    if (user == null) return;
    final now = DateTime.now();
    final cycle = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    loading = true;
    summaryLoading = true;
    error = null;
    notifyListeners();
    try {
      // Run all 5 table fetches + dashboard-summary edge function in parallel.
      // The summary is best-effort — we swallow its failure so it never blocks.
      final results = await Future.wait<dynamic>([
        _client.from('profiles').select().eq('id', user.id).maybeSingle(),
        _client
            .from('responsibility_centers')
            .select()
            .eq('user_id', user.id)
            .order('created_at', ascending: true),
        _client
            .from('obligations')
            .select()
            .eq('user_id', user.id)
            .order('created_at', ascending: false),
        _client
            .from('remittances')
            .select()
            .eq('user_id', user.id)
            .order('created_at', ascending: false),
        _client
            .from('savings_log')
            .select()
            .eq('user_id', user.id)
            .order('created_at', ascending: false),
        _fetchSummaryQuietly(cycle), // index 5 — non-fatal
      ]);

      profile = results[0] as Map<String, dynamic>?;
      centers = (results[1] as List).cast<Map<String, dynamic>>();
      obligations = (results[2] as List).cast<Map<String, dynamic>>();
      remittances = (results[3] as List).cast<Map<String, dynamic>>();
      savings = (results[4] as List).cast<Map<String, dynamic>>();
      final summaryData = results[5] as Map<String, dynamic>?;
      if (summaryData != null) dashboardSummary = summaryData;
    } catch (e) {
      error = AppErrorMapper.toMessage(e);
    } finally {
      loading = false;
      summaryLoading = false;
      notifyListeners();
    }
  }

  /// Fetches the dashboard-summary edge function silently (never throws).
  Future<Map<String, dynamic>?> _fetchSummaryQuietly(String cycle) async {
    try {
      final result = await _client.functions.invoke(
        'dashboard-summary',
        method: HttpMethod.get,
        queryParameters: {'cycle': cycle},
      );
      final data = result.data;
      return data is Map<String, dynamic> ? data : null;
    } catch (_) {
      return null;
    }
  }

  // ── Auth ──────────────────────────────────────────────────────────────────
  Future<String?> signIn(String email, String password) async {
    try {
      _fxWarmed = false; // reset before auth fires so bootstrap re-warms
      await _client.auth.signInWithPassword(email: email, password: password);
      // Set initializing=true immediately to prevent a brief OnboardingScreen
      // flash in the gap before the auth-state listener fires bootstrap().
      initializing = true;
      _bootstrapping = false; // allow the listener's bootstrap() to run
      notifyListeners();
      return null;
    } catch (e) {
      return AppErrorMapper.toMessage(e);
    }
  }

  Future<String?> signUp(String name, String email, String password) async {
    try {
      _fxWarmed = false;
      await _client.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': name},
      );
      initializing = true;
      _bootstrapping = false;
      notifyListeners();
      return null;
    } catch (e) {
      return AppErrorMapper.toMessage(e);
    }
  }

  Future<void> signOut() async {
    _bootstrapping = false; // allow bootstrap after next sign-in
    await _client.auth.signOut();
    _clearSession();
  }

  /// Drops every trace of the signed-in user from memory.
  void _clearSession() {
    profile = null;
    centers = [];
    obligations = [];
    remittances = [];
    savings = [];
    dashboardSummary = null;
    _fxWarmed = false;
    notifyListeners();
  }

  /// Permanently deletes the account and everything belonging to it.
  ///
  /// Removing the auth record requires the service-role key, so the work is
  /// done by the `delete-account` edge function; this only reacts to the
  /// result. Returns null on success, or a message to show the user.
  Future<String?> deleteAccount() async {
    if (currentUser == null) return 'Not authenticated.';
    try {
      final result = await _client.functions.invoke('delete-account');
      final data = result.data;
      if (data is Map && data['error'] != null) {
        return data['error'].toString();
      }

      // The auth record is gone, so the access token is already dead and
      // signOut may legitimately fail. Local state has to be cleared either way.
      _bootstrapping = false;
      try {
        await _client.auth.signOut();
      } catch (_) {
        // Expected once the user no longer exists server-side.
      }
      _clearSession();
      return null;
    } catch (e) {
      return AppErrorMapper.toMessage(e);
    }
  }

  // ── Onboarding ────────────────────────────────────────────────────────────
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

      // Immediately reflect onboarded=true in local state so AuthGate
      // redirects to HomeShell without waiting for the refreshAll round-trip.
      profile = {
        ...(profile ?? {}),
        'id': user.id,
        'email': user.email,
        'name': profile?['name'] ?? user.userMetadata?['full_name'],
        'onboarded': true,
        'work_location': workLocation,
        'family_location': familyLocation,
        'income_amount': incomeAmount,
        'income_currency': incomeCurrency.toUpperCase(),
        'income_frequency': incomeFrequency,
      };
      notifyListeners();

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

      // Re-warm FX with the new income currency, then refresh everything.
      _fxWarmed = false;
      await warmExchangeRates();
      await refreshAll();
      return null;
    } catch (e) {
      return AppErrorMapper.toMessage(e);
    }
  }

  // ── Centers ───────────────────────────────────────────────────────────────
  Future<String?> addCenter({
    required String name,
    required String color,
    String icon = 'home',
  }) async {
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
      // Only the centers list changed — no need for a full 5-table refresh.
      await _refreshCenters();
      return null;
    } catch (e) {
      return AppErrorMapper.toMessage(e);
    }
  }

  Future<String?> deleteCenter(String id) async {
    try {
      await _client.from('responsibility_centers').delete().eq('id', id);
      // Only the centers list changed.
      await _refreshCenters();
      return null;
    } catch (e) {
      return AppErrorMapper.toMessage(e);
    }
  }

  // ── Obligations ───────────────────────────────────────────────────────────
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
      // Obligations changed → refresh obligations list + summary in parallel.
      await Future.wait([
        _refreshObligations(),
        loadDashboardSummary(),
      ]);
      return null;
    } catch (e) {
      return AppErrorMapper.toMessage(e);
    }
  }

  Future<String?> deleteObligation(String id) async {
    try {
      await _client.from('obligations').delete().eq('id', id);
      // Obligations changed → refresh obligations list + summary in parallel.
      await Future.wait([
        _refreshObligations(),
        loadDashboardSummary(),
      ]);
      return null;
    } catch (e) {
      return AppErrorMapper.toMessage(e);
    }
  }

  /// Toggles obligation completion.
  /// Tries the `toggle-obligation` edge function first (FX-aware).
  /// Falls back to direct PostgREST writes when the function is unavailable.
  Future<String?> toggleObligation({
    required String obligationId,
    required bool isCompleted,
  }) async {
    // ── Optimistic update ────────────────────────────────────────────────────
    final idx = obligations.indexWhere((o) => o['id'] == obligationId);
    Map<String, dynamic>? original;
    if (idx != -1) {
      original = Map<String, dynamic>.from(obligations[idx]);
      obligations = List<Map<String, dynamic>>.from(obligations);
      obligations[idx] = {
        ...obligations[idx],
        'is_completed': isCompleted,
        'completed_at':
            isCompleted ? DateTime.now().toIso8601String() : null,
      };
      notifyListeners();
    }

    try {
      // Prefer the edge function — it stores the live FX rate.
      try {
        await _client.functions.invoke(
          'toggle-obligation',
          body: {'obligation_id': obligationId, 'is_completed': isCompleted},
        );
      } on FunctionException catch (_) {
        // Edge function not deployed yet — fall back to direct DB writes.
        await _toggleObligationFallback(
          obligationId: obligationId,
          isCompleted: isCompleted,
        );
      }
      // Reconcile with server — refresh obligations, remittances, and summary.
      await Future.wait([
        _refreshObligations(),
        _refreshRemittances(),
        loadDashboardSummary(),
      ]);
      return null;
    } catch (e) {
      // Revert optimistic update on failure.
      if (idx != -1 && original != null) {
        obligations = List<Map<String, dynamic>>.from(obligations);
        obligations[idx] = original;
        notifyListeners();
      }
      return AppErrorMapper.toMessage(e);
    }
  }

  /// Static fallback rates (units of currency per 1 USD).
  /// Mirrors the server-side FALLBACK_RATES so the fallback code path also
  /// produces correct conversions when the DB cache is empty or stale.
  static const Map<String, double> _fallbackRatesFromUsd = {
    'USD': 1.0,
    'EUR': 0.92,
    'GBP': 0.79,
    'AED': 3.67,
    'INR': 83.12,
    'PHP': 56.45,
    'PKR': 278.5,
    'EGP': 30.91,
    'MYR': 4.78,
    'SGD': 1.35,
    'IDR': 16150,
    'THB': 36.15,
    'VND': 24500,
    'BND': 1.35,
    'MMK': 2100,
    'KHR': 4100,
    'LAK': 21000,
  };

  /// Derives a cross-rate via USD from the static fallback table.
  /// Returns null if either currency is unknown.
  double? _staticFallbackRate(String from, String to) {
    if (from == to) return 1.0;
    final fromPerUsd = _fallbackRatesFromUsd[from.toUpperCase()];
    final toPerUsd = _fallbackRatesFromUsd[to.toUpperCase()];
    if (fromPerUsd == null || toPerUsd == null) return null;
    return toPerUsd / fromPerUsd;
  }

  /// Resolves the exchange rate from [fromCurrency] to [toCurrency].
  ///
  /// Priority:
  ///   1. Live DB cache  (direct pair)
  ///   2. Live DB cache  (inverse pair → reciprocal)
  ///   3. Static fallback table (cross-rate via USD)
  ///   4. 1.0 last-resort (unknown currency pair)
  Future<double> _lookupExchangeRate(
    String fromCurrency,
    String toCurrency,
  ) async {
    if (fromCurrency == toCurrency) return 1.0;

    // Fetch both the direct (from→to) and reverse (to→from) pairs in one call.
    final rows = await _client
        .from('currency_rates')
        .select('from_currency, to_currency, rate')
        .or(
          'and(from_currency.eq.$fromCurrency,to_currency.eq.$toCurrency),'
          'and(from_currency.eq.$toCurrency,to_currency.eq.$fromCurrency)',
        );

    for (final row in (rows as List)) {
      if (row['from_currency'] == fromCurrency &&
          row['to_currency'] == toCurrency &&
          row['rate'] != null) {
        return (row['rate'] as num).toDouble();
      }
    }
    for (final row in (rows as List)) {
      if (row['from_currency'] == toCurrency &&
          row['to_currency'] == fromCurrency &&
          row['rate'] != null) {
        final reverseRate = (row['rate'] as num).toDouble();
        if (reverseRate > 0) return 1.0 / reverseRate;
      }
    }

    // No cached rate found — use static fallback before giving up with 1.0.
    // This prevents a missing cache from making e.g. Rs 50,000 appear as $50,000.
    return _staticFallbackRate(fromCurrency, toCurrency) ?? 1.0;
  }

  /// Direct PostgREST fallback used when `toggle-obligation` edge function
  /// is not yet deployed.
  Future<void> _toggleObligationFallback({
    required String obligationId,
    required bool isCompleted,
  }) async {
    final user = currentUser;
    if (user == null) return;
    final now = DateTime.now();
    final today =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    // 1. Update the obligation row.
    await _client.from('obligations').update({
      'is_completed': isCompleted,
      'completed_at': isCompleted ? now.toIso8601String() : null,
    }).eq('id', obligationId);

    if (isCompleted) {
      // 2. Insert a remittance row so spent totals are tracked.
      final obl = obligations.firstWhere(
        (o) => o['id'] == obligationId,
        orElse: () => {},
      );
      if (obl.isNotEmpty) {
        final oblCurrency =
            ((obl['currency'] as String?) ?? 'USD').toUpperCase();
        final incomeCurrency =
            (profile?['income_currency'] as String?)?.toUpperCase() ?? 'USD';

        final exchangeRate =
            await _lookupExchangeRate(oblCurrency, incomeCurrency);

        await _client.from('remittances').insert({
          'user_id': user.id,
          'center_id': obl['center_id'],
          'obligation_id': obligationId,
          'date': today,
          'time':
              '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
          'amount': obl['amount'],
          'currency': oblCurrency,
          'target_currency': incomeCurrency,
          'exchange_rate': exchangeRate,
          'purpose': obl['title'],
        });
      }
    } else {
      // 3. Remove all remittances linked to this obligation.
      await _client
          .from('remittances')
          .delete()
          .eq('obligation_id', obligationId)
          .eq('user_id', user.id);
    }
  }

  // ── Private targeted refreshes ────────────────────────────────────────────

  Future<void> _refreshCenters() async {
    final user = currentUser;
    if (user == null) return;
    try {
      final result = await _client
          .from('responsibility_centers')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: true);
      centers = (result as List).cast<Map<String, dynamic>>();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _refreshObligations() async {
    final user = currentUser;
    if (user == null) return;
    try {
      final result = await _client
          .from('obligations')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);
      obligations = (result as List).cast<Map<String, dynamic>>();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _refreshRemittances() async {
    final user = currentUser;
    if (user == null) return;
    try {
      final result = await _client
          .from('remittances')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);
      remittances = (result as List).cast<Map<String, dynamic>>();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _refreshSavings() async {
    final user = currentUser;
    if (user == null) return;
    try {
      final result = await _client
          .from('savings_log')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);
      savings = (result as List).cast<Map<String, dynamic>>();
      notifyListeners();
    } catch (_) {}
  }

  // ── Remittances ───────────────────────────────────────────────────────────
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
        'date':
            '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
        'time':
            '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
        'amount': amount,
        'currency': currency.toUpperCase(),
        'target_currency': (targetCurrency ?? currency).toUpperCase(),
        'exchange_rate': exchangeRate ?? 1,
        'purpose': purpose,
      });
      // Only remittances + summary changed — skip the full refresh.
      await Future.wait([
        _refreshRemittances(),
        loadDashboardSummary(),
      ]);
      return null;
    } catch (e) {
      return AppErrorMapper.toMessage(e);
    }
  }

  Future<String?> deleteRemittance(String id) async {
    try {
      await _client.from('remittances').delete().eq('id', id);
      // Only remittances + summary changed.
      await Future.wait([
        _refreshRemittances(),
        loadDashboardSummary(),
      ]);
      return null;
    } catch (e) {
      return AppErrorMapper.toMessage(e);
    }
  }

  // ── Savings ───────────────────────────────────────────────────────────────
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
        'date':
            '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
        'amount': amount,
        'currency': currency.toUpperCase(),
        'type': type,
        'note': note,
      });
      // Refresh savings + summary only.
      await Future.wait([
        _refreshSavings(),
        loadDashboardSummary(),
      ]);
      return null;
    } catch (e) {
      return AppErrorMapper.toMessage(e);
    }
  }

  // ── Reset cycle ───────────────────────────────────────────────────────────
  Future<({String? error, Map<String, dynamic>? data})> resetCycle(
      String cycleMonth) async {
    try {
      final result = await _client.functions.invoke(
        'reset-cycle',
        body: {'cycle_month': cycleMonth},
      );
      final data = result.data;
      final responseData = data is Map<String, dynamic> ? data : null;
      // After reset, refresh everything for the new cycle.
      await refreshAll();
      return (error: null, data: responseData);
    } catch (e) {
      return (error: AppErrorMapper.toMessage(e), data: null);
    }
  }

  // ── Data reset (dev/settings) ─────────────────────────────────────────────
  Future<String?> resetAllData() async {
    final user = currentUser;
    if (user == null) return 'Not authenticated.';
    try {
      // Delete leaf tables first (remittances/savings reference obligations),
      // then obligations, then centers, then update profile.
      await Future.wait([
        _client.from('remittances').delete().eq('user_id', user.id),
        _client.from('savings_log').delete().eq('user_id', user.id),
      ]);
      await _client.from('obligations').delete().eq('user_id', user.id);
      await _client
          .from('responsibility_centers')
          .delete()
          .eq('user_id', user.id);
      await _client
          .from('profiles')
          .update({'onboarded': false}).eq('id', user.id);
      dashboardSummary = null;
      await refreshAll();
      return null;
    } catch (e) {
      return AppErrorMapper.toMessage(e);
    }
  }

  // ── Forecast ──────────────────────────────────────────────────────────────
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
