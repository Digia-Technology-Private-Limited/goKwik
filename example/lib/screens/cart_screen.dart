import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:gokwik/go_kwik.dart';
import '../models/product.dart';
import 'checkout_screen.dart';
import 'gokwik_kwikforms_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({Key? key}) : super(key: key);

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool _gokwikConsent = true;
  final List<KwikAddress> _savedAddresses = [
    const KwikAddress(
      id: '1',
      label: 'Office',
      addressLine:
          'B-204, Emerald Heights, Sector 65, DLF Phase 5, Gurgaon, Haryana – 122001',
      name: 'Karan B',
      phone: '+91 87990 44317',
      email: 'karan.bh789@yopmail.com',
      houseNo: 'B-204',
      area: 'Emerald Heights, Sector 65, DLF Phase 5',
      city: 'Gurgaon',
      state: 'Haryana',
      pincode: '122001',
      country: 'India',
      source: '1mg',
    ),
  ];

  void _onAddressSelected(KwikAddress address) {
    // Add to the saved list only if it's a newly added address.
    if (!_savedAddresses.any((a) => a.id == address.id)) {
      setState(() => _savedAddresses.add(address));
    }
  }

  @override
  Widget build(BuildContext context) {
    // TODO: Implement cart state management
    final List<Product> cartItems = [
      Product(
        id: '2',
        title: 'Antidote "Joie" Tee in Taupe',
        description: 'Comfortable cotton tee with modern design',
        price: 78.00,
        imageUrl:
            'https://karanzi.websites.co.in/obaju-turquoise/img/product-placeholder.png',
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cart'),
      ),
      body: cartItems.isEmpty
          ? const Center(
              child: Text('Your cart is empty'),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: cartItems.length,
                    itemBuilder: (context, index) {
                      final product = cartItems[index];
                      return Card(
                        margin: const EdgeInsets.all(8),
                        child: ListTile(
                          leading: SizedBox(
                            width: 60,
                            height: 60,
                            child: Image.network(
                              product.imageUrl,
                              fit: BoxFit.cover,
                            ),
                          ),
                          title: Text(product.title),
                          subtitle:
                              Text('₹${product.price.toStringAsFixed(2)}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove),
                                onPressed: () {
                                  // TODO: Implement quantity decrease
                                },
                              ),
                              const Text('1'),
                              IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: () {
                                  // TODO: Implement quantity increase
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () {
                                  // TODO: Implement remove from cart
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total:',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '₹${cartItems.fold<double>(0, (sum, item) => sum + item.price).toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const CheckoutScreen(),
                              ),
                            );
                          },
                          child: const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text('Proceed to Checkout'),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _GoKwikSection(
                        consent: _gokwikConsent,
                        onConsentChanged: (val) =>
                            setState(() => _gokwikConsent = val),
                        addresses: _savedAddresses,
                        onAddressSelected: _onAddressSelected,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _GoKwikSection extends StatelessWidget {
  final bool consent;
  final ValueChanged<bool> onConsentChanged;
  final List<KwikAddress> addresses;
  final ValueChanged<KwikAddress> onAddressSelected;

  const _GoKwikSection({
    required this.consent,
    required this.onConsentChanged,
    required this.addresses,
    required this.onAddressSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                final address = await Navigator.push<KwikAddress>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GokwikKwikformsScreen(
                      title: 'Select Address',
                      consent: consent,
                      addresses: addresses,
                    ),
                  ),
                );
                if (address != null && context.mounted) {
                  onAddressSelected(address);
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Address Selected'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Name: ${address.name}'),
                          Text('Phone: ${address.phone}'),
                          if (address.email != null) Text('Email: ${address.email}'),
                          Text('Address: ${address.addressLine}'),
                          if (address.pincode != null) Text('Pincode: ${address.pincode}'),
                          if (address.city != null) Text('City: ${address.city}'),
                          if (address.state != null) Text('State: ${address.state}'),
                          if (address.country != null) Text('Country: ${address.country}'),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6B3FA0),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.flash_on, size: 18),
              label: const Text(
                'Select Address · Powered by GoKwik',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: Checkbox(
                  value: consent,
                  onChanged: (val) => onConsentChanged(val ?? true),
                  activeColor: const Color(0xFF6B3FA0),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                      height: 1.4,
                    ),
                    children: [
                      const TextSpan(
                        text:
                            'I allow GoKwik to fetch, save my PII data and use it for SSO, prefill, intelligence and marketing. ',
                      ),
                      TextSpan(
                        text: 'Privacy Policy',
                        style: const TextStyle(
                          color: Color(0xFF6B3FA0),
                          fontWeight: FontWeight.w600,
                        ),
                        recognizer: TapGestureRecognizer()..onTap = () {},
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
