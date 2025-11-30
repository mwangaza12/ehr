import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ehr/providers/sync_provider.dart';
import 'package:ehr/screens/sync/sync_screen.dart';

class SyncButton extends StatelessWidget {
  const SyncButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SyncProvider>(
      builder: (context, syncProvider, _) {
        return Stack(
          children: [
            IconButton(
              icon: Icon(
                syncProvider.isOnline ? Icons.cloud_done : Icons.cloud_off,
                color: syncProvider.isOnline ? Colors.green : Colors.orange,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SyncScreen()),
                );
              },
            ),
            if (syncProvider.pendingSyncCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    '${syncProvider.pendingSyncCount}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}