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

  const CompanyAuthState({
    this.company,
    this.isLoading = false,
    this.errorMessage,
  });

  bool get isLoggedIn => company != null;

  CompanyAuthState copyWith({
    CompanyModel? company,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    bool clearCompany = false,
  }) {
    return CompanyAuthState(
      company: clearCompany ? null : company ?? this.company,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class CompanyAuthNotifier extends StateNotifier<CompanyAuthState> {
  final CompanyAuthDatasource _datasource;

  CompanyAuthNotifier(this._datasource) : super(const CompanyAuthState()) {
    _loadSavedCompany();
  }

  Future<void> _loadSavedCompany() async {
    state = state.copyWith(isLoading: true);
    try {
      final company = await _datasource.getSavedCompany();
      state = state.copyWith(company: company, isLoading: false);
    } catch (_) {
      state = state.copyWith(isLoading: false);
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