import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../providers/loan_provider.dart';
import '../../widgets/loan_card.dart';
import 'loan_details_screen.dart';

class LoanHistoryScreen extends StatelessWidget {
  const LoanHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loanProvider = context.watch<LoanProvider>();
    final loans = loanProvider.loans;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Loan History'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: loans.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 80,
                    color: AppColors.textLight.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No loans yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: AppColors.textLight,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Apply for your first loan to get started',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textLight,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: loans.length,
              itemBuilder: (context, index) {
                final loan = loans[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LoanDetailsScreen(loan: loan),
                        ),
                      );
                    },
                    child: LoanCard(loan: loan),
                  ),
                );
              },
            ),
    );
  }
}