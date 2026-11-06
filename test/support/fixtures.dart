import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:ecommerce_clean_app/core/network/api_client.dart';

const productJson = <String, dynamic>{
  'id': 1,
  'title': 'Test shirt',
  'description': 'A comfortable shirt',
  'category': 'clothing',
  'price': 0.10,
  'image': 'https://example.com/shirt.png',
};

/// Controlled HTTP transport: no public API requests are made in tests.
class FixtureAdapter implements HttpClientAdapter {
  int status = 200;
  Object? data;
  DioExceptionType? failure;
  FixtureAdapter({this.data});
  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    if (failure != null) {
      throw DioException(requestOptions: options, type: failure!);
    }
    return ResponseBody.fromString(data?.toString() ?? '[]', status, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType]
    });
  }

  @override
  void close({bool force = false}) {}
}

ApiClient fixtureClient(FixtureAdapter adapter) {
  final dio = ApiClient.createDio()..httpClientAdapter = adapter;
  return ApiClient(dio);
}
