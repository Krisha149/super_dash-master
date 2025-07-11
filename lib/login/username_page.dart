// import 'package:flutter/material.dart';
// import 'package:authentication_repository/authentication_repository.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'package:super_dash/game_intro/view/game_intro_page.dart';
//
// class UsernameEntryPage extends StatefulWidget {
//   final AuthenticationRepository authenticationRepository;
//
//   const UsernameEntryPage({
//     super.key,
//     required this.authenticationRepository,
//   });
//
//   @override
//   State<UsernameEntryPage> createState() => _UsernameEntryPageState();
// }
//
// class _UsernameEntryPageState extends State<UsernameEntryPage> {
//   final TextEditingController _usernameController = TextEditingController();
//   final _db = FirebaseDatabase.instance.ref();
//   bool _checking = true;
//
//   @override
//   void initState() {
//     super.initState();
//     _checkExistingUser();
//   }
//
//   Future<void> _checkExistingUser() async {
//     final user = widget.authenticationRepository.currentUser;
//     if (user != null) {
//       final snapshot = await _db.child('users/${user.id}/username').get();
//       if (snapshot.exists) {
//         _goToGame();
//         return;
//       }
//     } else {
//       await widget.authenticationRepository.signInAnonymously();
//     }
//     setState(() => _checking = false);
//   }
//
//   void _goToGame() {
//     Navigator.of(context).pushReplacement(
//       MaterialPageRoute(builder: (context) => const GameIntroPage()),
//     );
//   }
//
//   Future<void> _saveUsername() async {
//     final username = _usernameController.text.trim();
//     if (username.isEmpty) return;
//     final user = widget.authenticationRepository.currentUser;
//     if (user != null) {
//       await _db.child('users/${user.id}').set({'username': username});
//       _goToGame();
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     if (_checking) return const Center(child: CircularProgressIndicator());
//
//     return Scaffold(
//       body: Stack(
//         fit: StackFit.expand,
//         children: [
//           Image.asset('assets/images/intro_background_mobile.png',
//               fit: BoxFit.cover),
//           Center(
//             child: Padding(
//               padding: const EdgeInsets.all(24.0),
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   TextField(
//                     controller: _usernameController,
//                     decoration: const InputDecoration(
//                       hintText: 'Enter your username',
//                       filled: true,
//                       fillColor: Colors.black,
//                       border: OutlineInputBorder(),
//                     ),
//                   ),
//                   const SizedBox(height: 20),
//                   ElevatedButton(
//                     onPressed: _saveUsername,
//                     child: const Text('Continue'),
//                   )
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:authentication_repository/authentication_repository.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:super_dash/game_intro/view/game_intro_page.dart';

class UsernameEntryPage extends StatefulWidget {
  final AuthenticationRepository authenticationRepository;

  const UsernameEntryPage({
    super.key,
    required this.authenticationRepository,
  });

  @override
  State<UsernameEntryPage> createState() => _UsernameEntryPageState();
}

class _UsernameEntryPageState extends State<UsernameEntryPage> {
  final TextEditingController _usernameController = TextEditingController();
  final _db = FirebaseDatabase.instance.ref();
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    _checkExistingUser();
  }

  Future<void> _checkExistingUser() async {
    final user = widget.authenticationRepository.currentUser;
    if (user != null) {
      final snapshot = await _db.child('users/${user.id}/username').get();
      if (snapshot.exists) {
        _goToGame();
        return;
      }
    } else {
      await widget.authenticationRepository.signInAnonymously();
    }
    setState(() => _checking = false);
  }

  void _goToGame() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const GameIntroPage()),
    );
  }

  Future<void> _saveUsername() async {
    final username = _usernameController.text.trim();
    if (username.isEmpty) return;
    final user = widget.authenticationRepository.currentUser;
    if (user != null) {
      await _db.child('users/${user.id}').set({'username': username});
      _goToGame();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(), // dismiss keyboard
        child: Stack(
          clipBehavior: Clip.none,
          fit: StackFit.expand,
          children: [
            // Background
            Image.asset(
              'assets/images/game_bg.png',
              fit: BoxFit.cover,
            ),

            Column(
              children: [
                const SizedBox(height: 60),

                // Logo
                Center(
                  child: Image.asset(
                    'assets/images/doggo_dash.png',
                    height: 210,
width:358         ),
                ),

                const SizedBox(height: 130),

                Center(
                  child: SizedBox(
                    width: 330,
                    height: 100,
                    child: Stack(
                      children: [
                        // Background image
                        Image.asset(
                          'assets/images/username_container.png',
                          width: 330,
                          height: 100,
                          fit: BoxFit.fill,
                        ),

                        // Foreground content
                        Positioned.fill(
                          child: Row(
                            children: [
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 98,top: 15),
                                  child:TextFormField(
                                    controller: _usernameController,
                                    cursorColor: Colors.white,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontFamily: 'LilitaOne',
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      shadows: [
                                        Shadow(
                                          blurRadius: 0,
                                          offset: Offset(1.5, 1.5),
                                          color: Colors.black, // Simulates stroke effect
                                        ),
                                      ],
                                    ),
                                    decoration: const InputDecoration(
                                      hintText: 'NICKNAME',
                                      hintStyle: const TextStyle(
                                        fontSize: 24,
                                        fontFamily: 'LilitaOne',
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        shadows: [
                                          Shadow(
                                            blurRadius: 0,
                                            offset: Offset(1.5, 1.5),
                                            color: Colors.black, // Stroke effect for hint
                                          ),
                                        ],
                                      ),
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                      filled: true,
                                      fillColor: Colors.transparent, // Background is controlled by container
                                    ),
                                  ),

                                ),

                              ),
                              GestureDetector(
                                onTap: _saveUsername,
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 13,right: 2),
                                  child: Image.asset(
                                    'assets/images/confirm_name.png',
                                    height: 56,

                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}