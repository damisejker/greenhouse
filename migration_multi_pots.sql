-- Миграция для добавления поддержки множественных горшков в оранжерее
-- Дата создания: 2025-11-09

-- Шаг 1: Добавляем поле pot_id в таблицу oranjerie
-- Это поле будет идентифицировать каждый горшок пользователя
ALTER TABLE `oranjerie`
ADD COLUMN `pot_id` INT NOT NULL DEFAULT 1 AFTER `login`,
ADD INDEX `idx_login_pot` (`login`, `pot_id`);

-- Шаг 2: Обновляем существующие записи - присваиваем pot_id = 1 всем существующим растениям
UPDATE `oranjerie` SET `pot_id` = 1 WHERE `pot_id` = 0 OR `pot_id` IS NULL;

-- Шаг 3: Создаем таблицу для управления горшками пользователя
CREATE TABLE IF NOT EXISTS `user_pots` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `login` VARCHAR(255) NOT NULL,
  `pot_id` INT NOT NULL,
  `pot_left` VARCHAR(10) DEFAULT '50%',
  `pot_top` VARCHAR(10) DEFAULT '80%',
  `is_active` TINYINT(1) DEFAULT 1,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY `unique_user_pot` (`login`, `pot_id`),
  INDEX `idx_login` (`login`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- Шаг 4: Мигрируем существующие позиции горшков из pot_positions в user_pots
INSERT INTO `user_pots` (`login`, `pot_id`, `pot_left`, `pot_top`)
SELECT `username`, 1, `pot_left`, `pot_top`
FROM `pot_positions`
ON DUPLICATE KEY UPDATE
  `pot_left` = VALUES(`pot_left`),
  `pot_top` = VALUES(`pot_top`);

-- Шаг 5: Обновляем таблицу pot_positions - добавляем pot_id
-- Сначала проверяем, существует ли уже колонка pot_id
SET @column_exists = (
  SELECT COUNT(*)
  FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'pot_positions'
    AND COLUMN_NAME = 'pot_id'
);

-- Добавляем колонку только если её нет
SET @sql = IF(@column_exists = 0,
  'ALTER TABLE `pot_positions` ADD COLUMN `pot_id` INT NOT NULL DEFAULT 1 AFTER `username`',
  'SELECT "Column pot_id already exists" AS message'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Обновляем уникальный ключ в pot_positions для поддержки множественных горшков
ALTER TABLE `pot_positions`
DROP INDEX IF EXISTS `username`,
ADD UNIQUE KEY `unique_user_pot_position` (`username`, `pot_id`);

-- Шаг 6: Создаем таблицу настроек оранжереи для каждого пользователя
CREATE TABLE IF NOT EXISTS `greenhouse_settings` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `login` VARCHAR(255) NOT NULL UNIQUE,
  `max_pots` INT NOT NULL DEFAULT 5,
  `active_pots` INT NOT NULL DEFAULT 1,
  `last_updated` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX `idx_login` (`login`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- Шаг 7: Инициализируем настройки для всех существующих пользователей
INSERT INTO `greenhouse_settings` (`login`, `max_pots`, `active_pots`)
SELECT DISTINCT `login`, 5, 1
FROM `oranjerie`
ON DUPLICATE KEY UPDATE `active_pots` = 1;

-- Шаг 8: Обновляем описание таблицы oranjerie
-- Теперь уникальность определяется комбинацией login + pot_id
-- Убираем старый индекс если существует и создаем новый
ALTER TABLE `oranjerie`
DROP INDEX IF EXISTS `idx_login`,
ADD INDEX `idx_login_pot_status` (`login`, `pot_id`, `plantstatus`);

-- Конец миграции
-- Теперь система поддерживает до 5 горшков на пользователя (по умолчанию)
-- Каждый горшок имеет свою позицию и может содержать свое растение
