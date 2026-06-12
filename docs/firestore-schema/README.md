# Схема Firestore (SwimFlow)

Диаграмма строится из **живой** БД проекта `swim-app-moby` инструментом [firestore-schema-visualizer](https://github.com/analyticalmonk/firestore-schema-visualizer).

## Запуск

```bash
cd tools && npm run reset-seed   # при необходимости свежие данные
../tools/run_schema_visualizer.sh
```

Нужен `npx firebase-tools login` (те же учётные данные, что для сидов).

Результат в этой папке:

- `firestore_schema_*.json` — схема с типами полей
- `firestore_schema_*.puml` — PlantUML (для пояснительной / draw.io)
- `firestore_schema_*.png` — картинка (если установлен `plantuml`: `brew install plantuml`)
- `firestore_schema_*.xmi` — импорт в StarUML (см. ниже)

## StarUML

Прямого формата `.mdj` из PlantUML нет. Цепочка:

1. Сгенерировать XMI из `.puml`:
   ```bash
   plantuml -xmi:star docs/firestore-schema/firestore_schema_*.puml
   ```
   (то же делает `npm run schema`, если установлен `plantuml`)

2. В StarUML: **Extension Manager** → установить **XMI** (Import/Export XMI 2.1).

3. **File → Import → XMI Import (v2.1)** → выбрать `firestore_schema_*.xmi`.

Ограничения: экспорт PlantUML — старый XMI 1.x, классы и атрибуты обычно подхватываются; связи подколлекций (`*--`) могут не появиться на диаграмме — их можно дорисовать вручную. Если импорт падает, в пояснительной достаточно PNG/PDF из `.puml`.

## Готовая диаграмма (как в пояснительной)

| Файл | Назначение |
|------|------------|
| [swimflow_db_diagram.html](./swimflow_db_diagram.html) | Структурная схема: коллекции, поля, типы, **все связи** (открыть в браузере → печать в PDF) |
| [swimflow_db_diagram.puml](./swimflow_db_diagram.puml) | PlantUML: ER-связи между сущностями |
| `swimflow_db_diagram.png` | PNG из `.puml` (если установлен `plantuml`) |

```bash
brew install plantuml   # macOS
plantuml -tpng docs/firestore-schema/swimflow_db_diagram.puml -o docs/firestore-schema
```

## Коллекции приложения

| Уровень | Коллекция |
|---------|-----------|
| корень | `users`, `coach_invites`, `coach_registration_requests`, `catalog_exercises`, `rank_norms` |
| `users/{uid}` | `workouts`, `competition_swims`, `performance_goal` |
| `users/{coachUid}` | `athleteDossiers`, `workout_templates` |

Связи: `users.coachId` → тренер; `workouts.coachId` → тренер; `coach_invites` → привязка пловца; `performance_goal` ↔ `competition_swims` (цели и факт); `catalog_exercises` → шаблоны → `workouts.recordMeta.sets`.

Пустые корневые коллекции (например `coach_invites` без документов) crawl не покажет.
