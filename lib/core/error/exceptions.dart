class ServerException implements Exception {
  final String message;

  ServerException(this.message);
}

class CacheException implements Exception {
  final String message;

  CacheException(this.message);
}

class NetworkException implements Exception {
  final String message;

  const NetworkException(this.message);
}
