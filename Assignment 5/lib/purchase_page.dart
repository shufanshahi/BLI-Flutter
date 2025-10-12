import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_auth_ui/supabase_auth_ui.dart';

import 'cart_provider.dart';
import 'constants.dart';

class PurchasePage extends StatefulWidget {
  const PurchasePage({Key? key}) : super(key: key);

  static const List<String> itemImages = [
    'assests/images/items/item1.jpeg',
    'assests/images/items/item2.jpeg',
    'assests/images/items/item3.jpeg',
    'assests/images/items/item4.jpeg',
  ];

  static const int itemPrice = 100;

  @override
  _PurchasePageState createState() => _PurchasePageState();
}

class _PurchasePageState extends State<PurchasePage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Removed _loadProfile() to keep fields empty
  }

  Future<void> _loadProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        final response = await Supabase.instance.client
            .from('profiles')
            .select()
            .eq('user_id', user.id)
            .single();
        setState(() {
          _nameController.text = response['name'] ?? '';
          _addressController.text = response['address'] ?? '';
          _phoneController.text = response['phone_number'] ?? '';
        });
      } catch (e) {
        // No profile found
      }
    }
  }

  void _importFromProfile() {
    _loadProfile();
  }

  void _placeOrder() {
    // For now, just show success
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Order placed successfully!')),
    );
    // Could clear cart here
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Purchase'),
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
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const Text('Cart Items', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                ...cart.entries.map((entry) {
                  final itemIndex = entry.key;
                  final quantity = entry.value;
                  return ListTile(
                    leading: Image.asset(
                      PurchasePage.itemImages[itemIndex],
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    ),
                    title: Text('Item ${itemIndex + 1}'),
                    subtitle: Text('Price: \$${PurchasePage.itemPrice} | Quantity: $quantity | Subtotal: \$${PurchasePage.itemPrice * quantity}'),
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
                }),
                const SizedBox(height: 10),
                Builder(
                  builder: (context) {
                    int total = 0;
                    for (var entry in cart.entries) {
                      total += entry.value * PurchasePage.itemPrice;
                    }
                    return Text(
                      'Total: \$${total}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    );
                  },
                ),
                const SizedBox(height: 20),
                const Text('Delivery Information', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _addressController,
                  decoration: const InputDecoration(labelText: 'Address'),
                  maxLines: 2,
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _phoneController,
                  decoration: const InputDecoration(labelText: 'Phone Number'),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _importFromProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonColor,
                    foregroundColor: Colors.black,
                  ),
                  child: const Text('Import from Profile'),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _placeOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonColor,
                    foregroundColor: Colors.black,
                  ),
                  child: const Text('Place Order'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}