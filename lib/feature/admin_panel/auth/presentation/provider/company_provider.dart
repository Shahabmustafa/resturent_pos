import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/datasource/company_datasource.dart';
import '../../data/model/company_model.dart';

final companyAuthDatasourceProvider = Provider<CompanyAuthDatasource>((ref) {
  return CompanyAuthDatasource(Supabase.instance.client);
});

class CompanyAuthState {
  final CompanyModel? company;
  final bool isLoading;
  final String? errorMessage;

  /// True until the saved session has been checked on start-up.
  final bool restoring;

  const CompanyAuthState({
    this.company,
    this.isLoading = false,
    this.errorMessage,
    this.restoring = false,
  });

  bool get isLoggedIn => company != null;

  CompanyAuthState copyWith({
    CompanyModel? company,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    bool clearCompany = false,
    bool? restoring,
  }) {
    return CompanyAuthState(
      company: clearCompany ? null : company ?? this.company,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      restoring: restoring ?? this.restoring,
    );
  }
}

class CompanyAuthNotifier extends StateNotifier<CompanyAuthState> {
  final CompanyAuthDatasource _datasource;

  CompanyAuthNotifier(this._datasource) : super(const CompanyAuthState(restoring: true)) {
    _loadSavedCompany();
  }

  Future<void> _loadSavedCompany() async {
    state = state.copyWith(isLoading: true);
    try {
      final company = await _datasource.getSavedCompany();
      state = state.copyWith(company: company, isLoading: false, restoring: false);
    } catch (_) {
      state = state.copyWith(isLoading: false, restoring: false);
    }
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final company = await _datasource.login(
        email: email,
        password: password,
      );
      state = state.copyWith(company: company, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> logout() async {
    await _datasource.logout();
    state = state.copyWith(clearCompany: true, clearError: true);
  }
}

final companyAuthProvider = StateNotifierProvider<CompanyAuthNotifier, CompanyAuthState>((ref) {
  final datasource = ref.watch(companyAuthDatasourceProvider);
  return CompanyAuthNotifier(datasource);
});