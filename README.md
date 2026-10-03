# Warrior of Death — Пепел Угасшего Солнца

Souls-like metroidvania на Godot 4.x (GDScript), цель — Android APK.

## Что внутри (Этапы 1–5)
- Этап 1: контроллер Эзры — FSM, прыжки с coyote-time и jump-buffer, перекат с i-frames, стамина, тач-кнопки.
- Этап 2: комбо из 3 ударов, парирование с оглушением, Hitbox/Hurtbox.
- Этап 3: враг Окаменевший (патруль, преследование, стаггер) и босс Брат Алвин (печать Хранителя).
- Этап 4: лут Diablo-стиля — Common/Rare/Cursed/Relic, аффиксы, инвентарь с экипировкой.
- Этап 5: алтарь (сохранение, прокачка Живучесть/Сила/Выносливость, респаун), метка смерти с возвратом Пыли, сейв user://savegame.json, биом Усыпальница Забвения.

## Сборка APK
- Godot-трек: workflow Godot Android Build — экспорт подписанного APK, артефакт WarriorOfDeath-Godot-APK + отправка в Telegram.
- Нативный трек: workflow Build APK (Kotlin/Compose прототип арены).
- Секреты: TELEGRAM_BOT_TOKEN, TELEGRAM_CHAT_ID (или BOT_TOKEN, CHAT_ID).

## Спрайты
Все PNG в godot/assets — оригинальные, CC0. Сторонние паки не включены, аналоги перечислены в godot/assets/CREDITS.md.
