
local function tableExists(tableName)
    local row = MySQL.single.await([[
        SELECT 1 AS found
        FROM information_schema.TABLES
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = ?
        LIMIT 1
    ]], { tableName })

    return row and row.found == 1
end

local function columnExists(tableName, columnName)
    local row = MySQL.single.await([[
        SELECT 1 AS found
        FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = ?
          AND COLUMN_NAME = ?
        LIMIT 1
    ]], { tableName, columnName })

    return row and row.found == 1
end

local function indexExists(tableName, indexName)
    local row = MySQL.single.await([[
        SELECT 1 AS found
        FROM information_schema.STATISTICS
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = ?
          AND INDEX_NAME = ?
        LIMIT 1
    ]], { tableName, indexName })

    return row and row.found == 1
end

local function ensureColumn(tableName, columnName, ddl)
    if columnExists(tableName, columnName) then return end
    MySQL.query.await(('ALTER TABLE `%s` ADD COLUMN %s'):format(tableName, ddl))
end

local function ensureIndex(tableName, indexName, ddl)
    if indexExists(tableName, indexName) then return end
    MySQL.query.await(('ALTER TABLE `%s` ADD %s'):format(tableName, ddl))
end

function EnsureMechanicPanelSchema()
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `mechanic_orders` (
            `id` INT NOT NULL AUTO_INCREMENT,
            `session_id` VARCHAR(100) NULL,
            `bay_id` VARCHAR(64) NULL,
            `plate` VARCHAR(20) NOT NULL,
            `vehicle_model` VARCHAR(80) NULL,
            `owner_citizenid` VARCHAR(64) NULL,
            `mechanic_citizenid` VARCHAR(64) NULL,
            `shop_label` VARCHAR(100) NOT NULL,
            `items_json` LONGTEXT NULL,
            `approved_state_json` LONGTEXT NULL,
            `original_props_json` LONGTEXT NULL,
            `final_props_json` LONGTEXT NULL,
            `subtotal` INT NOT NULL DEFAULT 0,
            `labor` INT NOT NULL DEFAULT 0,
            `total` INT NOT NULL DEFAULT 0,
            `status` VARCHAR(30) NOT NULL DEFAULT 'pending',
            `paid_from` VARCHAR(20) NULL,
            `bypass_payment` TINYINT(1) NOT NULL DEFAULT 0,
            `metadata` LONGTEXT NULL,
            `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]])

    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `mechanic_service_logs` (
            `id` INT NOT NULL AUTO_INCREMENT,
            `order_id` INT NULL,
            `session_id` VARCHAR(100) NULL,
            `bay_id` VARCHAR(64) NULL,
            `plate` VARCHAR(20) NULL,
            `vehicle_model` VARCHAR(80) NULL,
            `owner_citizenid` VARCHAR(64) NULL,
            `mechanic_citizenid` VARCHAR(64) NULL,
            `shop_label` VARCHAR(100) NULL,
            `action` VARCHAR(50) NOT NULL,
            `status` VARCHAR(30) NULL,
            `value` INT NOT NULL DEFAULT 0,
            `metadata` LONGTEXT NULL,
            `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]])

    ensureColumn('mechanic_orders', 'session_id', '`session_id` VARCHAR(100) NULL AFTER `id`')
    ensureColumn('mechanic_orders', 'bay_id', '`bay_id` VARCHAR(64) NULL AFTER `session_id`')
    ensureColumn('mechanic_orders', 'vehicle_model', '`vehicle_model` VARCHAR(80) NULL AFTER `plate`')
    ensureColumn('mechanic_orders', 'approved_state_json', '`approved_state_json` LONGTEXT NULL AFTER `items_json`')
    ensureColumn('mechanic_orders', 'original_props_json', '`original_props_json` LONGTEXT NULL AFTER `approved_state_json`')
    ensureColumn('mechanic_orders', 'final_props_json', '`final_props_json` LONGTEXT NULL AFTER `original_props_json`')
    ensureColumn('mechanic_orders', 'bypass_payment', '`bypass_payment` TINYINT(1) NOT NULL DEFAULT 0 AFTER `paid_from`')
    ensureColumn('mechanic_orders', 'metadata', '`metadata` LONGTEXT NULL AFTER `bypass_payment`')
    ensureColumn('mechanic_orders', 'updated_at', '`updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP AFTER `created_at`')

    ensureColumn('mechanic_service_logs', 'order_id', '`order_id` INT NULL AFTER `id`')
    ensureColumn('mechanic_service_logs', 'session_id', '`session_id` VARCHAR(100) NULL AFTER `order_id`')
    ensureColumn('mechanic_service_logs', 'bay_id', '`bay_id` VARCHAR(64) NULL AFTER `session_id`')
    ensureColumn('mechanic_service_logs', 'plate', '`plate` VARCHAR(20) NULL AFTER `bay_id`')
    ensureColumn('mechanic_service_logs', 'vehicle_model', '`vehicle_model` VARCHAR(80) NULL AFTER `plate`')
    ensureColumn('mechanic_service_logs', 'shop_label', '`shop_label` VARCHAR(100) NULL AFTER `mechanic_citizenid`')
    ensureColumn('mechanic_service_logs', 'status', '`status` VARCHAR(30) NULL AFTER `action`')

    ensureIndex('mechanic_orders', 'idx_mechanic_orders_plate', 'INDEX `idx_mechanic_orders_plate` (`plate`)')
    ensureIndex('mechanic_orders', 'idx_mechanic_orders_owner', 'INDEX `idx_mechanic_orders_owner` (`owner_citizenid`)')
    ensureIndex('mechanic_orders', 'idx_mechanic_orders_mechanic', 'INDEX `idx_mechanic_orders_mechanic` (`mechanic_citizenid`)')
    ensureIndex('mechanic_orders', 'idx_mechanic_orders_bay', 'INDEX `idx_mechanic_orders_bay` (`bay_id`)')
    ensureIndex('mechanic_orders', 'idx_mechanic_orders_status', 'INDEX `idx_mechanic_orders_status` (`status`)')
    ensureIndex('mechanic_orders', 'idx_mechanic_orders_vehicle_model', 'INDEX `idx_mechanic_orders_vehicle_model` (`vehicle_model`)')

    ensureIndex('mechanic_service_logs', 'idx_mechanic_service_logs_order', 'INDEX `idx_mechanic_service_logs_order` (`order_id`)')
    ensureIndex('mechanic_service_logs', 'idx_mechanic_service_logs_plate', 'INDEX `idx_mechanic_service_logs_plate` (`plate`)')
    ensureIndex('mechanic_service_logs', 'idx_mechanic_service_logs_owner', 'INDEX `idx_mechanic_service_logs_owner` (`owner_citizenid`)')
    ensureIndex('mechanic_service_logs', 'idx_mechanic_service_logs_mechanic', 'INDEX `idx_mechanic_service_logs_mechanic` (`mechanic_citizenid`)')
    ensureIndex('mechanic_service_logs', 'idx_mechanic_service_logs_bay', 'INDEX `idx_mechanic_service_logs_bay` (`bay_id`)')
    ensureIndex('mechanic_service_logs', 'idx_mechanic_service_logs_status', 'INDEX `idx_mechanic_service_logs_status` (`status`)')
end

CreateThread(function()
    Wait(1000)
    EnsureMechanicPanelSchema()
end)
