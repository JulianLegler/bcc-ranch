/*
    CREATE TABLE `ranch` (
	`charidentifier` VARCHAR(50) NOT NULL COLLATE 'utf8mb4_general_ci',
	`ranchcoords` LONGTEXT NOT NULL COLLATE 'utf8mb4_general_ci',
	`ranchname` VARCHAR(100) NOT NULL COLLATE 'utf8mb4_general_ci',
	`ranch_radius_limit` VARCHAR(100) NOT NULL COLLATE 'utf8mb4_general_ci',
	`ranchid` INT(11) NOT NULL AUTO_INCREMENT,
	`ranchCondition` INT(10) NOT NULL DEFAULT '0',
	`cows` VARCHAR(50) NOT NULL DEFAULT 'false' COLLATE 'utf8mb4_general_ci',
	`cows_cond` INT(10) NOT NULL DEFAULT '0',
	`pigs` VARCHAR(50) NOT NULL DEFAULT 'false' COLLATE 'utf8mb4_general_ci',
	`pigs_cond` INT(10) NOT NULL DEFAULT '0',
	`chickens` VARCHAR(50) NOT NULL DEFAULT 'false' COLLATE 'utf8mb4_general_ci',
	`chickens_cond` INT(10) NOT NULL DEFAULT '0',
	`goats` VARCHAR(50) NOT NULL DEFAULT 'false' COLLATE 'utf8mb4_general_ci',
	`goats_cond` INT(10) NOT NULL DEFAULT '0',
	`cows_age` INT(10) NULL DEFAULT '0',
	`chickens_age` INT(10) NULL DEFAULT '0',
	`goats_age` INT(10) NULL DEFAULT '0',
	`pigs_age` INT(10) NULL DEFAULT '0',
	`wateranimalcoords` LONGTEXT NOT NULL DEFAULT 'none' COLLATE 'utf8mb4_general_ci',
	`chicken_coop` VARCHAR(50) NULL DEFAULT 'none' COLLATE 'utf8mb4_general_ci',
	`chicken_coop_coords` LONGTEXT NULL DEFAULT 'none' COLLATE 'utf8mb4_general_ci',
	`shovehaycoords` LONGTEXT NULL DEFAULT 'none' COLLATE 'utf8mb4_general_ci',
	`repairtroughcoords` LONGTEXT NULL DEFAULT 'none' COLLATE 'utf8mb4_general_ci',
	`scooppoopcoords` LONGTEXT NULL DEFAULT 'none' COLLATE 'utf8mb4_general_ci',
	`herdlocation` LONGTEXT NULL DEFAULT 'none' COLLATE 'utf8mb4_general_ci',
	`pigcoords` LONGTEXT NULL DEFAULT 'none' COLLATE 'utf8mb4_general_ci',
	`cowcoords` LONGTEXT NULL DEFAULT 'none' COLLATE 'utf8mb4_general_ci',
	`chickencoords` LONGTEXT NULL DEFAULT 'none' COLLATE 'utf8mb4_general_ci',
	`goatcoords` LONGTEXT NULL DEFAULT 'none' COLLATE 'utf8mb4_general_ci',
	`wagonfeedcoords` LONGTEXT NULL DEFAULT 'none' COLLATE 'utf8mb4_general_ci',
	`ledger` INT(10) NULL DEFAULT '0',
	`isherding` INT(10) NULL DEFAULT '0',
	`taxamount` INT(10) NULL DEFAULT '0',
	`job` VARCHAR(50) NULL DEFAULT 'none' COLLATE 'utf8mb4_general_ci',
	`shovelhay_timestamp` TIMESTAMP NOT NULL DEFAULT current_timestamp(),
	`repairtrough_timestamp` TIMESTAMP NOT NULL DEFAULT current_timestamp(),
	`scooppoop_timestamp` TIMESTAMP NOT NULL DEFAULT current_timestamp(),
	`wateranimal_timestamp` TIMESTAMP NOT NULL DEFAULT current_timestamp(),
	`feed_pigs_timestamp` TIMESTAMP NOT NULL DEFAULT current_timestamp(),
	`feed_cows_timestamp` TIMESTAMP NOT NULL DEFAULT current_timestamp(),
	`feed_chickens_timestamp` TIMESTAMP NOT NULL DEFAULT current_timestamp(),
	`feed_goats_timestamp` TIMESTAMP NOT NULL DEFAULT current_timestamp(),
	`herd_pigs_timestamp` TIMESTAMP NOT NULL DEFAULT current_timestamp(),
	`herd_cows_timestamp` TIMESTAMP NOT NULL DEFAULT current_timestamp(),
	`herd_chickens_timestamp` TIMESTAMP NOT NULL DEFAULT current_timestamp(),
	`herd_goats_timestamp` TIMESTAMP NOT NULL DEFAULT current_timestamp(),
	PRIMARY KEY (`ranchid`) USING BTREE,
	UNIQUE INDEX `charidentifier` (`charidentifier`) USING BTREE
)
COLLATE='utf8mb4_general_ci'
ENGINE=InnoDB
AUTO_INCREMENT=6
;
*/


CREATE TABLE IF NOT EXISTS `ranch` (
    `charidentifier` varchar(50) NOT NULL,
    `ranchcoords` LONGTEXT NOT NULL,
    `ranchname` varchar(100) NOT NULL,
    `ranch_radius_limit` varchar(100) NOT NULL,
    `ranchid` int NOT NULL AUTO_INCREMENT,
    `ranchCondition` int(10) NOT NULL DEFAULT 0,
    `cows` varchar(50) NOT NULL DEFAULT 'false',
    `cows_cond` int(10) NOT NULL DEFAULT 0,
    `pigs` varchar(50) NOT NULL DEFAULT 'false',
    `pigs_cond` int(10) NOT NULL DEFAULT 0,
    `chickens` varchar(50) NOT NULL DEFAULT 'false',
    `chickens_cond` int(10) NOT NULL DEFAULT 0,
    `goats` varchar(50) NOT NULL DEFAULT 'false',
    `goats_cond` int(10) NOT NULL DEFAULT 0,
    PRIMARY KEY `ranchid` (`ranchid`),
    UNIQUE KEY `charidentifier` (`charidentifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

ALTER TABLE `ranch` ADD COLUMN IF NOT EXISTS (`cows_age` INT(10) DEFAULT 0);
ALTER TABLE `ranch` ADD COLUMN IF NOT EXISTS (`chickens_age` INT(10) DEFAULT 0);
ALTER TABLE `ranch` ADD COLUMN IF NOT EXISTS (`goats_age` INT(10) DEFAULT 0);
ALTER TABLE `ranch` ADD COLUMN IF NOT EXISTS (`pigs_age` INT(10) DEFAULT 0);

ALTER TABLE `ranch` ADD COLUMN IF NOT EXISTS (`chicken_coop` varchar(50) DEFAULT 'none');
ALTER TABLE `ranch` ADD COLUMN IF NOT EXISTS (`chicken_coop_coords` LONGTEXT DEFAULT 'none');
ALTER TABLE `ranch` ADD COLUMN IF NOT EXISTS (`shovehaycoords` LONGTEXT DEFAULT 'none');
ALTER TABLE `ranch` ADD COLUMN IF NOT EXISTS (`wateranimalcoords` LONGTEXT DEFAULT 'none');
ALTER TABLE `ranch` ADD COLUMN IF NOT EXISTS (`repairtroughcoords` LONGTEXT DEFAULT 'none');
ALTER TABLE `ranch` ADD COLUMN IF NOT EXISTS (`scooppoopcoords` LONGTEXT DEFAULT 'none');
ALTER TABLE `ranch` ADD COLUMN IF NOT EXISTS (`herdlocation` LONGTEXT DEFAULT 'none');
ALTER TABLE `ranch` ADD COLUMN IF NOT EXISTS (`pigcoords` LONGTEXT DEFAULT 'none');
ALTER TABLE `ranch` ADD COLUMN IF NOT EXISTS (`cowcoords` LONGTEXT DEFAULT 'none');
ALTER TABLE `ranch` ADD COLUMN IF NOT EXISTS (`chickencoords` LONGTEXT DEFAULT 'none');
ALTER TABLE `ranch` ADD COLUMN IF NOT EXISTS (`goatcoords` LONGTEXT DEFAULT 'none');
ALTER TABLE `ranch` ADD COLUMN IF NOT EXISTS (`wagonfeedcoords` LONGTEXT DEFAULT 'none');

ALTER TABLE `characters` ADD COLUMN IF NOT EXISTS (`ranchid` INT(10) DEFAULT 0);
ALTER TABLE `ranch` ADD COLUMN IF NOT EXISTS (`ledger` INT(10) DEFAULT 0);
ALTER TABLE `ranch` ADD COLUMN IF NOT EXISTS (`isherding` INT(10) DEFAULT 0);
ALTER TABLE `ranch` ADD COLUMN IF NOT EXISTS (`taxamount` INT(10) DEFAULT 0);
ALTER TABLE `ranch` ADD COLUMN IF NOT EXISTS (`job` varchar(50) DEFAULT 'none');

ALTER TABLE `ranch` ADD COLUMN IF NOT EXISTS (`shovelhay_timestamp` TIMESTAMP DEFAULT current_timestamp());
ALTER TABLE `ranch` ADD COLUMN IF NOT EXISTS (`repairtrough_timestamp` TIMESTAMP DEFAULT current_timestamp());
ALTER TABLE `ranch` ADD COLUMN IF NOT EXISTS (`scooppoop_timestamp` TIMESTAMP DEFAULT current_timestamp());
ALTER TABLE `ranch` ADD COLUMN IF NOT EXISTS (`wateranimal_timestamp` TIMESTAMP DEFAULT current_timestamp());
ALTER TABLE `ranch` ADD COLUMN IF NOT EXISTS (`feed_pigs_timestamp` TIMESTAMP DEFAULT current_timestamp());
ALTER TABLE `ranch` ADD COLUMN IF NOT EXISTS (`feed_cows_timestamp` TIMESTAMP DEFAULT current_timestamp());
ALTER TABLE `ranch` ADD COLUMN IF NOT EXISTS (`feed_chickens_timestamp` TIMESTAMP DEFAULT current_timestamp());
ALTER TABLE `ranch` ADD COLUMN IF NOT EXISTS (`feed_goats_timestamp` TIMESTAMP DEFAULT current_timestamp());
ALTER TABLE `ranch` ADD COLUMN IF NOT EXISTS (`herd_pigs_timestamp` TIMESTAMP DEFAULT current_timestamp());
ALTER TABLE `ranch` ADD COLUMN IF NOT EXISTS (`herd_cows_timestamp` TIMESTAMP DEFAULT current_timestamp());
ALTER TABLE `ranch` ADD COLUMN IF NOT EXISTS (`herd_chickens_timestamp` TIMESTAMP DEFAULT current_timestamp());
ALTER TABLE `ranch` ADD COLUMN IF NOT EXISTS (`herd_goats_timestamp` TIMESTAMP DEFAULT current_timestamp());
