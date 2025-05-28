import 'package:hooks_riverpod/hooks_riverpod.dart';

/// ログイン状態を管理する StateProvider（最初は未ログイン）
final authProvider = StateProvider<bool>((ref) => false);
