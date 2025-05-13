import 'package:flutter/material.dart';
import 'package:gokwik/api/snowplow_events.dart';
import 'package:gokwik/config/types.dart';
import 'network_logger_screen.dart';
import 'login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  Future<void> handleProductEvents() async {
    // TODO: Implement product event tracking
    final productEvent = TrackProductEventArgs(
      pageUrl: 'https://gokwikproduction.myshopify.com/',
      cartId:
          'gid://shopify/Cart/Z2NwLWFzaWEtc291dGhlYXN0MTowMUpSQU1RNEhCN1I4S0tNOTJRR0tDRDRYRg?key=d9e7d5fb318b9c9d3fa45ca704a19d6e',
      productId: "123",
      variantId: "456",
      handle: "all-products",
      imgUrl:
          "https://cdn.shopify.com/s/files/1/0727/0216/5282/products/2015-03-20_Ashley_Look_20_23515_15565.jpg?v=1677584331",
      name: "All Products",
      price: "100.0",
    );

    // TODO: Call your event tracking service here
    await SnowplowTrackerService.trackProductEvent(productEvent);
    print('Product Event Data: $productEvent');
  }

  Future<void> handleCollectionEvents() async {
    // TODO: Implement collection event tracking
    final collectionEvent = TrackCollectionsEventArgs(
      cartId:
          'gid://shopify/Cart/Z2NwLWFzaWEtc291dGhlYXN0MTowMUpSQU1RNEhCN1I4S0tNOTJRR0tDRDRYRg?key=d9e7d5fb318b9c9d3fa45ca704a19d6e',
      collectionId: '478302175522',
      name: 'All Products',
      handle: 'all-products',
      pageUrl: 'https://gokwikproduction.myshopify.com/',
    );
    // TODO: Call your event tracking service here
    await SnowplowTrackerService.trackCollectionsEvent(collectionEvent);
    print('Collection Event Data: $collectionEvent');
  }

  Future<void> handleOtherEvents() async {
    // TODO: Implement other event tracking
    final otherEvent = TrackOtherEventArgs(
      cartId:
          'gid://shopify/Cart/Z2NwLWFzaWEtc291dGhlYXN0MTowMUpSQU1RNEhCN1I4S0tNOTJRR0tDRDRYRg?key=d9e7d5fb318b9c9d3fa45ca704a19d6e',
      pageUrl: 'https://gokwikproduction.myshopify.com/',
    );

    await SnowplowTrackerService.trackOtherEvent(otherEvent);

    // TODO: Call your event tracking service here
    print('Other Event Data: $otherEvent');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        children: [
          const SizedBox(height: 20),
          CircleAvatar(
            radius: 50,
            child: Image.network(
              'https://microbiology.ucr.edu/sites/default/files/styles/form_preview/public/blank-profile-pic.png?itok=4teBBoet',
            ),
          ),
          const SizedBox(height: 20),
          const Center(
            child: Text(
              'John Doe',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 30),
          ListTile(
            title: const Text('Product Events'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Handle download logs
              handleProductEvents();
            },
          ),
          ListTile(
            title: const Text('Collection Events'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Handle download logs
              handleCollectionEvents();
            },
          ),
          ListTile(
            title: const Text('Other Events'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Handle download logs
              handleOtherEvents();
            },
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Account Settings'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Navigate to account settings
            },
          ),
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('Notification Settings'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Navigate to notification settings
            },
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip),
            title: const Text('Privacy Policy'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Navigate to privacy policy
            },
          ),
          ListTile(
            leading: const Icon(Icons.help),
            title: const Text('Help & Support'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Navigate to help & support
            },
          ),
          ListTile(
            leading: const Icon(Icons.file_download),
            title: const Text('Download Logs'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Handle download logs
            },
          ),
          ListTile(
            leading: const Icon(Icons.network_check),
            title: const Text('Network Logs'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NetworkLoggerScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Login', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}
