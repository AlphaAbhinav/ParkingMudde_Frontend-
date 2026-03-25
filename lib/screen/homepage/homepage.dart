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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return const AddVehicleBottomSheet();
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundImage: NetworkImage("https://i.pravatar.cc/190"),
          ),
        ),
        title: InkWell(
          onTap: () {
            // Open location dropdown / bottom sheet
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.location_on, color: Colors.red, size: 20),
              const SizedBox(width: 4),
              Text(
                "Noida, UP",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.keyboard_arrow_down, color: Colors.black, size: 22),
            ],
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_none, color: Colors.black),
            onPressed: () {
              Get.to(Notificationpage());
              // Notification click
            },
          ),
          // IconButton(
          //   icon: Icon(Icons.shopping_cart_outlined, color: Colors.black),
          //   onPressed: () {
          //     // Cart click
          //   },
          // ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(left: 10, right: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 10),
              Center(
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 10),
                  height: 40,
                  child: GestureDetector(
                    onTap: () {},
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            blurRadius: 5.0,
                            spreadRadius: 2.0,
                            offset: const Offset(1, 9),
                          ),
                        ],
                        border: Border.all(color: Colors.grey),
                        borderRadius: const BorderRadius.all(
                          Radius.circular(12.0),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.only(
                              left: 10,
                              top: 5,
                              bottom: 5,
                              right: 5,
                            ),
                            child: Icon(
                              Icons.search,
                              size: 24,
                              color: Colors.grey,
                            ),
                          ),
                          Expanded(
                            child: Container(
                              margin: EdgeInsets.only(left: 10, bottom: 2),
                              child: Row(
                                children: [
                                  Text(
                                    "Search   ",
                                    style: TextStyle(color: Colors.grey,fontSize: 16),
                                  ),
                                  AnimatedOpacity(
                                    curve: Curves.easeInOutBack,
                                    opacity: 1, // Keeps text visible
                                    duration: Duration(milliseconds: 600),
                                    child: AnimatedScale(
                                      scale: 1.1, // Zoom-in effect
                                      duration: Duration(milliseconds: 600),
                                      curve: Curves.easeInOut,
                                      child: AnimatedSlide(
                                        curve: Curves.easeIn,
                                        duration: Duration(milliseconds: 600),
                                        offset: Offset(0.0, 0.0), // No shift
                                        child: Text(
                                          "",
                                          textAlign: TextAlign.start,
                                          style: TextStyle(color: Colors.grey,fontSize: 14,fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 10),
              Container(
                margin: EdgeInsets.only(left: 5, right: 5),
                // color: ColorUtils.backweather,
                // height: 300,
                child: CarouselSlider.builder(
                  carouselController: carouselController,
                  itemCount: 3,
                  itemBuilder: (context, index, realIndex) {
                    return SizedBox(
                      width: MediaQuery.of(context).size.width, // Full width
                      height: 220, // Adjusted height based on aspect ratio
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(
                          10.0,
                        ), // Rounded corners
                        child: CachedNetworkImage(
                          imageUrl:
                              "https://media.istockphoto.com/id/480652712/photo/dealer-new-cars-stock.jpg?s=612x612&w=0&k=20&c=Mzfb5oEeovQblEo160df-xFxfd6dGoLBkqjjDWQbd5E=",
                          fit: BoxFit.cover, // Image fill style
                          // Placeholder while loading
                          placeholder: (context, url) => Container(),

                          // Error widget if image fails to load
                          errorWidget: (context, url, error) => Container(
                            color: Colors
                                .grey[400], // Slightly darker grey for error
                            child: Icon(
                              Icons.image_not_supported,
                              color: Colors.red,
                            ),
                          ),

                          fadeInDuration: Duration(
                            milliseconds: 500,
                          ), // Smooth fade-in effect
                        ),
                      ),
                    );
                  },
                  options: CarouselOptions(
                    aspectRatio: 1.6001370801919122,

                    autoPlayInterval: const Duration(seconds: 10),
                    autoPlay: true,
                    enlargeCenterPage: false,
                    scrollDirection: Axis.horizontal,
                    viewportFraction: 1, // Full width for each item
                    onPageChanged: (index, reason) async {
                      // _current = index;
                      setState(() {});
                    },
                  ),
                ),
              ),
              SizedBox(height: 15),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("All Services", style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold)),
                ],
              ),
              SizedBox(height: 10),
              buildMainMenulastes(),
              homeSection(
                heading: "Parking Prachaar",
                description:
                    "Latest parking updates, rules and public announcements.",
                imagePath: "assets/logo.png",
                onTap: () {
                  // Navigate to Parking Prachaar Screen
                },
              ),

              contactSection(
                context: context,
                heading: "Contact & Support",
                phoneNumber: "+91 98765 43210",
                onCallTap: () {
                  // makeCall("+919876543210");
                },
                onWhatsAppTap: () {
                  // openWhatsApp("919876543210");
                },
              ),
              socialChannelSection(
                context: context,
                onYoutubeTap: () {
                  launchUrl(Uri.parse("https://youtube.com/@parkingmudde"));
                },
                onInstagramTap: () {
                  launchUrl(Uri.parse("https://instagram.com/parkingmudde"));
                },
                onWhatsAppTap: () {
                  launchUrl(Uri.parse("https://whatsapp.com/channel/xxxx"));
                },
              ),
              sloganSlider(context) 
            ],
          ),
        ),
      ),
    );
  }
Widget sloganSlider(BuildContext context) {
    final slogans = [
      "Park Right. Live Better.",
      "Responsible Parking, Safer Cities.",
      "Your Parking, Your Responsibility.",
      "One App. Better Parking Culture.",
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          // color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
        ),
        child: SizedBox(
          height: 120,
          child: PageView.builder(
            itemCount: slogans.length,
            controller: PageController(viewportFraction: 1),
            itemBuilder: (context, index) {
              return Center(
                child: Text(
                  slogans[index],
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 30),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget socialChannelSection({
    required BuildContext context,
    required VoidCallback onYoutubeTap,
    required VoidCallback onInstagramTap,
    required VoidCallback onWhatsAppTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// 🔹 HEADING (SAME STYLE)
          Text("Follow Our Channels", style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold)),

          const SizedBox(height: 14),

          Row(
            children: [
              /// ▶️ YOUTUBE
              Expanded(
                child: socialCard(
                  context: context,
                  title: "YouTube",
                  subtitle: "Videos & Updates",
                  color: Colors.red,
                  icon: Icons.play_circle_fill,
                  onTap: onYoutubeTap,
                ),
              ),

              const SizedBox(width: 12),

              /// 📸 INSTAGRAM
              Expanded(
                child: socialCard(
                  context: context,
                  title: "Instagram",
                  subtitle: "Photos & Reels",
                  color: Colors.purple,
                  icon: Icons.camera_alt,
                  onTap: onInstagramTap,
                ),
              ),

              const SizedBox(width: 12),

              /// 💬 WHATSAPP
              Expanded(
                child: socialCard(
                  context: context,
                  title: "WhatsApp",
                  subtitle: "Join Channel",
                  color: Colors.green,
                  icon: Icons.chat,
                  onTap: onWhatsAppTap,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget homeSection({
    required String heading,
    required String description,
    required String imagePath,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                imagePath,
                height: 160,
                width: double.infinity,
                fit: BoxFit.contain,
              ),
            ),

            SizedBox(height: 10),

            // 🔹 HEADING
            Text(heading, style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold)),

            SizedBox(height: 6),

            // 🔹 DESCRIPTION
            Text(description, style: TextStyle(fontSize: 14,)),
          ],
        ),
      ),
    );
  }

  Widget buildMainMenulastes() {
    return GridView.builder(
      padding: EdgeInsets.all(16),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: homeGridItems(context).length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, // 🔹 3 columns
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.9,
      ),
      itemBuilder: (context, index) {
        final item = homeGridItems(context)[index];

        return InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: item.onTap,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 6,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(item.icon, size: 30, color: Colors.black),
                SizedBox(height: 10),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    item.title,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<HomeGridItem> homeGridItems(BuildContext context) => [
    HomeGridItem(
      title: "Report Wrong Parking",
      icon: Icons.report_problem,
      onTap: () {
        Get.to(VehicleNumberInputScreen());
      },
    ),
    HomeGridItem(
      title: "Help a Vehicle",
      icon: Icons.car_repair,
      onTap: () {
        Get.to(VehicleNumberHelpScreen());
      },
    ),
    // HomeGridItem(title: "User Profile", icon: Icons.person, onTap: () {}),
    HomeGridItem(
      title: "Add Vehicle",
      icon: Icons.add_circle,
      onTap: () {
        Get.to(AddVehicleScreen());
      },
    ),
    HomeGridItem(
      title: "My Vehicles",
      icon: Icons.directions_car,
      onTap: () {
        Get.to(MyVehiclesScreen());
      },
    ),
    HomeGridItem(
      title: "Wallet",
      icon: Icons.account_balance_wallet,
      onTap: () {
        Get.to(WalletScreen(totalCoins: 2334));
      },
    ),

    // HomeGridItem(
    //   title: "My Coupons",
    //   icon: Icons.local_offer,
    //   onTap: () {
    //     final List<Map<String, dynamic>> coupons = [
    //       {
    //         "id": "CPN001",
    //         "title": "₹50 Parking Discount",
    //         "description": "Get flat ₹50 off on parking charges",
    //         "coins": 20,
    //         "expiry": "2026-03-31",
    //         "is_used": false,
    //       },
    //       {
    //         "id": "CPN002",
    //         "title": "₹100 Fuel Coupon",
    //         "description": "Use on selected fuel stations",
    //         "coins": 40,
    //         "expiry": "2026-04-15",
    //         "is_used": false,
    //       },
    //       {
    //         "id": "CPN003",
    //         "title": "Free Car Wash",
    //         "description": "One time free car wash service",
    //         "coins": 60,
    //         "expiry": "2026-02-28",
    //         "is_used": false,
    //       },
    //       {
    //         "id": "CPN004",
    //         "title": "Bike Service Discount",
    //         "description": "₹150 off on bike servicing",
    //         "coins": 30,
    //         "expiry": "2026-05-10",
    //         "is_used": true, // already redeemed
    //       },
    //     ];

    //     final int userCoins = 40;

    //     Navigator.push(
    //       context,
    //       MaterialPageRoute(
    //         builder: (_) => CouponStoreScreen(userCoins: userCoins),
    //       ),
    //     );
    //   },
    // ),
    HomeGridItem(
      title: "Referral",
      icon: Icons.share,
      onTap: () {
        Get.to(ReferralScreen());
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
        Get.to(AlertsScreen());
      },
    ),
    HomeGridItem(
      title: "Parking Nearby",
      icon: Icons.location_on,
      onTap: () {
        Get.to(NearbyParkingMapScreen());
      },
    ),
    HomeGridItem(
      title: "Visitor Management",
      icon: Icons.badge,
      onTap: () {
        Get.to(VisitorManagementScreen());
      },
    ),
  ];

  Widget contactSection({
    required BuildContext context,
    required String heading,
    required String phoneNumber,
    required VoidCallback onCallTap,
    required VoidCallback onWhatsAppTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// 🔹 HEADING (SAME STYLE)
          Text(heading, style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold)),

          const SizedBox(height: 12),

          /// 🔹 BUTTONS
          Row(
            children: [
              /// 📞 CALL
              Expanded(
                child: InkWell(
                  onTap: onCallTap,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.call, color: Colors.blue, size: 28),
                        const SizedBox(height: 6),
                        Text("Call Us", style: TextStyle(fontSize: 14,fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              /// 💬 WHATSAPP
              Expanded(
                child: InkWell(
                  onTap: onWhatsAppTap,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        Image.asset("assets/WhatsApp.webp", height: 28),
                        const SizedBox(height: 6),
                        Text(
                          "WhatsApp",
                          style: TextStyle(fontSize: 14,fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          /// 🔹 SUPPORT TEXT
          Text(
            "Support: $phoneNumber",
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget socialCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 8),
            Text(title, style: TextStyle(fontSize: 14,fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(subtitle, style: TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class HomeGridItem {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  HomeGridItem({required this.title, required this.icon, required this.onTap});
}
