# Notes App

Кросплатформний застосунок особистих нотаток на Flutter і Dart. Firebase
Authentication відповідає за вхід і реєстрацію, Cloud Firestore — за зберігання
даних користувачів.

## Можливості

- реєстрація, вхід і вихід через email та пароль;
- створення, пошук, редагування й видалення нотаток;
- окрема колекція нотаток для кожного користувача;
- підтвердження перед видаленням нотатки та виходом з акаунта.

## Структура проєкту

```text
lib/
├── main.dart
├── firebase_options.dart
└── features/
    ├── auth/
    │   ├── services/auth_service.dart
    │   └── presentation/screens/auth_screen.dart
    └── notes/
        ├── models/note_model.dart
        ├── repositories/notes_repository.dart
        └── presentation/screens/
            ├── notes_list_screen.dart
            └── note_editor_screen.dart

test/
├── widget_test.dart
└── firestore.rules.test.mjs

firestore.rules
firebase.json
pubspec.yaml
package.json
```

Код організований за функціями (**feature-first**). Екрани відповідають за
інтерфейс, `AuthService` — за виклики Firebase Authentication, модель `Note` —
за структуру нотатки, а `NotesRepository` — за операції Firestore.

## Як працює застосунок

1. `main.dart` ініціалізує Firebase і показує екран запуску.
2. `AuthGate` слухає стан Firebase Authentication та відкриває екран входу або
   список нотаток.
3. Після входу Firebase надає користувачу `uid`.
4. `NotesRepository` читає та змінює нотатки за шляхом
   `users/{uid}/notes/{noteId}`.
5. Firestore Rules на сервері перевіряють, що запит виконує власник даних.

## Безпека даних

Застосунок використовує Firebase SDK і не має власного API-сервера. Firestore
є NoSQL-базою даних, тому SQL injection до запитів застосунку не стосується.

Правила в `firestore.rules` дозволяють доступ лише автентифікованому власнику
нотаток. Також вони перевіряють поля, типи та довжину заголовка і тексту.
Перевірка у Flutter-інтерфейсі зручна для користувача, але саме правила
Firestore є серверною межею доступу.


## Налаштування та запуск

1. У Firebase Console увімкніть провайдер **Email/Password** і створіть
   Cloud Firestore.
2. Налаштуйте Firebase для потрібної платформи та за потреби згенеруйте
   `lib/firebase_options.dart` через FlutterFire CLI.
3. Отримайте залежності й запустіть застосунок:

```shell
flutter pub get
flutter run
```

## Перевірки

```shell
flutter analyze
flutter test
```

Тести правил Firestore запускаються через Firebase Emulator. Потрібні Node.js,
Firebase CLI та JDK 21 або новіший:

```shell
npm ci
npm run test:rules
```

Тести перевіряють доступ власника, відмову анонімному та іншому користувачеві,
а також відхилення некоректних полів, завеликих значень і підроблених часових
міток. Вони виконуються локально й не змінюють production-базу.
