import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:supabase_auth_ui/supabase_auth_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'cart_provider.dart';
import 'constants.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final List<String> carouselImages = [
    'assests/images/carousel/image1.jpeg',
    'assests/images/carousel/image2.jpeg',
    'assests/images/carousel/image3.jpeg',
  ];

  final List<String> itemImages = [
    'assests/images/items/item1.jpeg',
    'assests/images/items/item2.jpeg',
    'assests/images/items/item3.jpeg',
    'assests/images/items/item4.jpeg',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Color.fromARGB(222, 255, 162, 0),
              ),
              child: Text(
                'Menu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Sign Out'),
              onTap: () {
                Supabase.instance.client.auth.signOut();
                Navigator.of(context).pushReplacementNamed('/landing');
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Profile'),
              onTap: () {
                Navigator.of(context).pushNamed('/profile');
              },
            ),
            ListTile(
              leading: const Icon(Icons.shopping_cart),
              title: const Text('Cart'),
              onTap: () {
                Navigator.of(context).pushNamed('/cart');
              },
            ),
            ListTile(
              leading: const Icon(Icons.payment),
              title: const Text('Purchase'),
              onTap: () {
                Navigator.of(context).pushNamed('/purchase');
              },
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          CarouselSlider(
            options: CarouselOptions(
              height: 200.0,
              autoPlay: true,
              enlargeCenterPage: true,
            ),
            items: carouselImages.map((imagePath) {
              return Builder(
                builder: (BuildContext context) {
                  return Container(
                    width: MediaQuery.of(context).size.width,
                    margin: const EdgeInsets.symmetric(horizontal: 5.0),
                    decoration: const BoxDecoration(
                      color: Colors.amber,
                    ),
                    child: Image.asset(
                      imagePath,
                      fit: BoxFit.cover,
                    ),
                  );
                },
              );
            }).toList(),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(10.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10.0,
                mainAxisSpacing: 10.0,
              ),
              itemCount: itemImages.length,
              itemBuilder: (context, index) {
                return Consumer(
                  builder: (context, ref, child) {
                    final cart = ref.watch(cartProvider);
                    final quantity = cart[index] ?? 0;
                    return Card(
                      child: Column(
                        children: [
                          Expanded(
                            child: Image.asset(
                              itemImages[index],
                              fit: BoxFit.cover,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text('Item ${index + 1}'),
                          ),
                          if (quantity > 0)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Text('Quantity: $quantity'),
                            ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton(
                                onPressed: () {
                                  ref.read(cartProvider.notifier).addToCart(index);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: buttonColor,
                                  foregroundColor: Colors.black,
                                ),
                                child: const Text('Add'),
                              ),
                              if (quantity > 0)
                                ElevatedButton(
                                  onPressed: () {
                                    ref.read(cartProvider.notifier).removeItem(index);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: buttonColor,
                                    foregroundColor: Colors.black,
                                  ),
                                  child: const Text('Remove'),
                                ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
