import 'package:flutter/material.dart';

class ParkingPracharScreen extends StatelessWidget {
  const ParkingPracharScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          "Parking Prachar",
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        physics: const BouncingScrollPhysics(),
        children: [
          _buildBlogCard(
            title: "5 Tips for Easy City Parking",
            category: "Blog",
            imageColor: Colors.blue.shade200,
            icon: Icons.article_rounded,
            description: "Discover the best times and places to find parking in the busy city center without getting a ticket.",
          ),
          const SizedBox(height: 16),
          _buildBlogCard(
            title: "Summer Blockbuster Movie Out Now!",
            category: "Advertisement",
            imageColor: Colors.purple.shade200,
            icon: Icons.movie_creation_rounded,
            description: "Don't miss the biggest action movie of the year! Book your tickets and your parking spot in advance.",
          ),
          const SizedBox(height: 16),
          _buildBlogCard(
            title: "How ParkingMudde is Saving Lives",
            category: "Community",
            imageColor: Colors.green.shade200,
            icon: Icons.volunteer_activism_rounded,
            description: "Read about how our emergency alert system helped an ambulance get through traffic last week.",
          ),
          const SizedBox(height: 16),
          _buildBlogCard(
            title: "50% Off Car Wash Service",
            category: "Exclusive Offer",
            imageColor: Colors.orange.shade200,
            icon: Icons.local_car_wash_rounded,
            description: "Use your PM Coins to claim a 50% discount at selected car wash partners this weekend.",
          ),
        ],
      ),
    );
  }

  Widget _buildBlogCard({
    required String title,
    required String category,
    required Color imageColor,
    required IconData icon,
    required String description,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 140,
            color: imageColor,
            child: Icon(
              icon,
              size: 64,
              color: Colors.white,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    category.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text(
                      "Read More",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward_rounded, size: 16, color: Colors.blue),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
