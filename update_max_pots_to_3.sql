-- Обновление максимального количества горшков с 5 на 3
-- Дата: 2025-11-09

-- Обновляем существующие настройки пользователей
UPDATE `greenhouse_settings` SET `max_pots` = 3 WHERE `max_pots` = 5;

-- Проверяем результат
SELECT `login`, `max_pots`, `active_pots` FROM `greenhouse_settings`;
