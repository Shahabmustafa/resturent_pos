import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/customer_datasource.dart';

final customerDatasourceProvider = Provider<CustomerDatasource>((_) => CustomerDatasource(Supabase.instance.client));

/// Live menu from the POS. `ref.invalidate(customerMenuProvider)` to reload.
final customerMenuProvider = FutureProvider<CustomerMenu>((ref) => ref.watch(customerDatasourceProvider).fetchMenu());

/// Token from a table's QR code (website opened at `?table=<token>`), or null.
final tableQrToken = kIsWeb ? Uri.base.queryParameters['table'] : null;

/// The table this visitor is sitting at, from its QR code. null = normal
/// website visit (or an invalid code), so delivery/takeaway ordering applies.
final tableSessionProvider = FutureProvider<String?>((ref) async {
  final token = tableQrToken;
  if (token == null || token.isEmpty) return null;
  return ref.watch(customerDatasourceProvider).tableForQr(token);
});

/// Signed-in website customer (Supabase Auth), or null. Ordering requires one.
final customerUserProvider = StreamProvider<User?>((ref) {
  final auth = Supabase.instance.client.auth;
  // Re-emit on profile edits too (same user, new updatedAt), not only on sign in/out.
  return auth.onAuthStateChange
      .map((e) => e.session?.user)
      .distinct((a, b) => a?.id == b?.id && a?.updatedAt == b?.updatedAt);
});

/// The signed-in customer's orders (live), or null when nobody is signed in.
final myOrdersProvider = StreamProvider<List<CustomerOrder>?>((ref) {
  // Only the user id matters here, so profile edits don't restart the stream.
  final userId = ref.watch(customerUserProvider.select((u) => u.value?.id));
  if (userId == null) return Stream.value(null);
  return ref.watch(customerDatasourceProvider).watchMyOrders(userId);
});

/// Public customer feedback for the home page. Invalidate after a new rating.
final publicFeedbackProvider = FutureProvider<FeedbackSummary>(
  (ref) => ref.watch(customerDatasourceProvider).fetchFeedback(),
);

/// Opening hours as set in the POS (Settings → Company → Working hours).
final openingHoursProvider = FutureProvider<OpeningHoursInfo>(
  (ref) => ref.watch(customerDatasourceProvider).fetchOpeningHours(),
);

/// Result of a register attempt: signed in right away, or the project requires
/// the customer to confirm their email first.
enum SignUpResult { signedIn, confirmEmail }

class CustomerAuth {
  CustomerAuth._();

  static GoTrueClient get _auth => Supabase.instance.client.auth;

  static Future<void> signIn(String email, String password) async {
    try {
      await _auth.signInWithPassword(email: email.trim(), password: password);
    } on AuthException catch (e) {
      throw _friendly(e);
    }
  }

  static Future<SignUpResult> signUp({
    required String name,
    required String phone,
    required String email,
    required String password,
  }) async {
    try {
      final res = await _auth.signUp(
        email: email.trim(),
        password: password,
        data: {'full_name': name.trim(), 'phone': phone.trim(), 'account_type': 'customer'},
      );
      return res.session != null ? SignUpResult.signedIn : SignUpResult.confirmEmail;
    } on AuthException catch (e) {
      throw _friendly(e);
    }
  }

  static Future<void> signOut() => _auth.signOut();

  /// Saves the profile fields (also used to pre-fill checkout).
  static Future<void> updateProfile({required String name, required String phone, required String address}) async {
    try {
      await _auth.updateUser(
        UserAttributes(data: {'full_name': name.trim(), 'phone': phone.trim(), 'address': address.trim()}),
      );
    } on AuthException catch (e) {
      throw _friendly(e);
    }
  }

  /// Uploads a new profile photo to `avatars/<user id>/` and saves its URL on the
  /// account, then removes the previous photo. Returns the new URL.
  static Future<String> uploadAvatar(Uint8List bytes, String mimeType) async {
    final user = _auth.currentUser;
    if (user == null) throw 'Please log in first.';
    final storage = Supabase.instance.client.storage.from('avatars');
    final ext = switch (mimeType) {
      'image/png' => 'png',
      'image/webp' => 'webp',
      _ => 'jpg',
    };
    // A new name each time, so browsers don't keep showing a cached old photo.
    final path = '${user.id}/avatar-${DateTime.now().millisecondsSinceEpoch}.$ext';
    try {
      await storage.uploadBinary(path, bytes, fileOptions: FileOptions(contentType: mimeType));
      final url = storage.getPublicUrl(path);
      final oldPath = _avatarPath(user.avatarUrl);
      await _auth.updateUser(UserAttributes(data: {'avatar_url': url}));
      if (oldPath != null) await storage.remove([oldPath]).catchError((_) => <FileObject>[]);
      return url;
    } on StorageException catch (e) {
      throw e.message.toLowerCase().contains('size') ? 'Photo is too large — please use one under 2 MB.' : e.message;
    } on AuthException catch (e) {
      throw _friendly(e);
    }
  }

  /// Removes the profile photo (falls back to the initial).
  static Future<void> removeAvatar() async {
    final user = _auth.currentUser;
    if (user == null) return;
    final oldPath = _avatarPath(user.avatarUrl);
    try {
      await _auth.updateUser(UserAttributes(data: {'avatar_url': null}));
    } on AuthException catch (e) {
      throw _friendly(e);
    }
    if (oldPath != null) {
      await Supabase.instance.client.storage.from('avatars').remove([oldPath]).catchError((_) => <FileObject>[]);
    }
  }

  /// `…/object/public/avatars/<uid>/avatar-1.jpg` → `<uid>/avatar-1.jpg`.
  static String? _avatarPath(String url) {
    const marker = '/object/public/avatars/';
    final i = url.indexOf(marker);
    return i < 0 ? null : Uri.decodeComponent(url.substring(i + marker.length));
  }

  static Future<void> changePassword(String newPassword) async {
    try {
      await _auth.updateUser(UserAttributes(password: newPassword));
    } on AuthException catch (e) {
      throw _friendly(e);
    }
  }

  static String _friendly(AuthException e) {
    final m = e.message.toLowerCase();
    if (m.contains('invalid login')) return 'Incorrect email or password.';
    if (m.contains('already registered') || m.contains('already exists')) {
      return 'An account with this email already exists — please log in.';
    }
    if (m.contains('email not confirmed')) return 'Please confirm your email first (check your inbox).';
    if (m.contains('should be different')) return 'The new password must be different from your current one.';
    return e.message;
  }
}

extension CustomerUserX on User {
  String get displayName => (userMetadata?['full_name'] as String?)?.trim().isNotEmpty == true
      ? userMetadata!['full_name'] as String
      : (email ?? '').split('@').first;

  String get contactPhone => (userMetadata?['phone'] as String?) ?? '';

  /// Profile photo URL, or '' when none is set.
  String get avatarUrl => (userMetadata?['avatar_url'] as String?) ?? '';

  /// Default delivery address saved on the profile page.
  String get savedAddress => (userMetadata?['address'] as String?) ?? '';
}
