import 'package:equatable/equatable.dart';

class Product extends Equatable {
  final int id;
  final String title;
  final String description;
  final String category;
  final double price;
  final String image;

  const Product({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.price,
    required this.image,
  });

  @override
  List<Object?> get props => [id, title, description, category, price, image];
}
