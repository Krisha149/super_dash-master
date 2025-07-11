// import 'package:bloc/bloc.dart';
// import 'package:equatable/equatable.dart';
// import 'package:leaderboard_repository/leaderboard_repository.dart';
//
// part 'score_event.dart';
// part 'score_state.dart';
//
// class ScoreBloc extends Bloc<ScoreEvent, ScoreState> {
//   ScoreBloc({
//     required this.score,
//     required LeaderboardRepository leaderboardRepository,
//   })  : _leaderboardRepository = leaderboardRepository,
//         super(const ScoreState()) {
//     on<ScoreSubmitted>(_onScoreSubmitted);
//     on<ScoreInitialsUpdated>(_onScoreInitialsUpdated);
//     on<ScoreInitialsSubmitted>(_onScoreInitialsSubmitted);
//     on<ScoreLeaderboardRequested>(_onScoreLeaderboardRequested);
//   }
//
//   final int score;
//   final LeaderboardRepository _leaderboardRepository;
//
//   final initialsRegex = RegExp('[A-Z]{3}');
//
//   void _onScoreSubmitted(
//     ScoreSubmitted event,
//     Emitter<ScoreState> emit,
//   ) {
//     emit(
//       state.copyWith(
//         status: ScoreStatus.inputInitials,
//       ),
//     );
//   }
//
//   void _onScoreInitialsUpdated(
//     ScoreInitialsUpdated event,
//     Emitter<ScoreState> emit,
//   ) {
//     final initials = [...state.initials];
//     initials[event.index] = event.character;
//     final initialsStatus =
//         (state.initialsStatus == InitialsFormStatus.blacklisted)
//             ? InitialsFormStatus.initial
//             : state.initialsStatus;
//     emit(state.copyWith(initials: initials, initialsStatus: initialsStatus));
//   }
//
//   Future<void> _onScoreInitialsSubmitted(
//     ScoreInitialsSubmitted event,
//     Emitter<ScoreState> emit,
//   ) async {
//     if (!_hasValidPattern()) {
//       emit(state.copyWith(initialsStatus: InitialsFormStatus.invalid));
//     } else if (_isInitialsBlacklisted()) {
//       emit(state.copyWith(initialsStatus: InitialsFormStatus.blacklisted));
//     } else {
//       emit(state.copyWith(initialsStatus: InitialsFormStatus.loading));
//       try {
//         await _leaderboardRepository.addLeaderboardEntry(
//           LeaderboardEntryData(
//             playerInitials: state.initials.join(),
//             score: score,
//           ),
//         );
//
//         emit(state.copyWith(status: ScoreStatus.scoreOverview));
//       } catch (e, s) {
//         addError(e, s);
//         emit(state.copyWith(initialsStatus: InitialsFormStatus.failure));
//       }
//     }
//   }
//
//   bool _hasValidPattern() {
//     final value = state.initials;
//     return value.isNotEmpty && initialsRegex.hasMatch(value.join());
//   }
//
//   bool _isInitialsBlacklisted() {
//     return _blacklist.contains(state.initials.join());
//   }
//
//   void _onScoreLeaderboardRequested(
//     ScoreLeaderboardRequested event,
//     Emitter<ScoreState> emit,
//   ) {
//     emit(
//       state.copyWith(
//         status: ScoreStatus.leaderboard,
//       ),
//     );
//   }
// }
//
// const _blacklist = [
//   'FUK',
//   'FUC',
//   'COK',
//   'DIK',
//   'KKK',
//   'SHT',
//   'CNT',
//   'ASS',
//   'CUM',
//   'FAG',
//   'GAY',
//   'GOD',
//   'JEW',
//   'SEX',
//   'TIT',
//   'WTF',
// ];
// import 'dart:async';
//
// import 'package:authentication_repository/authentication_repository.dart';
// import 'package:bloc/bloc.dart';
// import 'package:equatable/equatable.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'package:leaderboard_repository/leaderboard_repository.dart';
//
// part 'score_event.dart';
// part 'score_state.dart';
//
// class ScoreBloc extends Bloc<ScoreEvent, ScoreState> {
//   ScoreBloc({
//     required this.score,
//     required LeaderboardRepository leaderboardRepository,
//     required AuthenticationRepository authenticationRepository,
//   })  : _leaderboardRepository = leaderboardRepository,
//         _authenticationRepository = authenticationRepository,
//         super(const ScoreState()) {
//     on<ScoreSubmitted>(_onScoreSubmitted);
//     on<ScoreInitialsSubmitted>(_onScoreInitialsSubmitted);
//     on<ScoreLeaderboardRequested>(_onScoreLeaderboardRequested);
//   }
//
//   final int score;
//   final LeaderboardRepository _leaderboardRepository;
//   final AuthenticationRepository _authenticationRepository;
//
//   void _onScoreSubmitted(
//     ScoreSubmitted event,
//     Emitter<ScoreState> emit,
//   ) {
//     // Directly proceed to initials submission since we're using real username.
//     add(ScoreInitialsSubmitted());
//   }
//
//   Future<void> _onScoreInitialsSubmitted(
//     ScoreInitialsSubmitted event,
//     Emitter<ScoreState> emit,
//   ) async {
//     emit(state.copyWith(initialsStatus: InitialsFormStatus.loading));
//     try {
//       final user = _authenticationRepository.currentUser;
//       if (user == null) throw Exception('User not signed in');
//
//       final snapshot = await FirebaseDatabase.instance
//           .ref()
//           .child('users/${user.id}/username')
//           .get();
//
//       final username = snapshot.value as String?;
//       if (username == null || username.trim().isEmpty) {
//         throw Exception('Username not found');
//       }
//
//       await _leaderboardRepository.addLeaderboardEntry(
//         LeaderboardEntryData(
//           playerInitials: username,
//           score: score,
//         ),
//       );
//
//       emit(state.copyWith(status: ScoreStatus.scoreOverview));
//     } catch (e, s) {
//       addError(e, s);
//       emit(state.copyWith(initialsStatus: InitialsFormStatus.failure));
//     }
//   }
//
//   void _onScoreLeaderboardRequested(
//     ScoreLeaderboardRequested event,
//     Emitter<ScoreState> emit,
//   ) {
//     emit(
//       state.copyWith(
//         status: ScoreStatus.leaderboard,
//       ),
//     );
//   }
// }
import 'dart:async';

import 'package:authentication_repository/authentication_repository.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:leaderboard_repository/leaderboard_repository.dart';

part 'score_event.dart';
part 'score_state.dart';

class ScoreBloc extends Bloc<ScoreEvent, ScoreState> {
  ScoreBloc({
    required this.score,
    required LeaderboardRepository leaderboardRepository,
    required AuthenticationRepository authenticationRepository,
  })  : _leaderboardRepository = leaderboardRepository,
        _authenticationRepository = authenticationRepository,
        super(const ScoreState()) {
    on<ScoreSubmitted>(_onScoreSubmitted);
    on<ScoreInitialsSubmitted>(_onScoreInitialsSubmitted);
    on<ScoreLeaderboardRequested>(_onScoreLeaderboardRequested);
  }

  final int score;
  final LeaderboardRepository _leaderboardRepository;
  final AuthenticationRepository _authenticationRepository;

  void _onScoreSubmitted(
    ScoreSubmitted event,
    Emitter<ScoreState> emit,
  ) {
    // Directly proceed to initials submission since we're using real username.
    add(ScoreInitialsSubmitted());
  }

  Future<void> _onScoreInitialsSubmitted(
    ScoreInitialsSubmitted event,
    Emitter<ScoreState> emit,
  ) async {
    emit(state.copyWith(initialsStatus: InitialsFormStatus.loading));
    try {
      final user = _authenticationRepository.currentUser;
      if (user == null) throw Exception('User not signed in');

      final snapshot = await FirebaseDatabase.instance
          .ref()
          .child('users/${user.id}/username')
          .get();

      final username = snapshot.value as String?;
      if (username == null || username.trim().isEmpty) {
        throw Exception('Username not found');
      }

      // await _leaderboardRepository.addLeaderboardEntry(
      //   LeaderboardEntryData(
      //     playerInitials: username,
      //     score: score,
      //   ),
      // );
      await _leaderboardRepository.addOrUpdateLeaderboardScore(
        LeaderboardEntryData(
          playerInitials: username,
          score: score,
        ),
      );

      emit(state.copyWith(status: ScoreStatus.scoreOverview));
    } catch (e, s) {
      addError(e, s);
      emit(state.copyWith(initialsStatus: InitialsFormStatus.failure));
    }
  }

  void _onScoreLeaderboardRequested(
    ScoreLeaderboardRequested event,
    Emitter<ScoreState> emit,
  ) {
    emit(
      state.copyWith(
        status: ScoreStatus.leaderboard,
      ),
    );
  }
}
