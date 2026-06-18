# swim_app

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

To start in browser:  
flutter run -d edge --web-port=7357

Админ-панель (сборка на Windows, если проект на синхронизируемом диске E:):

```powershell
cd admin_web
.\build_admin.ps1
```

Разработка (после первой сборки):

```powershell
cd C:\dev\swim_admin_web
npm.cmd run dev
```

taskkill /PID 2448 /F
cd "E:\Другие компьютеры\MacBook Pro\AndroidStudioProjects\swim_app"
flutter run -d edge --web-port=7357

Если `npm` ругается на политику выполнения скриптов — используй `npm.cmd`, не `npm`.

Прогресс (в процентах):
(prevTime − currTime) / prevTime × 100.

Улучшение (в секундах):
(prevTime − currTime) / 100.

Эффективность тренировки (в процентах):
progressPercent / workoutsCount.