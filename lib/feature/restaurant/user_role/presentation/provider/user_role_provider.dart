import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../auth/presentation/provider/branch_auth_provider.dart';
import '../../data/datasource/user_role_datasource.dart';
import '../../data/model/user_model.dart';


final branchUserDatasourceProvider = Provider<BranchUserDatasource>((ref) {
  return BranchUserDatasource(Supabase.instance.client);
});

class BranchUserState {
  final List<BranchUserModel> users;
  final bool isLoading;
  final String? errorMessage;

  const BranchUserState({
    this.users = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  BranchUserState copyWith({
    List<BranchUserModel>? users,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) => BranchUserState(
    users:        users        ?? this.users,
    isLoading:    isLoading    ?? this.isLoading,
    errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
  );
}

class BranchUserNotifier extends StateNotifier<BranchUserState> {
  final BranchUserDatasource _ds;
  final String _branchId;

  BranchUserNotifier(this._ds, this._branchId) : super(const BranchUserState()) {
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final users = await _ds.fetchUsers(_branchId);
      state = state.copyWith(users: users, isLoading: false);
    } catch (e) {
      state = state.copyWith(
          isLoading: false,
          errorMessage: e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> addUser(BranchUserModel user) async {
    try {
      final added = await _ds.addUser(user, _branchId);
      state = state.copyWith(users: [...state.users, added]);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<void> updateUser(BranchUserModel user) async {
    try {
      final updated = await _ds.updateUser(user);
      state = state.copyWith(
        users: state.users.map((u) => u.id == updated.id ? updated : u).toList(),
      );
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<void> toggleStatus(String userId, BranchUserStatus status) async {
    try {
      await _ds.toggleStatus(userId, status);
      state = state.copyWith(
        users: state.users.map((u) {
          if (u.id == userId) u.status = status;
          return u;
        }).toList(),
      );
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<void> deleteUser(String userId) async {
    try {
      await _ds.deleteUser(userId);
      state = state.copyWith(
          users: state.users.where((u) => u.id != userId).toList());
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }
}

final branchUserProvider =
StateNotifierProvider<BranchUserNotifier, BranchUserState>((ref) {
  final ds = ref.watch(branchUserDatasourceProvider);
  final branch = ref.watch(branchAuthProvider).branch!;
  return BranchUserNotifier(ds, branch.branchId);
});