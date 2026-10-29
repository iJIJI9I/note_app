import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notes_app/main.dart';

void main() {
  testWidgets('shows branded startup screen while Firebase initializes', (
    tester,
  ) async {
    final initialization = Completer<FirebaseApp>();

    await tester.pumpWidget(
      NotesApp(firebaseInitialization: initialization.future),
    );

    expect(find.text('Notes'), findsOneWidget);
    expect(find.text('Preparing your space…'), findsOneWidget);
  });
}
