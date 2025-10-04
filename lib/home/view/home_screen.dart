import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'dart:async';
import 'dart:math' as math;
import 'package:the_chess/game_board.dart' as single;
import 'package:the_chess/home/controller/matchmaking_controller.dart';
import 'package:the_chess/home/view/match_macking/match_macking_animations.dart';
import 'package:the_chess/home/view/match_macking/matchmaking_screen.dart';
import 'package:the_chess/screens/game_history.dart';
import 'package:the_chess/values/colors.dart';

class ChessAppUI extends StatefulWidget {
  const ChessAppUI({super.key});

  @override
  State<ChessAppUI> createState() => _ChessAppUIState();
}

class _ChessAppUIState extends State<ChessAppUI>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error logging out: ${e.toString()}'),
          backgroundColor: MyColors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyColors.darkBackground,
      appBar: AppBar(
        backgroundColor: MyColors.darkBackground,
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: MyColors.lightGray,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.person,
                color: Colors.white,
                size: 24,
              ),
            ),
            Image.asset(
              "assets/images/Pixel-Pawn-Logo.png",
              height: 50,
            )
          ],
        ),
        actions: [
          InkWell(
            onTap: () {
              Get.to(() => GameHistoryScreen());
            },
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: MyColors.tealGray,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.history,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          InkWell(
            onTap: _logout,
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: MyColors.red,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.logout,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // AnalyticsNavigation.buildAnalyticsCard(title: '', subtitle: ''),
          // Tab Bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: MyColors.cardBackground,
              borderRadius: BorderRadius.circular(8),
            ),
            child: TabBar(
              controller: _tabController,
              padding: EdgeInsets.symmetric(vertical: 16),
              indicator: BoxDecoration(
                color: MyColors.lightGray,
                borderRadius: BorderRadius.circular(5),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: MyColors.mediumGray,
              dividerColor: Colors.transparent,
              tabs: [
                Tab(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.sports_esports, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'BATTLE',
                          style: GoogleFonts.orbitron(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Tab(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.emoji_events, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'TOURNAMENT',
                          style: GoogleFonts.orbitron(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: TabBarView(
                controller: _tabController,
                children: [
                  SingleChildScrollView(
                    child: _buildBattleModeContent(),
                  ),
                  _buildTournamentContent(),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: MyColors.darkBackground,
        selectedItemColor: MyColors.lightGray,
        unselectedItemColor: MyColors.mediumGray,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.play_arrow),
            label: 'PLAY',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'FRIENDS',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu),
            label: 'More',
          ),
        ],
      ),
    );
  }

  Widget _buildBattleModeContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        ChessGameCard(),
        const SizedBox(height: 16),
        ChessGameCard(),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildTournamentContent() {
    return Center(
      child: Text(
        'Tournament content coming soon',
        style: GoogleFonts.orbitron(
          color: Colors.white,
          fontSize: 18,
        ),
      ),
    );
  }
}

class ChessGameCard extends StatelessWidget {
  const ChessGameCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          margin: const EdgeInsets.only(left: 16, right: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF2D2D2D),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: MyColors.cardBackground,
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top section with badge and entry fee

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SizedBox(),
                        Text(
                          'Entry fee: 120',
                          style: GoogleFonts.orbitron(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          // style: GoogleFonts.orbitron(
                          //   color: MyColors.white,
                          //   fontSize: 12,
                          // ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Main content section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Play for free',
                          style: GoogleFonts.orbitron(
                            color: Color(0xFFCCCCCC),
                            fontSize: 18,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            final controller = Get.put(MatchmakingController());
                            controller.startSearching();
                            Get.to(() => MatchmakingScreen());
                            Future.delayed(Duration(seconds: 1), () {
                              var vsController = Get.put(VSBattleController());
                              vsController.initializeControllers();
                              vsController.startVSAnimation();
                              vsController.setupAnimations();
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 8),
                            decoration: BoxDecoration(
                              color: MyColors.mediumGray.withValues(alpha: .5),
                              border: Border.all(
                                color: MyColors.lightGray,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'FREE',
                              style: GoogleFonts.orbitron(
                                color: MyColors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Middle border line
              Container(
                height: 1,
                color: const Color(0xFF404040),
              ),

              // Bottom section with different background
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Color(0xFF252525),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: const Color(0xFF4A4A4A),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Icon(
                            Icons.extension,
                            color: Color(0xFF6B9B6B),
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Solve mate-in-x',
                          style: GoogleFonts.orbitron(
                            color: Color(0xFF888888),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.emoji_events_outlined,
                          color: Color(0xFF888888),
                          size: 20,
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.keyboard_arrow_down,
                          color: Color(0xFFD4AF37),
                          size: 20,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 12, left: 5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomPaint(
                size: const Size(10, 5), // triangle size
                painter: TrianglePainter(color: MyColors.mediumGray),
              ),
              SizedBox(height: .5),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: MyColors.lightGray,
                  borderRadius: BorderRadius.only(
                      topRight: Radius.circular(4),
                      bottomRight: Radius.circular(12)),
                ),
                child: Text(
                  'Winning Amount: 200',
                  style: GoogleFonts.orbitron(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class TrianglePainter extends CustomPainter {
  final Color color;

  TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(size.width / 1, 0);
    path.lineTo(0, size.height);
    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ChessHomeScreen extends StatefulWidget {
  const ChessHomeScreen({super.key});

  @override
  State<ChessHomeScreen> createState() => _ChessHomeScreenState();
}

class _ChessHomeScreenState extends State<ChessHomeScreen>
    with SingleTickerProviderStateMixin {
  final List<ChessMatch> matches = [
    ChessMatch(
      name: "Grand Master Championship",
      entryFee: 100,
      winningAmount: 180,
      participants: 128,
      timeLeft: "2h 30m",
      difficulty: "Expert",
      isHot: true,
      image: "assets/images/figures/black/king.png",
    ),
    ChessMatch(
      name: "Speed Blitz Tournament",
      entryFee: 25,
      winningAmount: 45,
      participants: 64,
      timeLeft: "45m",
      difficulty: "Intermediate",
      isHot: false,
      image: "assets/images/figures/black/knight.png",
    ),
    ChessMatch(
      name: "Rookie Challenge",
      entryFee: 10,
      winningAmount: 17,
      participants: 32,
      timeLeft: "1h 15m",
      difficulty: "Beginner",
      isHot: false,
      image: "assets/images/figures/black/pawn.png",
    ),
    ChessMatch(
      name: "Lightning Round",
      entryFee: 50,
      winningAmount: 80,
      participants: 96,
      timeLeft: "3h 45m",
      difficulty: "Advanced",
      isHot: true,
      image: "assets/images/figures/black/queen.png",
    ),
    ChessMatch(
      name: "Daily Showdown",
      entryFee: 5,
      winningAmount: 8,
      participants: 16,
      timeLeft: "6h 20m",
      difficulty: "Casual",
      isHot: false,
      image: "assets/images/figures/black/rook.png",
    ),
  ];
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1a1a2e),
              Color(0xFF16213e),
              Color(0xFF0f3460),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header Section
              Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Chess Master",
                              style: GoogleFonts.orbitron(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "Choose your battle",
                              style: GoogleFonts.orbitron(
                                color: Colors.grey[400],
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: MyColors.red,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.circle, color: Colors.white, size: 8),
                              SizedBox(width: 5),
                              Text(
                                "LIVE",
                                style: GoogleFonts.orbitron(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Container(
                        //   padding: EdgeInsets.all(12),
                        //   decoration: BoxDecoration(
                        //     color: Colors.orange.withValues(alpha: 0.2),
                        //     borderRadius: BorderRadius.circular(15),
                        //     border: Border.all(color: Colors.orange, width: 1),
                        //   ),
                        //   child: Row(
                        //     children: [
                        //       Icon(Icons.account_balance_wallet,
                        //           color: Colors.orange, size: 20),
                        //       SizedBox(width: 8),
                        //       Text(
                        //         "₹2,450",
                        //         style: GoogleFonts.orbitron(
                        //           color: Colors.orange,
                        //           fontWeight: FontWeight.bold,
                        //           fontSize: 16,
                        //         ),
                        //       ),
                        //     ],
                        //   ),
                        // ),
                      ],
                    ),
                    SizedBox(height: 20),
                    SizedBox(
                      height: 20,
                      child: TabBar(
                        controller: _tabController,
                        dividerColor: MyColors.transparent,
                        unselectedLabelColor: MyColors.white,
                        indicator: UnderlineTabIndicator(
                          borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(15),
                              topRight: Radius.circular(15)),
                          borderSide: BorderSide(
                            color: MyColors.amber,
                            width: 5,
                          ),
                          insets: const EdgeInsets.only(bottom: 5),
                        ),
                        labelColor: MyColors.amber,
                        tabs: [
                          Tab(
                              icon: Icon(
                            Icons.cloud_outlined,
                            color: MyColors.transparent,
                          )),
                          Tab(
                              icon: Icon(
                            Icons.beach_access_sharp,
                            color: MyColors.transparent,
                          )),
                          Tab(
                            icon: Icon(
                              Icons.brightness_5_sharp,
                              color: MyColors.transparent,
                            ),
                          ),
                          Tab(
                            icon: Icon(
                              Icons.brightness_5_sharp,
                              color: MyColors.transparent,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TabBar(
                      controller: _tabController,
                      dividerColor: Colors.transparent,
                      unselectedLabelColor: Colors.white,
                      indicator: const TorchLightIndicator(
                        color: Colors.amber,
                        radius: 30.0,
                      ),
                      labelColor: Colors.yellow[700],
                      tabs: const [
                        Tab(
                          icon: Column(
                            children: [Icon(Icons.home), Text("Home")],
                          ),
                        ),
                        Tab(
                          icon: Column(
                            children: [Icon(Icons.history), Text("History")],
                          ),
                        ),
                        Tab(
                          icon: Column(
                            children: [Icon(Icons.person), Text("Profile")],
                          ),
                        ),
                        Tab(
                          icon: Column(
                            children: [Icon(Icons.wallet), Text("Wallet")],
                          ),
                        ),
                      ],
                    ),
                    // SizedBox(
                    //   height: 20,
                    //   child: TabBar(
                    //     controller: _tabController,
                    //     dividerColor: Colors.transparent,
                    //     unselectedLabelColor: Colors.white,
                    //     indicator: UnderlineTabIndicator(
                    //       borderRadius: const BorderRadius.only(
                    //           bottomLeft: Radius.circular(15),
                    //           bottomRight: Radius.circular(15)),
                    //       borderSide: BorderSide(
                    //         color: Colors.amber,
                    //         width: 5,
                    //       ),
                    //       insets: const EdgeInsets.only(bottom: 10),
                    //     ),
                    //     indicatorWeight: 10,
                    //     labelColor: Colors.amber,
                    //     tabs: [
                    //       Tab(
                    //           icon: Icon(
                    //         Icons.cloud_outlined,
                    //         color: Colors.transparent,
                    //       )),
                    //       Tab(
                    //           icon: Icon(
                    //         Icons.beach_access_sharp,
                    //         color: Colors.transparent,
                    //       )),
                    //       Tab(
                    //         icon: Icon(
                    //           Icons.brightness_5_sharp,
                    //           color: Colors.transparent,
                    //         ),
                    //       ),
                    //       Tab(
                    //         icon: Icon(
                    //           Icons.wallet,
                    //           color: Colors.transparent,
                    //         ),
                    //       ),
                    //     ],
                    //   ),
                    // ),
                  ],
                ),
              ),

              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: <Widget>[
                    // Matches List
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF0f3460),
                            Color(0xFF16213e),
                            Color(0xFF1a1a2e),
                          ],
                        ),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                        ),
                      ),
                      child: Column(
                        children: [
                          // Padding(
                          //   padding: EdgeInsets.all(20),
                          //   child: Row(
                          //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          //     children: [
                          //       Text(
                          //         "Live Tournaments",
                          //         style: GoogleFonts.orbitron(
                          //           fontSize: 22,
                          //           fontWeight: FontWeight.bold,
                          //           color: Colors.white,
                          //         ),
                          //       ),
                          //       Container(
                          //         padding: EdgeInsets.symmetric(
                          //             horizontal: 12, vertical: 6),
                          //         decoration: BoxDecoration(
                          //           color: Colors.red,
                          //           borderRadius: BorderRadius.circular(20),
                          //         ),
                          //         child: Row(
                          //           children: [
                          //             Icon(Icons.circle,
                          //                 color: Colors.white, size: 8),
                          //             SizedBox(width: 5),
                          //             Text(
                          //               "LIVE",
                          //               style: GoogleFonts.orbitron(
                          //                 color: Colors.white,
                          //                 fontSize: 12,
                          //                 fontWeight: FontWeight.bold,
                          //               ),
                          //             ),
                          //           ],
                          //         ),
                          //       ),
                          //     ],
                          //   ),
                          // ),

                          Expanded(
                            child: ListView.builder(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              itemCount: matches.length,
                              itemBuilder: (context, index) {
                                return _buildMatchCard(matches[index]);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    HistoryScreen(),
                    ProfileScreen(),

                    WalletScreen(),
                    // Column(
                    //   children: [
                    //     Row(
                    //       spacing: 8,
                    //       mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    //       children: [
                    //         Expanded(
                    //           child: _buildStatCard(
                    //               "Matches Won", "47", Icons.emoji_events),
                    //         ),
                    //         Expanded(
                    //           child: _buildStatCard(
                    //               "Win Rate", "73%", Icons.trending_up),
                    //         ),
                    //         Expanded(
                    //             child: _buildStatCard(
                    //                 "Rank", "#124", Icons.leaderboard)),
                    //       ],
                    //     ),
                    //   ],
                    // ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMatchCard(ChessMatch match) {
    return Container(
      margin: EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: match.isHot
              ? [Colors.orange.shade400, Colors.red.shade500]
              : [Colors.blue.shade600, Colors.purple.shade600],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (match.isHot ? Colors.orange : Colors.blue)
                .withValues(alpha: 0.3),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background Pattern
          Positioned(
            right: 00,
            top: 10,
            child: Opacity(
              opacity: 0.3,
              child: Image.asset(
                match.image,
                height: 50,
              ),
            ),
          ),

          Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (match.isHot)
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.local_fire_department,
                                      color: Colors.orange, size: 16),
                                  SizedBox(width: 4),
                                  Text(
                                    "HOT",
                                    style: GoogleFonts.orbitron(
                                      color: Colors.orange,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          SizedBox(height: 8),
                          Text(
                            match.name,
                            style: GoogleFonts.orbitron(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "${match.difficulty} • ${match.participants} players",
                            style: GoogleFonts.orbitron(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          margin: EdgeInsets.only(right: 10),
                          padding:
                              EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Text(
                            match.timeLeft,
                            style: GoogleFonts.orbitron(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          "Time Left",
                          style: GoogleFonts.orbitron(
                            color: Colors.white.withValues(alpha: 0.2),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Entry Fee
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Entry Fee",
                          style: GoogleFonts.orbitron(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          "₹${match.entryFee}",
                          style: GoogleFonts.orbitron(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    // Prize Pool
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          "Win",
                          style: GoogleFonts.orbitron(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 14,
                          ),
                        ),
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.yellow.shade400,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Text(
                            "₹${match.winningAmount}",
                            style: GoogleFonts.orbitron(
                              color: Colors.black,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Join Button
                    ElevatedButton(
                      onPressed: () {
                        Get.to(() => PlayerSearchScreen());
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor:
                            match.isHot ? Colors.orange : Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        padding:
                            EdgeInsets.symmetric(horizontal: 25, vertical: 12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.play_arrow, size: 20),
                          SizedBox(width: 4),
                          Text(
                            "JOIN",
                            style: GoogleFonts.orbitron(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
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

class ChessMatch {
  final String name;
  final int entryFee;
  final int winningAmount;
  final int participants;
  final String timeLeft;
  final String difficulty;
  final String image;
  final bool isHot;

  ChessMatch({
    required this.name,
    required this.entryFee,
    required this.winningAmount,
    required this.participants,
    required this.timeLeft,
    required this.difficulty,
    required this.image,
    required this.isHot,
  });
}

class PlayerSearchScreen extends StatefulWidget {
  const PlayerSearchScreen({super.key});

  @override
  State<PlayerSearchScreen> createState() => _PlayerSearchScreenState();
}

class _PlayerSearchScreenState extends State<PlayerSearchScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late AnimationController _rotationController;
  late AnimationController _matchFoundController;

  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _matchFoundAnimation;

  bool isSearching = true;
  bool matchFound = false;
  int currentPlayerIndex = 0;
  Timer? _playerSwitchTimer;
  String searchStatus = "Searching for opponent...";

  final List<PlayerProfile> availablePlayers = [
    PlayerProfile(
      name: "Alex Chen",
      rating: 1450,
      winRate: 68,
      avatar: "assets/player1.png",
      country: "🇨🇳",
    ),
    PlayerProfile(
      name: "Sarah Johnson",
      rating: 1520,
      winRate: 72,
      avatar: "assets/player2.png",
      country: "🇺🇸",
    ),
    PlayerProfile(
      name: "Mike Rodriguez",
      rating: 1380,
      winRate: 65,
      avatar: "assets/player3.png",
      country: "🇪🇸",
    ),
    PlayerProfile(
      name: "Emma Wilson",
      rating: 1600,
      winRate: 78,
      avatar: "assets/player4.png",
      country: "🇬🇧",
    ),
    PlayerProfile(
      name: "David Kim",
      rating: 1490,
      winRate: 70,
      avatar: "assets/player5.png",
      country: "🇰🇷",
    ),
  ];

  final PlayerProfile myProfile = PlayerProfile(
    name: "You",
    rating: 1475,
    winRate: 73,
    avatar: "assets/my_avatar.png",
    country: "🇮🇳",
  );

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startSearching();
  }

  void _setupAnimations() {
    // Pulse animation for searching effect
    _pulseController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Slide animation for player switching (top to bottom)
    _slideController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: Offset(0.0, -1.0),
      end: Offset(0.0, 0.0),
    ).animate(
        CurvedAnimation(parent: _slideController, curve: Curves.elasticOut));

    // Rotation animation for VS symbol
    _rotationController = AnimationController(
      duration: Duration(seconds: 3),
      vsync: this,
    );
    _rotationAnimation = Tween<double>(begin: 0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.linear),
    );

    // Match found animation
    _matchFoundController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    );
    _matchFoundAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _matchFoundController, curve: Curves.bounceOut),
    );
  }

  void _startSearching() {
    _pulseController.repeat(reverse: true);
    _rotationController.repeat();

    _playerSwitchTimer = Timer.periodic(Duration(milliseconds: 1500), (timer) {
      if (isSearching) {
        setState(() {
          currentPlayerIndex =
              (currentPlayerIndex + 1) % availablePlayers.length;
        });
        _slideController.reset();
        _slideController.forward();

        // Simulate finding a match after 8 seconds
        if (timer.tick >= 5) {
          _foundMatch();
        }
      }
    });

    _slideController.forward();
  }

  void _foundMatch() {
    setState(() {
      isSearching = false;
      matchFound = true;
      searchStatus = "Match Found!";
    });

    _playerSwitchTimer?.cancel();
    _pulseController.stop();
    _rotationController.stop();
    _matchFoundController.forward();

    // Navigate to game after 3 seconds
    Timer(Duration(seconds: 3), () {
      _showMatchFoundDialog();
    });
  }

  void _showMatchFoundDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xFF1a1a2e),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 60),
              SizedBox(height: 20),
              Text(
                "Ready to Play!",
                style: GoogleFonts.orbitron(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10),
              Text(
                "Match found with ${availablePlayers[currentPlayerIndex].name}",
                style:
                    GoogleFonts.orbitron(color: Colors.grey[400], fontSize: 16),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Get.to(() => single.BoardGame());
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                ),
                child: Text(
                  "START GAME",
                  style: GoogleFonts.orbitron(
                    color: MyColors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1a1a2e),
              Color(0xFF16213e),
              Color(0xFF0f3460),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: EdgeInsets.all(20),
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.arrow_back, color: Colors.white),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Finding Opponent",
                            style: GoogleFonts.orbitron(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            searchStatus,
                            style: GoogleFonts.orbitron(
                              color: matchFound ? Colors.green : Colors.orange,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(30),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Player profiles section
                      SizedBox(
                        width: Get.width,
                        height: 400,
                        child: Stack(
                          children: [
                            // My Profile (Static)
                            Positioned(
                                top: 0,
                                left: 0,
                                child: _buildPlayerCard(myProfile, isMe: true)),
                            // Opponent Profile with sliding animation
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: SizedBox(
                                height: 200, // Fixed height container
                                width: 180, // Fixed width
                                child: ClipRect(
                                  child: Stack(
                                    children: [
                                      // Current player sliding in from top
                                      SlideTransition(
                                        position: _slideAnimation,
                                        child: _buildPlayerCard(
                                          availablePlayers[currentPlayerIndex],
                                          isMe: false,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            // VS Symbol
                            Positioned(
                              top: 0,
                              bottom: 0,
                              right: 0,
                              left: 0,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  AnimatedBuilder(
                                    animation: _rotationAnimation,
                                    builder: (context, child) {
                                      return Transform.rotate(
                                        angle: isSearching
                                            ? _rotationAnimation.value
                                            : 0,
                                        child: Container(
                                          width: 80,
                                          height: 80,
                                          decoration: BoxDecoration(
                                            color: matchFound
                                                ? Colors.green
                                                : Colors.orange,
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: (matchFound
                                                        ? Colors.green
                                                        : Colors.orange)
                                                    .withValues(alpha: 0.5),
                                                blurRadius: 20,
                                                spreadRadius: 5,
                                              ),
                                            ],
                                          ),
                                          child: Center(
                                            child: Text(
                                              "VS",
                                              style: GoogleFonts.orbitron(
                                                color: Colors.white,
                                                fontSize: 24,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 50),

                      // Search Progress
                      if (isSearching)
                        Column(
                          children: [
                            Container(
                              width: 200,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(2),
                              ),
                              child: AnimatedBuilder(
                                animation: _pulseController,
                                builder: (context, child) {
                                  return LinearProgressIndicator(
                                    backgroundColor: Colors.transparent,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.orange.withValues(
                                          alpha: _pulseAnimation.value - 0.8),
                                    ),
                                  );
                                },
                              ),
                            ),
                            SizedBox(height: 20),
                            Text(
                              "Checking ${(currentPlayerIndex * 347 + 1250)} players...",
                              style: GoogleFonts.orbitron(
                                color: Colors.grey[400],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),

                      // Match Found Animation
                      if (matchFound)
                        AnimatedBuilder(
                          animation: _matchFoundAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _matchFoundAnimation.value,
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.celebration,
                                    color: Colors.green,
                                    size: 50,
                                  ),
                                  SizedBox(height: 10),
                                  Text(
                                    "Perfect Match!",
                                    style: GoogleFonts.orbitron(
                                      color: Colors.green,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    "Similar skill level detected",
                                    style: GoogleFonts.orbitron(
                                      color: Colors.grey[400],
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),

              // Cancel Button
              if (isSearching)
                Padding(
                  padding: EdgeInsets.all(30),
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: MyColors.red.withValues(alpha: 0.2),
                      side: BorderSide(color: MyColors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      padding:
                          EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    ),
                    child: Text(
                      "CANCEL SEARCH",
                      style: GoogleFonts.orbitron(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerCard(PlayerProfile player, {required bool isMe}) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 500),
      width: 180,
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isMe
              ? [Colors.blue.shade600, Colors.blue.shade800]
              : matchFound
                  ? [Colors.green.shade600, Colors.green.shade800]
                  : [Colors.purple.shade600, Colors.purple.shade800],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (isMe
                    ? Colors.blue
                    : matchFound
                        ? Colors.green
                        : Colors.purple)
                .withValues(alpha: 0.3),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Avatar
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                player.country,
                style: GoogleFonts.orbitron(fontSize: 30),
              ),
            ),
          ),
          SizedBox(height: 10),

          // Name
          Text(
            player.name,
            style: GoogleFonts.orbitron(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 5),

          // Rating
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              "${player.rating}",
              style: GoogleFonts.orbitron(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(height: 5),

          // Win Rate
          Text(
            "${player.winRate}% wins",
            style: GoogleFonts.orbitron(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _slideController.dispose();
    _rotationController.dispose();
    _matchFoundController.dispose();
    _playerSwitchTimer?.cancel();
    super.dispose();
  }
}

class PlayerProfile {
  final String name;
  final int rating;
  final int winRate;
  final String avatar;
  final String country;

  PlayerProfile({
    required this.name,
    required this.rating,
    required this.winRate,
    required this.avatar,
    required this.country,
  });
}

class TorchLightIndicator extends Decoration {
  final double radius;
  final Color color;

  const TorchLightIndicator({
    this.radius = 20.0,
    this.color = Colors.amber,
  });

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) {
    return _TorchLightPainter(this, onChanged);
  }
}

class _TorchLightPainter extends BoxPainter {
  final TorchLightIndicator decoration;

  _TorchLightPainter(this.decoration, VoidCallback? onChanged)
      : super(onChanged);

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final Rect rect = offset & configuration.size!;
    final Paint paint = Paint()
      ..color = decoration.color.withValues(alpha: 0.2);
    final RRect rrect = RRect.fromRectAndRadius(
      Rect.fromCircle(
        center: rect.center,
        radius: decoration.radius,
      ),
      const Radius.circular(50.0),
    );

    // Apply the box shadow for the glowing effect
    final Paint shadowPaint = Paint()
      ..color = decoration.color.withValues(alpha: 0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15.0);

    canvas.drawRRect(rrect, shadowPaint);
    canvas.drawRRect(rrect, paint);
  }
}

class ChessMatchHistory {
  final String opponentName;
  final String result; // e.g., "Win", "Loss", "Draw"
  final String gameType; // e.g., "Blitz", "Rapid"
  final String date;
  final String opponentImage;

  ChessMatchHistory({
    required this.opponentName,
    required this.result,
    required this.gameType,
    required this.date,
    required this.opponentImage,
  });
}

class HistoryScreen extends StatelessWidget {
  HistoryScreen({super.key});

  final List<ChessMatchHistory> pastMatches = [
    ChessMatchHistory(
      opponentName: "Magnus Carlsen",
      result: "Win",
      gameType: "Blitz",
      date: "Aug 12, 2024",
      opponentImage:
          "assets/images/figures/black/king.png", // Use a relevant asset
    ),
    ChessMatchHistory(
      opponentName: "Hikaru Nakamura",
      result: "Loss",
      gameType: "Rapid",
      date: "Aug 10, 2024",
      opponentImage: "assets/images/figures/black/queen.png",
    ),
    ChessMatchHistory(
      opponentName: "Garry Kasparov",
      result: "Draw",
      gameType: "Classic",
      date: "Aug 08, 2024",
      opponentImage: "assets/images/figures/black/knight.png",
    ),
    ChessMatchHistory(
      opponentName: "Anish Giri",
      result: "Win",
      gameType: "Blitz",
      date: "Aug 05, 2024",
      opponentImage: "assets/images/figures/black/rook.png",
    ),
    ChessMatchHistory(
      opponentName: "Fabiano Caruana",
      result: "Loss",
      gameType: "Rapid",
      date: "Aug 03, 2024",
      opponentImage: "assets/images/figures/black/bishop.png",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyColors.historyBackground,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: pastMatches.length,
          itemBuilder: (context, index) {
            final match = pastMatches[index];
            return _buildMatchHistoryCard(match);
          },
        ),
      ),
    );
  }

  Widget _buildMatchHistoryCard(ChessMatchHistory match) {
    Color cardColor;
    Color resultColor;
    IconData resultIcon;

    if (match.result == "Win") {
      cardColor = Colors.green.shade400;
      resultColor = Colors.green;
      resultIcon = Icons.check_circle;
    } else if (match.result == "Loss") {
      cardColor = Colors.red.shade400;
      resultColor = Colors.red;
      resultIcon = Icons.cancel;
    } else {
      cardColor = Colors.yellow.shade400;
      resultColor = Colors.yellow;
      resultIcon = Icons.horizontal_rule;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        color: const Color(0xFF16213e),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: cardColor.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: cardColor.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16.0),
        leading: CircleAvatar(
          backgroundColor: Colors.white.withValues(alpha: 0.1),
          radius: 30,
          child: Image.asset(
            match.opponentImage,
            height: 40,
          ),
        ),
        title: Text(
          "vs ${match.opponentName}",
          style: GoogleFonts.orbitron(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        subtitle: Text(
          "${match.gameType} • ${match.date}",
          style: GoogleFonts.orbitron(
            color: Colors.grey[400],
            fontSize: 14,
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(resultIcon, color: resultColor, size: 24),
            const SizedBox(height: 4),
            Text(
              match.result,
              style: GoogleFonts.orbitron(
                color: resultColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// A simple data model for the user profile
class UserProfile {
  final String name;
  final String username;
  final int rating;
  final int wins;
  final int losses;
  final int draws;
  final String avatarImage;
  final List<String> achievements;

  UserProfile({
    required this.name,
    required this.username,
    required this.rating,
    required this.wins,
    required this.losses,
    required this.draws,
    required this.avatarImage,
    required this.achievements,
  });
}

class ProfileScreen extends StatelessWidget {
  ProfileScreen({super.key});

  // Mock data for the user profile
  final UserProfile currentUser = UserProfile(
    name: "John Doe",
    username: "@johndoe",
    rating: 1850,
    wins: 154,
    losses: 82,
    draws: 21,
    avatarImage: "assets/images/figures/black/king.png",
    achievements: [
      "First Win",
      "100 Wins Club",
      "King Slayer",
      "Expert Strategist",
    ],
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Profile Picture
              CircleAvatar(
                radius: 60,
                backgroundColor: Colors.white.withValues(alpha: 0.1),
                child: Image.asset(
                  currentUser.avatarImage,
                  height: 80,
                ),
              ),
              const SizedBox(height: 16.0),

              // User Name and Username
              Text(
                currentUser.name,
                style: GoogleFonts.orbitron(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4.0),
              Text(
                currentUser.username,
                style: GoogleFonts.orbitron(
                  color: Colors.grey[400],
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 24.0),

              // Statistics Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatCard("Rating", "${currentUser.rating}", Icons.star),
                  _buildStatCard(
                      "Wins", "${currentUser.wins}", Icons.emoji_events),
                  _buildStatCard("Losses", "${currentUser.losses}", Icons.flag),
                  _buildStatCard(
                      "Draws", "${currentUser.draws}", Icons.balance),
                ],
              ),
              const SizedBox(height: 32.0),

              // Achievements Section
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Achievements",
                  style: GoogleFonts.orbitron(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16.0),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: const Color(0xFF16213e),
                  borderRadius: BorderRadius.circular(15.0),
                ),
                child: Column(
                  children: currentUser.achievements.map((achievement) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle,
                              color: Colors.amber, size: 24),
                          const SizedBox(width: 12.0),
                          Text(
                            achievement,
                            style: GoogleFonts.orbitron(
                              color: MyColors.white,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // A helper function to build the stat cards
  Widget _buildStatCard(String title, String value, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          ),
          child: Icon(icon, color: Colors.white, size: 28),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.orbitron(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          title,
          style: GoogleFonts.orbitron(
            color: Colors.grey[400],
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

// A simple data model for a transaction
class Transaction {
  final String description;
  final double amount;
  final DateTime date;
  final bool isDeposit;

  Transaction({
    required this.description,
    required this.amount,
    required this.date,
    required this.isDeposit,
  });
}

class WalletScreen extends StatelessWidget {
  WalletScreen({super.key});

  // Mock data for the user's wallet
  final double currentBalance = 2450.0;
  final List<Transaction> recentTransactions = [
    Transaction(
      description: "Match Win: Grand Master",
      amount: 180.0,
      date: DateTime.now().subtract(const Duration(hours: 2)),
      isDeposit: true,
    ),
    Transaction(
      description: "Entry Fee: Speed Blitz",
      amount: 25.0,
      date: DateTime.now().subtract(const Duration(hours: 5)),
      isDeposit: false,
    ),
    Transaction(
      description: "Deposit from Card",
      amount: 500.0,
      date: DateTime.now().subtract(const Duration(days: 1)),
      isDeposit: true,
    ),
    Transaction(
      description: "Match Loss: Rookie Challenge",
      amount: 10.0,
      date: DateTime.now().subtract(const Duration(days: 2)),
      isDeposit: false,
    ),
    Transaction(
      description: "Withdrawal to Bank",
      amount: 200.0,
      date: DateTime.now().subtract(const Duration(days: 3)),
      isDeposit: false,
    ),
  ];

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Current Balance Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.blue.shade600,
                      Colors.purple.shade600,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(25.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purple.withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      "Current Balance",
                      style: GoogleFonts.orbitron(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      "₹${currentBalance.toStringAsFixed(2)}",
                      style: GoogleFonts.orbitron(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildWalletButton(
                          icon: Icons.add_circle_outline,
                          label: "Add Funds",
                          onPressed: () {},
                        ),
                        _buildWalletButton(
                          icon: Icons.account_balance_wallet_outlined,
                          label: "Withdraw",
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32.0),

              // Recent Transactions Section
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Recent Transactions",
                  style: GoogleFonts.orbitron(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16.0),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: const Color(0xFF16213e),
                  borderRadius: BorderRadius.circular(15.0),
                ),
                child: Column(
                  children: recentTransactions.map((transaction) {
                    return _buildTransactionCard(transaction);
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // A helper function to build the action buttons
  Widget _buildWalletButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: BorderSide(color: Colors.white.withValues(alpha: 0.5)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
      icon: Icon(icon, size: 20),
      label: Text(label, style: GoogleFonts.orbitron(fontSize: 16)),
    );
  }

  // A helper function to build the transaction list tile
  Widget _buildTransactionCard(Transaction transaction) {
    Color iconColor =
        transaction.isDeposit ? Colors.green.shade400 : Colors.red.shade400;
    IconData icon =
        transaction.isDeposit ? Icons.arrow_upward : Icons.arrow_downward;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 16.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.description,
                  style: GoogleFonts.orbitron(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  _formatDate(transaction.date),
                  style: GoogleFonts.orbitron(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            "${transaction.isDeposit ? '+' : '-'} ₹${transaction.amount.toStringAsFixed(2)}",
            style: GoogleFonts.orbitron(
              color: transaction.isDeposit
                  ? Colors.green.shade400
                  : Colors.red.shade400,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
