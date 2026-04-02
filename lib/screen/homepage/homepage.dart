import 'package:cached_network_image/cached_network_image.dart';
// import 'package:carousel_slider/carousel_controller.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:get/get.dart';
import 'package:parkingmudde/screen/Referal/referalpage.dart';
import 'package:parkingmudde/screen/couponstore/couponsstorepage.dart';
import 'package:parkingmudde/screen/helpingvehicle.dart/vehiclescan.dart';
import 'package:parkingmudde/screen/homepage/addvehiclepopup.dart';
import 'package:parkingmudde/screen/notification/notificationpage.dart';
import 'package:parkingmudde/screen/parkingAlert/parkingalertpage.dart'
    show AlertsScreen;
import 'package:parkingmudde/screen/parkingnearby/parkingnearbypage.dart';
import 'package:parkingmudde/screen/reportwrongparking/scanenter.dart';
import 'package:parkingmudde/screen/vehicle/addvehicle.dart';
import 'package:parkingmudde/screen/vehicle/myvehicle.dart';
import 'package:parkingmudde/screen/visitormangement/vistormangepage.dart';
import 'package:parkingmudde/screen/wallet/walletpage.dart';
import 'package:url_launcher/url_launcher.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  CarouselSliderController carouselController = CarouselSliderController();

  void getBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: false,
      backgroundColor:
          Colors.transparent, // Modern transparent trigger for bottomsheet card
      builder: (_) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: const AddVehicleBottomSheet(),
        );
      },
    );
  }

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      getBottomSheet(context);
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(
        0xFFF6F8FA,
      ), // A professional ultra-light silver/blue tint
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 1, // Cleaner material 3 scroll mapping
          titleSpacing: 16,
          title: Row(
            children: [
              const CircleAvatar(
                radius: 22,
                backgroundImage: NetworkImage("https://i.pravatar.cc/190"),
              ),
              const SizedBox(width: 12),
              InkWell(
                onTap: () {
                  // Open location dropdown / bottom sheet
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Current Location",
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: Color(0xFFE53935),
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          "Noida, UP",
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Icon(
                          Icons.keyboard_arrow_down,
                          color: Colors.black87,
                          size: 20,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade200, width: 1.5),
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.notifications_outlined,
                    color: Colors.black87,
                    size: 24,
                  ),
                  onPressed: () {
                    Get.to(const Notificationpage());
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Sleek Top Base connecting Search smoothly
            Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(32),
                ),
              ),
              padding: const EdgeInsets.only(
                left: 20,
                right: 20,
                bottom: 20,
                top: 10,
              ),
              child: modernSearchBar(),
            ),

            const SizedBox(height: 20),

            /// Modern Carousel Section
            buildCarousel(),

            const SizedBox(height: 10),

            /// Subtitles
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                "Core Services",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.3,
                  color: Colors.blueGrey.shade900,
                ),
              ),
            ),

            const SizedBox(height: 12),

            /// Services wrapped into a Single Clean Unified Paper Surface!
            buildModernUnifiedGrid(),

            const SizedBox(height: 16),

            /// ✨ FIXED LOGO BANNER : Perfectly structured row banner instead of vertical layout clipping logo
            informationalBanner(
              heading: "Parking Prachaar",
              description:
                  "View latest parking updates, municipal rules & public announcements.",
              imagePath: "assets/logo.png",
              onTap: () {
                // Navigate to Parking Prachaar Screen
              },
            ),

            const SizedBox(height: 12),

            /// The elegant Slogan ticker
            sloganSlider(context),

            const SizedBox(height: 8),

            /// Connect Section
            contactAndSupportUnifiedBox(),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  /// Extremely Premium Unified Application Services Grid
  Widget buildModernUnifiedGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 10),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: homeGridItems(context).length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3, // Maintained 3 as before
            mainAxisSpacing: 24,
            crossAxisSpacing: 8,
            childAspectRatio: 0.85,
          ),
          itemBuilder: (context, index) {
            final item = homeGridItems(context)[index];
            final uniqueBgColors = [
              Colors.red.shade50,
              Colors.blue.shade50,
              Colors.green.shade50,
              Colors.orange.shade50,
              Colors.purple.shade50,
              Colors.indigo.shade50,
              Colors.pink.shade50,
              Colors.teal.shade50,
              Colors.blueGrey.shade50,
              Colors.amber.shade50,
            ];
            final uniqueIconColors = [
              Colors.red,
              Colors.blue,
              Colors.green,
              Colors.orange,
              Colors.purple,
              Colors.indigo,
              Colors.pink,
              Colors.teal,
              Colors.blueGrey,
              Colors.amber.shade700,
            ];

            return GestureDetector(
              onTap: item.onTap,
              behavior: HitTestBehavior.opaque,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Container(
                    height: 56,
                    width: 56,
                    decoration: BoxDecoration(
                      color: uniqueBgColors[index % uniqueBgColors.length],
                      shape:
                          BoxShape.circle, // perfectly crisp soft touch targets
                    ),
                    child: Center(
                      child: Icon(
                        item.icon,
                        size: 28,
                        color:
                            uniqueIconColors[index % uniqueIconColors.length],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        item.title,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// Cleaned search bar with smooth shadow padding. Keeps functionality alive.
  Widget modernSearchBar() {
    return GestureDetector(
      onTap: () {},
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: const Color(0xFFF7F9FC),
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(color: Colors.grey.shade200, width: 1.5),
        ),
        child: const Row(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Icon(Icons.search, size: 24, color: Colors.blueGrey),
            ),
            Expanded(
              child: Text(
                "Search parking, rules & more...",
                style: TextStyle(
                  color: Colors.black38,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Fixed Promotional Container that uses explicitly bounded widths.
  /// NO clipping - Logo sits nicely beside context area.
  Widget informationalBanner({
    required String heading,
    required String description,
    required String imagePath,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFE3F2FD), Color(0xFFBBDEFB)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.blue.withOpacity(0.1)),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              /// 🔥 Ensures Full Uncropped Image Fitting
              Container(
                width: 75,
                height: 75,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(12),
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.contain, // Guarantee image never overflows
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.announcement,
                    color: Colors.blue,
                    size: 30,
                  ),
                ),
              ),
              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      heading,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Colors.blue.shade900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Colors.blueGrey.shade800,
                        height: 1.3,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: Colors.blue.shade900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Fully premium Carousel View
  Widget buildCarousel() {
    return CarouselSlider.builder(
      carouselController: carouselController,
      itemCount: 3,
      itemBuilder: (context, index, realIndex) {
        return Container(
          width: MediaQuery.of(context).size.width,
          margin: const EdgeInsets.symmetric(horizontal: 6.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20.0),
            child: Stack(
              fit: StackFit.expand,
              children: [
                CachedNetworkImage(
                  imageUrl:
                      "https://media.istockphoto.com/id/480652712/photo/dealer-new-cars-stock.jpg?s=612x612&w=0&k=20&c=Mzfb5oEeovQblEo160df-xFxfd6dGoLBkqjjDWQbd5E=",
                  fit: BoxFit.cover,
                  placeholder: (context, url) =>
                      Container(color: Colors.grey.shade100),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[200],
                    child: const Icon(
                      Icons.image_not_supported,
                      color: Colors.grey,
                    ),
                  ),
                ),
                // Gradient layer guarantees bottom section of pictures holds contrast well if titles are added
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withOpacity(0),
                        Colors.black.withOpacity(0.5),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      options: CarouselOptions(
        height: 175,
        autoPlayInterval: const Duration(seconds: 8),
        autoPlayAnimationDuration: const Duration(milliseconds: 1200),
        autoPlay: true,
        enlargeCenterPage: true, // Elevates the view
        viewportFraction: 0.88,
        onPageChanged: (index, reason) async {
          setState(() {});
        },
      ),
    );
  }

  /// Refined Premium Ticker Style Slogans Area
  Widget sloganSlider(BuildContext context) {
    final slogans = [
      "Park Right. Live Better.",
      "Responsible Parking, Safer Cities.",
      "Your Parking, Your Responsibility.",
      "One App. Better Parking Culture.",
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
      child: SizedBox(
        height: 40, // Elegant low profile size
        child: PageView.builder(
          itemCount: slogans.length,
          controller: PageController(viewportFraction: 1),
          itemBuilder: (context, index) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.auto_awesome, color: Colors.orange, size: 16),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    slogans[index],
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      fontStyle: FontStyle.italic,
                      letterSpacing: 0.5,
                      color: Colors.blueGrey.shade500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.auto_awesome, color: Colors.orange, size: 16),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Superapp styled block connecting Socials & Helplines together elegantly!
  Widget contactAndSupportUnifiedBox() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              "Support & Community",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.3,
                color: Colors.blueGrey.shade900,
              ),
            ),
          ),

          /// Unified support block area
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.grey.shade100, width: 2),
            ),
            child: Column(
              children: [
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          contactIconButton(
                            icon: Icons.phone_in_talk,
                            color: Colors.blue.shade700,
                            title: "Helpline",
                            onTap: () {},
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          contactIconButton(
                            icon: Icons.chat,
                            color: Colors.green.shade600,
                            title: "WhatsApp Chat",
                            isImageProvider: true,
                            onTap: () {
                              launchUrl(
                                Uri.parse("https://whatsapp.com/channel/xxxx"),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Divider(
                    color: Colors.grey.shade100,
                    height: 30,
                    thickness: 1.5,
                  ),
                ),

                /// Social icons in tight highly responsive layout row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    socialBubbleButton(
                      icon: Icons.play_arrow_rounded,
                      bgTappedColor: Colors.red.shade50,
                      iconColor: Colors.red.shade600,
                      label: "YouTube",
                      onTap: () => launchUrl(
                        Uri.parse("https://youtube.com/@parkingmudde"),
                      ),
                    ),
                    socialBubbleButton(
                      icon: Icons.camera_alt,
                      bgTappedColor: Colors.purple.shade50,
                      iconColor: Colors.purple.shade500,
                      label: "Instagram",
                      onTap: () => launchUrl(
                        Uri.parse("https://instagram.com/parkingmudde"),
                      ),
                    ),
                    socialBubbleButton(
                      icon: Icons.people_alt,
                      bgTappedColor: Colors.green.shade50,
                      iconColor: Colors.green.shade700,
                      label: "Join Channel",
                      onTap: () => launchUrl(
                        Uri.parse("https://whatsapp.com/channel/xxxx"),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget contactIconButton({
    required IconData icon,
    required Color color,
    required String title,
    required VoidCallback onTap,
    bool isImageProvider = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: isImageProvider
                  ? Image.asset(
                      "assets/WhatsApp.webp",
                      height: 20,
                      errorBuilder: (ctx, _, __) =>
                          Icon(icon, color: color, size: 20),
                    )
                  : Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget socialBubbleButton({
    required IconData icon,
    required Color iconColor,
    required Color bgTappedColor,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade200, width: 1.5),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 24, color: iconColor),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  // --- Strict compliance to functionality preservation below --- //

  List<HomeGridItem> homeGridItems(BuildContext context) => [
    HomeGridItem(
      title: "Report Wrong Parking",
      icon: Icons.report_problem,
      onTap: () {
        Get.to(const VehicleNumberInputScreen());
      },
    ),
    HomeGridItem(
      title: "Help a Vehicle",
      icon: Icons.car_repair,
      onTap: () {
        Get.to(const VehicleNumberHelpScreen());
      },
    ),
    HomeGridItem(
      title: "Add Vehicle",
      icon: Icons.add_circle,
      onTap: () {
        Get.to(const AddVehicleScreen());
      },
    ),
    HomeGridItem(
      title: "My Vehicles",
      icon: Icons.directions_car,
      onTap: () {
        Get.to(const MyVehiclesScreen());
      },
    ),
    HomeGridItem(
      title: "Wallet",
      icon: Icons.account_balance_wallet,
      onTap: () {
        Get.to(const WalletScreen(totalCoins: 2334));
      },
    ),
    HomeGridItem(
      title: "Referral",
      icon: Icons.share,
      onTap: () {
        Get.to(const ReferralScreen());
      },
    ),
    HomeGridItem(
      title: "Coupon Store",
      icon: Icons.store,
      onTap: () {
        final int userCoins = 40;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CouponStoreScreen(userCoins: userCoins),
          ),
        );
      },
    ),
    HomeGridItem(
      title: "Parking Alerts",
      icon: Icons.notifications_active,
      onTap: () {
        Get.to(const AlertsScreen());
      },
    ),
    HomeGridItem(
      title: "Parking Nearby",
      icon: Icons.location_on,
      onTap: () {
        Get.to(const NearbyParkingMapScreen());
      },
    ),
    HomeGridItem(
      title: "Visitor Mgmt",
      icon: Icons.badge,
      onTap: () {
        Get.to(const VisitorManagementScreen());
      },
    ),
  ];
}

class HomeGridItem {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  HomeGridItem({required this.title, required this.icon, required this.onTap});
}
