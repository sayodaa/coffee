import 'package:coffee_app/auth/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ReportScreen extends StatelessWidget {
  const ReportScreen({super.key});

  Future<void> _cancelReport(BuildContext context, String reportId) async {
    final authProvider = context.read<AuthProvider>();

    if (!authProvider.isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Only admins can cancel or delete reports.')),
      );
      return;
    }

    try {
      // Replace this with your real API call.
      await Future<void>.delayed(const Duration(milliseconds: 500));
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Report $reportId cancelled successfully.')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to cancel report: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: Center(
        child: Consumer<AuthProvider>(
          builder: (context, authProvider, _) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Role: ${authProvider.role ?? 'none'}'),
                const SizedBox(height: 16),
                if (authProvider.isAdmin)
                  ElevatedButton.icon(
                    onPressed: () => _cancelReport(context, 'report-123'),
                    icon: const Icon(Icons.cancel),
                    label: const Text('Cancel/Delete Report'),
                  )
                else
                  const Text('Barista users cannot delete reports.'),
              ],
            );
          },
        ),
      ),
    );
  }
}
