import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class PromoBanner extends StatelessWidget {
  const PromoBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        image: const DecorationImage(
          image: NetworkImage('https://images.unsplash.com/photo-1542838132-92c53300491e?q=80&w=2574&auto=format&fit=crop'), // Placeholder vegetable image
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(Colors.black38, BlendMode.darken),
        ),
        boxShadow: [
          BoxShadow(
             color: AppColors.primaryGreen.withOpacity(0.3),
             blurRadius: 15,
             offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                RichText(
                  text: const TextSpan(
                    children: [
                      TextSpan(
                        text: "Healthy & Fresh\n",
                         style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontFamily: 'Poppins', 
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      TextSpan(
                        text: "VEGETABLE",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                 Text(
                  "Get 20% off",
                  style: TextStyle(
                    color: AppColors.primaryGreen.withOpacity(0.9),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ]
      ),
    );
  }
}
