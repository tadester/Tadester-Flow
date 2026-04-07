import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/auth_repository.dart';

final Provider<AuthRepository> authRepositoryProvider =
    Provider<AuthRepository>((Ref ref) {
      return AuthRepository();
    });

final StreamProvider<User?> authStateProvider = StreamProvider<User?>((
  Ref ref,
) async* {
  final GoTrueClient authClient = Supabase.instance.client.auth;

  yield authClient.currentUser;
  yield* authClient.onAuthStateChange.map(
    (AuthState data) => data.session?.user,
  );
});
