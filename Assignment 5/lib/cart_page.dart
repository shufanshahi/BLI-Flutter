import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'cart_provider.dart';
import 'constants.dart';

class CartPage extends StatelessWidget {
  const CartPage({Key? key}) : super(key: key);

  static const List<String> itemImages = [
    'assests/images/items/item1.jpeg',
    'assests/images/items/item2.jpeg',
    'assests/images/items/item3.jpeg',
    'assests/images/items/item4.jpeg',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cart'),
        backgroundColor: Color.fromARGB(222, 255, 162, 0),
      ),
      body: Consumer(
        builder: (context, ref, child) {
          final cart = ref.watch(cartProvider);
          if (cart.isEmpty) {
            return const Center(
              child: Text('Your cart is empty'),
            );
          }
          return ListView.builder(
            itemCount: cart.length,
            itemBuilder: (context, index) {
              final itemIndex = cart.keys.elementAt(index);
              final quantity = cart[itemIndex]!;
              return ListTile(
                leading: Image.asset(
                  itemImages[itemIndex],
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                ),
                title: Text('Item ${itemIndex + 1}'),
                subtitle: Text('Quantity: $quantity'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove),
                      style: IconButton.styleFrom(
                        // backgroundColor: buttonColor,
                        foregroundColor: Colors.black,
                      ),
                      onPressed: () {
                        ref.read(cartProvider.notifier).removeFromCart(itemIndex);
                      },
                    ),
                    Text('$quantity'),
                    IconButton(
                      icon: const Icon(Icons.add),
                      style: IconButton.styleFrom(
                        // backgroundColor: buttonColor,
                        foregroundColor: Colors.black,
                      ),
                      onPressed: () {
                        ref.read(cartProvider.notifier).addToCart(itemIndex);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      style: IconButton.styleFrom(
                        // backgroundColor: buttonColor,
                        foregroundColor: Colors.black,
                      ),
                      onPressed: () {
                        ref.read(cartProvider.notifier).removeItem(itemIndex);
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: Consumer(
        builder: (context, ref, child) {
          final cart = ref.watch(cartProvider);
          if (cart.isEmpty) {
            return const SizedBox.shrink();
          }
          return FloatingActionButton.extended(
            onPressed: () {
              Navigator.pushNamed(context, '/purchase');
            },
            backgroundColor: buttonColor,
            foregroundColor: Colors.black,
            label: const Text('Proceed to Purchase'),
            icon: const Icon(Icons.shopping_cart_checkout),
          );
        },
      ),
    );
  }
}