/// Local-only streak data until a WordPress endpoint exists.
class StreakRemoteDataSource {
  Future<Map<String, dynamic>?> fetchStreak(String userId) async {
    // TODO(streaks): Wire GET /streaks when backend adds endpoint.
    return null;
  }
}
