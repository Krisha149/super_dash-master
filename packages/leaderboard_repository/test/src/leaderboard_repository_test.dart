// ignore_for_file: prefer_const_constructors, subtype_of_sealed_class

import 'package:authentication_repository/authentication_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leaderboard_repository/leaderboard_repository.dart';
import 'package:mocktail/mocktail.dart';

class _MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

class _MockCollectionReference extends Mock
    implements CollectionReference<Map<String, dynamic>> {}

class _MockQuery extends Mock implements Query<Map<String, dynamic>> {}

class _MockQuerySnapshot extends Mock
    implements QuerySnapshot<Map<String, dynamic>> {}

class _MockQueryDocumentSnapshot extends Mock
    implements QueryDocumentSnapshot<Map<String, dynamic>> {}

class _MockDocumentReference extends Mock
    implements DocumentReference<Map<String, dynamic>> {}

class _MockAuthenticationRepository extends Mock
    implements AuthenticationRepository {}

void main() {
  group('LeaderboardRepository', () {
    late FirebaseFirestore firestore;
    late AuthenticationRepository authenticationRepository;

    setUp(() {
      firestore = _MockFirebaseFirestore();
      authenticationRepository = _MockAuthenticationRepository();
    });

    test('can be instantiated', () {
      expect(
        LeaderboardRepository(firestore, authenticationRepository),
        isNotNull,
      );
    });

    group('fetchTop10Leaderboard', () {
      late LeaderboardRepository leaderboardRepository;
      late CollectionReference<Map<String, dynamic>> collectionReference;
      late Query<Map<String, dynamic>> query;
      late QuerySnapshot<Map<String, dynamic>> querySnapshot;
      late List<QueryDocumentSnapshot<Map<String, dynamic>>>
          queryDocumentSnapshots;

      final top10Scores = [
        2500,
        2200,
        2200,
        2000,
        1800,
        1400,
        1300,
        1000,
        600,
        300,
        100,
      ];

      final top10Leaderboard = top10Scores
          .map(
            (score) => LeaderboardEntryData(
              score: score,
              playerInitials: 'user$score',
            ),
          )
          .toList();

      setUp(() {
        leaderboardRepository =
            LeaderboardRepository(firestore, authenticationRepository);
        collectionReference = _MockCollectionReference();
        query = _MockQuery();
        querySnapshot = _MockQuerySnapshot();
        queryDocumentSnapshots = top10Scores.map((score) {
          final queryDocumentSnapshot = _MockQueryDocumentSnapshot();
          when(() => queryDocumentSnapshot.data()).thenReturn(
            <String, dynamic>{
              'playerInitials': 'user$score',
              'score': score,
            },
          );
          return queryDocumentSnapshot;
        }).toList();

        when(() => firestore.collection('leaderboard'))
            .thenReturn(collectionReference);
        when(() => collectionReference.orderBy('score', descending: true))
            .thenReturn(query);
        when(() => query.limit(10)).thenReturn(query);
        when(() => query.get()).thenAnswer((_) async => querySnapshot);
        when(() => querySnapshot.docs).thenReturn(queryDocumentSnapshots);
      });

      test('returns top 10 entries on success', () async {
        final result = await leaderboardRepository.fetchTop10Leaderboard();
        expect(result, equals(top10Leaderboard));
      });

      test('throws FetchTop10LeaderboardException on Firestore failure', () {
        when(() => firestore.collection('leaderboard')).thenThrow(Exception());
        final repo = LeaderboardRepository(firestore, authenticationRepository);
        expect(
          () => repo.fetchTop10Leaderboard(),
          throwsA(isA<FetchTop10LeaderboardException>()),
        );
      });

      test('throws LeaderboardDeserializationException on bad data', () {
        final badDoc = _MockQueryDocumentSnapshot();
        when(() => badDoc.data()).thenReturn(<String, dynamic>{
          'playerInitials': 'ABC',
          // missing score
        });
        when(() => querySnapshot.docs).thenReturn([badDoc]);

        final repo = LeaderboardRepository(firestore, authenticationRepository);

        expect(
          () => repo.fetchTop10Leaderboard(),
          throwsA(isA<LeaderboardDeserializationException>()),
        );
      });
    });

    group('addLeaderboardEntry', () {
      late LeaderboardRepository leaderboardRepository;
      late CollectionReference<Map<String, dynamic>> collectionReference;
      late DocumentReference<Map<String, dynamic>> documentReference;
      late Query<Map<String, dynamic>> query;
      late QuerySnapshot<Map<String, dynamic>> querySnapshot;
      late List<QueryDocumentSnapshot<Map<String, dynamic>>>
          queryDocumentSnapshots;

      const entryScore = 1500;
      final leaderboardEntry = LeaderboardEntryData(
        score: entryScore,
        playerInitials: 'ABC',
      );
      const entryDocumentId = 'id$entryScore';

      setUp(() {
        leaderboardRepository =
            LeaderboardRepository(firestore, authenticationRepository);

        collectionReference = _MockCollectionReference();
        documentReference = _MockDocumentReference();
        query = _MockQuery();
        querySnapshot = _MockQuerySnapshot();

        final scores = [2500, 2200, entryScore, 1000];
        queryDocumentSnapshots = scores.map((score) {
          final doc = _MockQueryDocumentSnapshot();
          when(() => doc.data()).thenReturn({
            'playerInitials': 'AAA',
            'score': score,
          });
          when(() => doc.id).thenReturn('id$score');
          return doc;
        }).toList();

        when(() => firestore.collection('leaderboard'))
            .thenReturn(collectionReference);
        when(() => collectionReference.add(any()))
            .thenAnswer((_) async => documentReference);
        when(() => collectionReference.orderBy('score', descending: true))
            .thenReturn(query);
        when(() => query.get()).thenAnswer((_) async => querySnapshot);
        when(() => querySnapshot.docs).thenReturn(queryDocumentSnapshots);
        when(() => documentReference.id).thenReturn(entryDocumentId);
      });

      test('adds entry if fewer than 10 scores exist', () async {
        when(() => querySnapshot.docs).thenReturn(queryDocumentSnapshots);
        await leaderboardRepository.addLeaderboardEntry(leaderboardEntry);
        verify(() => collectionReference.add(leaderboardEntry.toJson()))
            .called(1);
      });

      test('throws FetchLeaderboardException if Firestore fails', () {
        when(() => firestore.collection('leaderboard')).thenThrow(Exception());
        expect(
          () => leaderboardRepository.addLeaderboardEntry(leaderboardEntry),
          throwsA(isA<FetchLeaderboardException>()),
        );
      });

      test('throws AddLeaderboardEntryException if add fails', () {
        when(() => collectionReference.add(leaderboardEntry.toJson()))
            .thenThrow(Exception('oops'));
        expect(
          () => leaderboardRepository.addLeaderboardEntry(leaderboardEntry),
          throwsA(isA<AddLeaderboardEntryException>()),
        );
      });

      test('does not save entry if not in top 10', () async {
        final highScores = List.generate(11, (i) => 10000 - (i * 100));
        final docs = highScores.map((score) {
          final doc = _MockQueryDocumentSnapshot();
          when(() => doc.data()).thenReturn({
            'playerInitials': 'AAA',
            'score': score,
          });
          return doc;
        }).toList();
        when(() => querySnapshot.docs).thenReturn(docs);
        await leaderboardRepository.addLeaderboardEntry(leaderboardEntry);
        verifyNever(() => collectionReference.add(any()));
      });

      test('saves if score is higher than 10th place', () async {
        final higherEntry = LeaderboardEntryData(
          score: 15000,
          playerInitials: 'ABC',
        );
        final scores = [
          10000,
          9500,
          9000,
          8500,
          8000,
          7500,
          7000,
          6500,
          6000,
          5500
        ];
        final docs = scores.map((score) {
          final doc = _MockQueryDocumentSnapshot();
          when(() => doc.data()).thenReturn({
            'playerInitials': 'AAA',
            'score': score,
          });
          return doc;
        }).toList();
        when(() => querySnapshot.docs).thenReturn(docs);
        await leaderboardRepository.addLeaderboardEntry(higherEntry);
        verify(() => collectionReference.add(higherEntry.toJson())).called(1);
      });
    });
  });
}
