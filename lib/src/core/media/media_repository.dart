import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_platform/src/core/errors/app_failure.dart';
import 'package:school_platform/src/core/providers.dart';
import 'package:school_platform/src/features/auth/data/auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Signed URLs for the private `school-media` bucket.
///
/// Storage policies decide who may read which object; a signed URL is only
/// issued when the caller is allowed to read it.
class MediaRepository {
  MediaRepository(this._client, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  static const bucket = 'school-media';
  static const _ttl = Duration(hours: 1);

  /// Re-sign a little before expiry so images never break mid-session.
  static const _refreshMargin = Duration(minutes: 10);

  final SupabaseClient _client;
  final DateTime Function() _clock;
  final _cache = <String, ({String url, DateTime expiresAt})>{};

  Future<String> signedUrl(String path) async {
    final cached = _cache[path];
    final now = _clock();
    if (cached != null && now.isBefore(cached.expiresAt)) return cached.url;
    try {
      final url = await _client.storage
          .from(bucket)
          .createSignedUrl(path, _ttl.inSeconds);
      _cache[path] = (url: url, expiresAt: now.add(_ttl - _refreshMargin));
      return url;
    } on Object catch (e) {
      throw AppFailure.from(e);
    }
  }

  void clear() => _cache.clear();
}

/// Recreated per signed-in user so cached signed URLs never outlive the
/// session that was authorised to read them.
final mediaRepositoryProvider = Provider<MediaRepository>((ref) {
  ref.watch(currentUserIdProvider);
  return MediaRepository(ref.watch(supabaseClientProvider));
});

final signedUrlProvider = FutureProvider.autoDispose.family<String, String>(
  (ref, path) => ref.watch(mediaRepositoryProvider).signedUrl(path),
);

/// A circular avatar for a storage object path, with an initials fallback.
class StorageAvatar extends ConsumerWidget {
  const StorageAvatar({
    required this.path,
    required this.fallbackText,
    super.key,
    this.radius = 22,
    this.backgroundColor,
  });

  final String? path;
  final String fallbackText;
  final double radius;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final fallback = CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor ?? scheme.primaryContainer,
      child: Text(
        initials(fallbackText),
        style: TextStyle(
          color: scheme.onPrimaryContainer,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
    final objectPath = path;
    if (objectPath == null || objectPath.isEmpty) return fallback;

    final url = ref.watch(signedUrlProvider(objectPath)).value;
    if (url == null) return fallback;
    return ExcludeSemantics(
      child: CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor ?? scheme.primaryContainer,
        foregroundImage: NetworkImage(url),
        onForegroundImageError: (_, _) {},
        child: Text(initials(fallbackText)),
      ),
    );
  }
}

/// Up to two initials for an avatar placeholder.
String initials(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((p) => p.isNotEmpty)
      .toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first.characters.first.toUpperCase();
  return (parts.first.characters.first + parts.last.characters.first)
      .toUpperCase();
}
