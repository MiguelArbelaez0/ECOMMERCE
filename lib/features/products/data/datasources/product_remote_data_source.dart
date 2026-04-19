import 'package:dio/dio.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../models/product_model.dart';

abstract class ProductRemoteDataSource {
  Future<List<ProductModel>> getProducts();

  Future<ProductModel> getProductById(int id);
}

class ProductRemoteDataSourceImpl implements ProductRemoteDataSource {
  final ApiClient apiClient;

  ProductRemoteDataSourceImpl(this.apiClient);

  @override
  Future<List<ProductModel>> getProducts() async {
    try {
      final Response<dynamic> response = await apiClient.dio.get('/products');
      final List<dynamic> data = response.data as List<dynamic>;
      return data
          .map((item) => ProductModel.fromJson(item as Map<String, dynamic>))
          .toList(growable: false);
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data.toString() ??
            e.message ??
            'Failed to fetch products from server',
      );
    }
  }

  @override
  Future<ProductModel> getProductById(int id) async {
    try {
      final Response<dynamic> response = await apiClient.dio.get('/products/$id');
      return ProductModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data.toString() ??
            e.message ??
            'Failed to fetch product details',
      );
    }
  }
}
