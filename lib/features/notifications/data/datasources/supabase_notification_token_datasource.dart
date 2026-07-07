class SupabaseNotificationTokenDataSource {
  const SupabaseNotificationTokenDataSource();

  Future<void> upsertToken({
    required String userId,
    required String token,
    required String platform,
  }) async {}
}
