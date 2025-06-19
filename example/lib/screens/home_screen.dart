import 'package:flutter/material.dart';
import '../models/product.dart';
import '../widgets/product_card.dart';

class HomeScreen extends StatelessWidget {
  HomeScreen({Key? key}) : super(key: key);

  final List<Product> products = [
    Product(
      id: '1',
      title: 'Antidote "13" Tee in Mood Indigo',
      description: 'A long sleeved tissue tee featuring the number 13',
      price: 78.00,
      imageUrl: 'https://karanzi.websites.co.in/obaju-turquoise/img/product-placeholder.png',
    ),
    Product(
      id: '2',
      title: 'Antidote "Joie" Tee in Taupe',
      description: 'Comfortable cotton tee with modern design',
      price: 78.00,
      imageUrl: 'https://karanzi.websites.co.in/obaju-turquoise/img/product-placeholder.png',
    ),
    // Add more products as needed
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: products.length,
        itemBuilder: (context, index) {
          return ProductCard(product: products[index]);
        },
      ),
    );
  }
} 