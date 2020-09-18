DROP SCHEMA IF EXISTS ###APP_NAME###dbtesting;
CREATE SCHEMA IF NOT EXISTS ###APP_NAME###dbtesting /*!40100 DEFAULT CHARACTER SET
utf8mb4 COLLATE utf8mb4_unicode_ci */;
USE ###APP_NAME###dbtesting;
DROP USER IF EXISTS '###APP_NAME###dbtestingadmin';
CREATE USER IF NOT EXISTS '###APP_NAME###dbtestingadmin'@'%' IDENTIFIED BY '###DB_PASSWD###';
GRANT ALL ON ###APP_NAME###dbtesting.* TO '###APP_NAME###dbtestingadmin'@'%';
FLUSH PRIVILEGES;
