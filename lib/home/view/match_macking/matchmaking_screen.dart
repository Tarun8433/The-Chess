import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:the_chess/home/view/match_macking/match_macking_animations.dart';
import 'package:the_chess/home/controller/matchmaking_controller.dart';
import 'package:the_chess/home/view/match_macking/match_not_found_screen.dart';
import 'package:the_chess/values/colors.dart';

// Updated MatchmakingScreen with better state handling
class MatchmakingScreen extends StatefulWidget {
  const MatchmakingScreen({super.key});

  @override
  State<MatchmakingScreen> createState() => _MatchmakingScreenState();
}

class _MatchmakingScreenState extends State<MatchmakingScreen> {
  @override
  void initState() {
    super.initState();
    // Reset navigation state when entering matchmaking screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = Get.find<MatchmakingController>();
      controller.resetNavigationState();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Initialize controller
    final controller = Get.put(MatchmakingController());

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Obx(() {
        // If user has been navigated to game, don't show matchmaking interface
        if (controller.hasNavigatedToGame) {
          return Center(
            child: CircularProgressIndicator(
              color: MyColors.lightGray,
            ),
          );
        }

        // If searching has ended and match was found, controller will handle navigation
        // If searching has ended and no match found, show the else part (main interface)
        return Stack(
          children: [
            if (controller.isSearching)
              Positioned(
                top: 100,
                right: -50,
                child: Transform.rotate(
                  angle: 0.3,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: MyColors.lightGray.withValues(alpha: 0.05),
                    ),
                    child: CustomPaint(
                      painter: ChessPatternPainter(),
                    ),
                  ),
                ),
              ),
            // VS Battle Animation background when searching
            if (controller.isSearching) ...[
              VSBattleWidget(showRestartButton: false),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: Get.width * 0.1),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    SizedBox(height: 160),
                    _buildSearchingHeader(controller),
                    Spacer(),
                    _buildQuickStatsSection(),
                    SizedBox(height: 26),
                    // Show stop button only if not navigating
                    !controller.isNavigating
                        ? _buildStopButton(controller)
                        : SizedBox(height: 45),
                    SizedBox(
                      height: Get.height * .06,
                    ),
                  ],
                ),
              ),
            ],
            // Main content overlay
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (controller.isSearching) ...[
                    SizedBox(),
                    SizedBox(),
                    SizedBox(height: 10),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildPlayerSlots(),
                        SizedBox(height: 130),
                        _buildOpponentSlider(),
                      ],
                    ),
                    SizedBox(),
                    SizedBox(),
                    SizedBox(),
                  ] else ...[
                    // When searching ends, show the main interface (else part)
                    // This will be shown if no match is found or user stops searching
                    const Spacer(),
                    _buildWelcomeSection(),
                    const Spacer(),
                    _buildQuickStatsSection(),
                    const SizedBox(height: 30),
                    _buildGameModesSection(),
                    const Spacer(),
                    _buildStartButton(controller),
                    const Spacer(),
                  ],
                ],
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildSearchingHeader(MatchmakingController controller) {
    return Obx(() {
      return Column(
        children: [
          Text(
            controller.isMatchFound
                ? 'Match Found!'
                : 'Looking for someone to join',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          Text(
            controller.searchStatus,
            style: TextStyle(
                fontSize: 14,
                color: controller.isMatchFound
                    ? Colors.green.shade300
                    : Colors.white),
          ),
        ],
      );
    });
  }

  Widget _buildPlayerSlots() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(8),
            ),
            height: 100,
            width: 100,
            clipBehavior: Clip.hardEdge,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.0, 1.0),
                    end: const Offset(0.0, 0.0),
                  ).animate(animation),
                  child: child,
                );
              },
              child: Image.asset(
                imageList[0],
                key: ValueKey<int>(0),
                fit: BoxFit.cover,
                height: 100,
                width: 100,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOpponentSlider() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 40),
      child: SimpleVerticalImageSlider(
        imagePaths: imageList,
        height: 100,
        width: 100,
        tag: 'opponent_slider',
      ),
    );
  }

  Widget _buildStopButton(MatchmakingController controller) {
    return Center(
      child: ElevatedButton(
        onPressed: controller.stopSearching,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white.withValues(alpha: 0.2),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
            side: const BorderSide(color: Colors.white, width: 2),
          ),
        ),
        child: const Text(
          'Stop Searching',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: MyColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MyColors.lightGray.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: MyColors.lightGray.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.sports_esports,
              size: 40,
              color: MyColors.lightGray,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Ready to Play Chess?',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: MyColors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Find opponents from around the world and test your chess skills',
            style: TextStyle(
              fontSize: 16,
              color: MyColors.mediumGray,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>> _getQuickStats() async {
    final controller = Get.find<MatchmakingController>();
    try {
      final playerCounts = await controller.getPlayerCounts();
      final gamesToday = await controller.getTodayGamesCount();

      return {
        'playersOnline':
            (playerCounts['queue'] ?? 0) + (playerCounts['active'] ?? 0),
        'gamesToday': gamesToday,
      };
    } catch (e) {
      return {'playersOnline': 0, 'gamesToday': 0};
    }
  }

  Widget _buildQuickStatsSection() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: MyColors.white.withValues(alpha: 0.5)),
      ),
      child: FutureBuilder<Map<String, dynamic>>(
        future: _getQuickStats(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          }

          if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          }

          final stats = snapshot.data ?? {'playersOnline': 0, 'gamesToday': 0};

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                  '${stats['playersOnline']}', 'Players Online', Icons.people),
              _buildStatItem('${stats['gamesToday']}', 'Games Today',
                  Icons.playlist_remove),
              _buildStatItem('2.5s', 'Avg Wait Time', Icons.timer),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: MyColors.white, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: MyColors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: MyColors.mediumGray,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildGameModesSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: MyColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: MyColors.lightGray.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Game Modes Available',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: MyColors.white,
            ),
          ),
          const SizedBox(height: 16),
          _buildGameModeItem('Blitz', '5 min per player', Icons.flash_on, true),
          // _buildGameModeItem('Rapid', '10 min per player', Icons.speed, false),
          // _buildGameModeItem(
          //     'Classic', '30 min per player', Icons.access_time, false),
        ],
      ),
    );
  }

  Widget _buildGameModeItem(
      String title, String subtitle, IconData icon, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSelected
            ? MyColors.lightGray.withValues(alpha: 0.2)
            : MyColors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected
              ? MyColors.lightGray
              : MyColors.tealGray.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: isSelected ? MyColors.lightGray : MyColors.mediumGray,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? MyColors.white : MyColors.mediumGray,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: isSelected ? MyColors.mediumGray : MyColors.tealGray,
                  ),
                ),
              ],
            ),
          ),
          if (isSelected)
            const Icon(
              Icons.check_circle,
              color: MyColors.lightGray,
              size: 20,
            ),
        ],
      ),
    );
  }

  Widget _buildStartButton(MatchmakingController controller) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: controller.startSearching,
        style: ElevatedButton.styleFrom(
          backgroundColor: MyColors.lightGray,
          foregroundColor: MyColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 20),
            SizedBox(width: 8),
            Text(
              'Find Opponent',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}




// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:the_chess/home/view/match_macking/match_macking_animations.dart';
// import 'package:the_chess/home/controller/matchmaking_controller.dart';
// import 'package:the_chess/values/colors.dart';

// // Updated MatchmakingScreen with better state handling
// class MatchmakingScreen extends StatelessWidget {
//   const MatchmakingScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     // Initialize controller
//     final controller = Get.put(MatchmakingController());

//     return Scaffold(
//       backgroundColor: MyColors.darkBackground,
//       body: Obx(() {
//         return Stack(
//           children: [
//             // Simple background pattern
//             Positioned.fill(
//               child: Container(
//                 decoration: BoxDecoration(
//                   gradient: LinearGradient(
//                     begin: Alignment.topCenter,
//                     end: Alignment.bottomCenter,
//                     colors: [
//                       MyColors.darkBackground,
//                       MyColors.cardBackground,
//                       MyColors.darkBackground,
//                     ],
//                   ),
//                 ),
//               ),
//             ),

//             // VS Battle Animation background when searching
//             if (controller.isSearching)
//               VSBattleWidget(showRestartButton: false),
//             if (controller.isSearching)
//               SizedBox(
//                   height: Get.height,
//                   width: Get.width,
//                   child: Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Padding(
//                         padding:
//                             EdgeInsets.symmetric(horizontal: Get.width * .1),
//                         child: _buildPlayerMatchSection(),
//                       ),
//                     ],
//                   )),
//             // Main content overlay
//             SafeArea(
//               child: Padding(
//                 padding: const EdgeInsets.all(20.0),
//                 child: Column(
//                   children: [
//                     if (controller.isSearching) ...[
//                       const SizedBox(height: 20),
//                       _buildSearchingHeader(controller),
//                       const Spacer(),
//                       SizedBox(),
//                       const Spacer(),
//                       _buildGameInfoSection(),
//                       const SizedBox(height: 20),
//                       if (!controller.isNavigating)
//                         _buildStopButton(controller),
//                       const SizedBox(height: 20),
//                     ] else ...[
//                       _buildWelcomeSection(),
//                       const Spacer(),
//                       _buildQuickStatsSection(),
//                       const SizedBox(height: 30),
//                       _buildGameModesSection(),
//                       const Spacer(),
//                       _buildStartButton(controller),
//                       const SizedBox(height: 40),
//                     ],
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         );
//       }),
//     );
//   }

//   Widget _buildWelcomeSection() {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(24),
//       decoration: BoxDecoration(
//         color: MyColors.cardBackground,
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(color: MyColors.lightGray.withValues(alpha: 0.3)),
//       ),
//       child: Column(
//         children: [
//           Container(
//             padding: const EdgeInsets.all(16),
//             decoration: BoxDecoration(
//               color: MyColors.lightGray.withValues(alpha: 0.2),
//               borderRadius: BorderRadius.circular(12),
//             ),
//             child: const Icon(
//               Icons.sports_esports,
//               size: 40,
//               color: MyColors.lightGray,
//             ),
//           ),
//           const SizedBox(height: 16),
//           const Text(
//             'Ready to Play Chess?',
//             style: TextStyle(
//               fontSize: 24,
//               fontWeight: FontWeight.bold,
//               color: MyColors.white,
//             ),
//             textAlign: TextAlign.center,
//           ),
//           const SizedBox(height: 8),
//           const Text(
//             'Find opponents from around the world and test your chess skills',
//             style: TextStyle(
//               fontSize: 16,
//               color: MyColors.mediumGray,
//             ),
//             textAlign: TextAlign.center,
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildQuickStatsSection() {
//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: MyColors.cardBackground,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: MyColors.tealGray.withValues(alpha: 0.3)),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Text(
//             'Quick Stats',
//             style: TextStyle(
//               fontSize: 18,
//               fontWeight: FontWeight.bold,
//               color: MyColors.white,
//             ),
//           ),
//           const SizedBox(height: 16),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceAround,
//             children: [
//               _buildStatItem('1,234', 'Players Online', Icons.people),
//               _buildStatItem('567', 'Games Today', Icons.playlist_remove),
//               _buildStatItem('2.5s', 'Avg Wait Time', Icons.timer),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildStatItem(String value, String label, IconData icon) {
//     return Column(
//       children: [
//         Icon(icon, color: MyColors.lightGray, size: 24),
//         const SizedBox(height: 8),
//         Text(
//           value,
//           style: const TextStyle(
//             fontSize: 20,
//             fontWeight: FontWeight.bold,
//             color: MyColors.white,
//           ),
//         ),
//         Text(
//           label,
//           style: const TextStyle(
//             fontSize: 12,
//             color: MyColors.mediumGray,
//           ),
//           textAlign: TextAlign.center,
//         ),
//       ],
//     );
//   }

//   Widget _buildGameModesSection() {
//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: MyColors.cardBackground,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: MyColors.lightGray.withValues(alpha: 0.2)),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Text(
//             'Game Modes Available',
//             style: TextStyle(
//               fontSize: 18,
//               fontWeight: FontWeight.bold,
//               color: MyColors.white,
//             ),
//           ),
//           const SizedBox(height: 16),
//           _buildGameModeItem('Blitz', '5 min per player', Icons.flash_on, true),
//           // _buildGameModeItem('Rapid', '10 min per player', Icons.speed, false),
//           // _buildGameModeItem(
//           //     'Classic', '30 min per player', Icons.access_time, false),
//         ],
//       ),
//     );
//   }

//   Widget _buildGameModeItem(
//       String title, String subtitle, IconData icon, bool isSelected) {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 8),
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: isSelected
//             ? MyColors.lightGray.withValues(alpha: 0.2)
//             : MyColors.transparent,
//         borderRadius: BorderRadius.circular(8),
//         border: Border.all(
//           color: isSelected
//               ? MyColors.lightGray
//               : MyColors.tealGray.withValues(alpha: 0.3),
//         ),
//       ),
//       child: Row(
//         children: [
//           Icon(
//             icon,
//             color: isSelected ? MyColors.lightGray : MyColors.mediumGray,
//             size: 20,
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   title,
//                   style: TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.w600,
//                     color: isSelected ? MyColors.white : MyColors.mediumGray,
//                   ),
//                 ),
//                 Text(
//                   subtitle,
//                   style: TextStyle(
//                     fontSize: 12,
//                     color: isSelected ? MyColors.mediumGray : MyColors.tealGray,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           if (isSelected)
//             const Icon(
//               Icons.check_circle,
//               color: MyColors.lightGray,
//               size: 20,
//             ),
//         ],
//       ),
//     );
//   }

//   Widget _buildSearchingHeader(MatchmakingController controller) {
//     return Obx(() {
//       return Container(
//         width: double.infinity,
//         padding: const EdgeInsets.all(20),
//         decoration: BoxDecoration(
//           // color: MyColors.cardBackground,
//           borderRadius: BorderRadius.circular(12),
//           border: Border.all(
//             color: controller.isMatchFound
//                 ? Colors.green.withValues(alpha: 0.5)
//                 : MyColors.lightGray.withValues(alpha: 0.3),
//           ),
//         ),
//         child: Column(
//           children: [
//             Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 if (!controller.isMatchFound) ...[
//                   SizedBox(
//                     width: 20,
//                     height: 20,
//                     child: CircularProgressIndicator(
//                       strokeWidth: 2,
//                       valueColor:
//                           AlwaysStoppedAnimation<Color>(MyColors.lightGray),
//                     ),
//                   ),
//                   const SizedBox(width: 12),
//                 ],
//                 Text(
//                   controller.isMatchFound
//                       ? 'Match Found!'
//                       : 'Searching for Opponent',
//                   style: TextStyle(
//                     fontSize: 20,
//                     fontWeight: FontWeight.bold,
//                     color:
//                         controller.isMatchFound ? Colors.green : MyColors.white,
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 8),
//             Text(
//               controller.searchStatus,
//               style: TextStyle(
//                 fontSize: 14,
//                 color: controller.isMatchFound
//                     ? Colors.green.shade300
//                     : MyColors.mediumGray,
//               ),
//             ),
//           ],
//         ),
//       );
//     });
//   }

//   Widget _buildPlayerMatchSection() {
//     return Column(
//       children: [
//         const Text(
//           'Match Preview',
//           style: TextStyle(
//             fontSize: 18,
//             fontWeight: FontWeight.bold,
//             color: MyColors.white,
//           ),
//         ),
//         const SizedBox(height: 20),
//         Column(
//           mainAxisAlignment: MainAxisAlignment.start,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Your player slot
//             Column(
//               children: [
//                 Container(
//                   width: 80,
//                   height: 80,
//                   decoration: BoxDecoration(
//                     color: MyColors.lightGray.withValues(alpha: 0.2),
//                     borderRadius: BorderRadius.circular(12),
//                     border: Border.all(color: MyColors.lightGray, width: 2),
//                   ),
//                   clipBehavior: Clip.hardEdge,
//                   child: Image.asset(
//                     imageList[0],
//                     fit: BoxFit.cover,
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//                 const Text(
//                   'YOU',
//                   style: TextStyle(
//                     color: MyColors.white,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 const Text(
//                   'Rating: 1200',
//                   style: TextStyle(
//                     color: MyColors.white,
//                     fontSize: 12,
//                   ),
//                 ),
//               ],
//             ),
//             SizedBox(height: 100),

//             // Opponent slot
//             Row(
//               mainAxisAlignment: MainAxisAlignment.end,
//               children: [
//                 SizedBox(
//                   height: 150,
//                   width: 100,
//                   child: Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     crossAxisAlignment: CrossAxisAlignment.center,
//                     children: [
//                       SimpleVerticalImageSlider(
//                         imagePaths: imageList,
//                         height: 80,
//                         width: 80,
//                         tag: 'opponent_slider',
//                       ),
//                       const SizedBox(height: 8),
//                       const Text(
//                         'OPPONENT',
//                         style: TextStyle(
//                           color: MyColors.white,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       const Text(
//                         'Finding...',
//                         style: TextStyle(
//                           color: MyColors.white,
//                           fontSize: 12,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ],
//     );
//   }

//   Widget _buildGameInfoSection() {
//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: MyColors.cardBackground,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: MyColors.lightGray.withValues(alpha: 0.2)),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Text(
//             'Game Details',
//             style: TextStyle(
//               fontSize: 18,
//               fontWeight: FontWeight.bold,
//               color: MyColors.white,
//             ),
//           ),
//           const SizedBox(height: 16),
//           _buildInfoRow('Mode', 'Blitz (5 min)', Icons.flash_on),
//           _buildInfoRow('Rating Range', '1100 - 1300', Icons.trending_up),
//           _buildInfoRow('Region', 'Global', Icons.public),
//           _buildInfoRow('Expected Wait', '< 30 seconds', Icons.timer),
//         ],
//       ),
//     );
//   }

//   Widget _buildInfoRow(String label, String value, IconData icon) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 12),
//       child: Row(
//         children: [
//           Icon(icon, color: MyColors.lightGray, size: 16),
//           const SizedBox(width: 12),
//           Text(
//             '$label: ',
//             style: const TextStyle(
//               color: MyColors.mediumGray,
//               fontSize: 14,
//             ),
//           ),
//           Text(
//             value,
//             style: const TextStyle(
//               color: MyColors.white,
//               fontSize: 14,
//               fontWeight: FontWeight.w600,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildStopButton(MatchmakingController controller) {
//     return SizedBox(
//       width: double.infinity,
//       height: 50,
//       child: ElevatedButton(
//         onPressed: controller.stopSearching,
//         style: ElevatedButton.styleFrom(
//           backgroundColor: Colors.red.shade600,
//           foregroundColor: MyColors.white,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(12),
//           ),
//         ),
//         child: const Row(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(Icons.stop, size: 20),
//             SizedBox(width: 8),
//             Text(
//               'Stop Searching',
//               style: TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildStartButton(MatchmakingController controller) {
//     return SizedBox(
//       width: double.infinity,
//       height: 56,
//       child: ElevatedButton(
//         onPressed: controller.startSearching,
//         style: ElevatedButton.styleFrom(
//           backgroundColor: MyColors.lightGray,
//           foregroundColor: MyColors.white,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(12),
//           ),
//         ),
//         child: const Row(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(Icons.search, size: 20),
//             SizedBox(width: 8),
//             Text(
//               'Find Opponent',
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

// }
 