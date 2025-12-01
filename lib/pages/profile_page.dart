import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class ProfilePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final count = auth.user!.totalNews.toString();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
          CircleAvatar(radius: 40, backgroundColor: Colors.orangeAccent, child: Text(auth.user?.name.substring(0,1).toUpperCase() ?? '?')),
          const SizedBox(height: 12),
          Text(auth.user?.name ?? 'Guest', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(auth.user?.email ?? '', style: TextStyle(color: Colors.grey[300])),
          const SizedBox(height: 12),
          Card(
            color: const Color(0xFF3A332F),
            child: ListTile(
              title: Text('News Created', style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold)),
              trailing: Text(count, style: const TextStyle(fontSize: 18, color: Colors.white)),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange),
            onPressed: auth.isLoggedIn ? () async {
              await context.read<AuthProvider>().logout();
            } : null,
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          )
        ]),
      ),
    );
  }
}
