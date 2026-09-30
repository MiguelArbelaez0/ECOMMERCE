import 'package:ecommerce_clean_app/features/products/data/models/product_model.dart';
import 'package:ecommerce_clean_app/features/products/domain/entities/product.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const model = ProductModel(
    id: 7,
    title: 'Test product',
    description: 'A product for conversion testing',
    category: 'test',
    price: 19.99,
    image: 'https://example.com/product.png',
  );

  test('converts API data to a domain entity', () {
    final entity = model.toEntity();

    expect(entity, isA<Product>());
    expect(entity.id, model.id);
    expect(entity.title, model.title);
    expect(entity.description, model.description);
    expect(entity.category, model.category);
    expect(entity.price, model.price);
    expect(entity.image, model.image);
  });

  test('serializes and parses the Fake Store API fields', () {
    final parsed = ProductModel.fromJson(model.toJson());

    expect(parsed.id, model.id);
    expect(parsed.title, model.title);
    expect(parsed.description, model.description);
    expect(parsed.category, model.category);
    expect(parsed.price, model.price);
    expect(parsed.image, model.image);
  });
}
