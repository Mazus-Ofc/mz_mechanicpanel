CREATE TABLE IF NOT EXISTS mechanic_orders (
  id INT NOT NULL AUTO_INCREMENT,
  plate VARCHAR(20) NOT NULL,
  owner_citizenid VARCHAR(64) NULL,
  mechanic_citizenid VARCHAR(64) NULL,
  shop_label VARCHAR(100) NOT NULL,
  items_json LONGTEXT NULL,
  subtotal INT NOT NULL DEFAULT 0,
  labor INT NOT NULL DEFAULT 0,
  total INT NOT NULL DEFAULT 0,
  status VARCHAR(30) NOT NULL DEFAULT 'paid',
  paid_from VARCHAR(20) NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_mechanic_orders_plate (plate),
  KEY idx_mechanic_orders_owner (owner_citizenid),
  KEY idx_mechanic_orders_mechanic (mechanic_citizenid)
);

CREATE TABLE IF NOT EXISTS mechanic_service_logs (
  id INT NOT NULL AUTO_INCREMENT,
  plate VARCHAR(20) NOT NULL,
  owner_citizenid VARCHAR(64) NULL,
  mechanic_citizenid VARCHAR(64) NULL,
  action VARCHAR(50) NOT NULL,
  value INT NOT NULL DEFAULT 0,
  metadata LONGTEXT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_mechanic_service_logs_plate (plate),
  KEY idx_mechanic_service_logs_owner (owner_citizenid),
  KEY idx_mechanic_service_logs_mechanic (mechanic_citizenid)
);
