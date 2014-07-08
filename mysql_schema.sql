-- change vars, if different
-- dbname = DATABASE NAME
-- dbuser = DB USER ACCOUNT
-- dbpass = DB USER ACCOUNT PASSWORD

CREATE DATABASE dbname;
USE dbname;

-- what's the primary key in oah_adjustment
-- check datetime types

DROP TABLE IF EXISTS oah_adjustment;
CREATE TABLE oah_adjustment (
  ruleid          INT(11) UNSIGNED,
  adjvalue        DECIMAL(4,3),
  affectratetype  CHAR(1),
  minloanamt      INT(9) UNSIGNED,
  maxloanamt      INT(12) UNSIGNED,
  minltv          DECIMAL(6,3) UNSIGNED,
  maxltv          DECIMAL(6,3) UNSIGNED,
  minfico         DECIMAL(6,3) UNSIGNED,
  maxfico         DECIMAL(6,3) UNSIGNED,
  proptype        VARCHAR(15),
  state           VARCHAR(2),
  ruletext        TEXT,
  loadstatus_startdate  DATETIME,
  batchdate       DATETIME
)
  ENGINE = InnoDB
  DEFAULT CHARACTER SET = utf8;

DROP TABLE IF EXISTS oah_product;
CREATE TABLE oah_product (
  institution     VARCHAR(50),
  regionabbrev    VARCHAR(255),
  loanpurpose     VARCHAR(15),
  loantype        VARCHAR(15),
  loanterm        TINYINT UNSIGNED,
  pmttype         VARCHAR(15),
  proddesc        VARCHAR(255),
  intadjterm      TINYINT,
  adjintrvl       TINYINT,
  singlefamily    TINYINT,
  condo           TINYINT,
  coop            TINYINT,
  prodid          INT(6) UNSIGNED,
  lender          VARCHAR(50),
  narrative       VARCHAR(255),
  tbflag          TINYINT,
  vaflag          TINYINT,
  ioflag          TINYINT,
  exceptionid     INT(7),
  planid          INT(6),
  minltv          VARCHAR(15),
  maxltv          VARCHAR(15),
  minfico         SMALLINT UNSIGNED,
  maxfico         SMALLINT UNSIGNED,
  minloanamt      VARCHAR(20),
  maxloanamt      VARCHAR(20),
  minloanamtagency  VARCHAR(50),
  maxloanamtagency  VARCHAR(50),
  armid           INT(11) UNSIGNED,
  ceiling         TINYINT,
  anncap          TINYINT,
  intrateadjcap   TINYINT,
  loancap         TINYINT,
  armindex        VARCHAR(15),
  armmargin       DECIMAL(4,3),
  aivalue         DECIMAL(5,4),
  rateadjmonth    TINYINT
)
  ENGINE = InnoDB
  DEFAULT CHARACTER SET = utf8;

DROP TABLE IF EXISTS oah_rate;
CREATE TABLE oah_rate (
  ratesid         INT(11) UNSIGNED,
  planid          INT(11) UNSIGNED,
  regionid        INT(11) UNSIGNED,
  `lock`          TINYINT UNSIGNED,
  baserate        DECIMAL(5,3),
  totalpoints     DECIMAL(5,3),
  CONSTRAINT oah_rates_pri_key PRIMARY KEY (ratesid)
)
  ENGINE = InnoDB
  DEFAULT CHARACTER SET = utf8;

DROP TABLE IF EXISTS oah_region;
CREATE TABLE oah_region (
  bankid          varchar(255),
  bankname        varchar(255),
  bankshortname   varchar(255),
  lender          varchar(255),
  regionabbrev    varchar(255),
  regionnarrative varchar(255),
  regionid        SMALLINT UNSIGNED,
  stateid         CHAR(2),
  statename       VARCHAR(50),
  offersagency    TINYINT
)
  ENGINE = InnoDB
  DEFAULT CHARACTER SET = utf8;


-- ---------------------------------------

DROP TABLE IF EXISTS oah_state;
CREATE TABLE oah_state (
  state_fips  CHAR(2),
  state_name  VARCHAR(100),
  state_abbr  CHAR(2),
  CONSTRAINT oah_state_pri_key PRIMARY KEY (state_fips)
)
  ENGINE = InnoDB
  DEFAULT CHARACTER SET = utf8;

DROP TABLE IF EXISTS oah_county;
CREATE TABLE oah_county (
  complete_fips CHAR(5),
  county_fips   CHAR(3) NOT NULL,
  county_name   VARCHAR(100) NOT NULL,
  CONSTRAINT oah_county_pri_key PRIMARY KEY (complete_fips)
)
  ENGINE = InnoDB
  DEFAULT CHARACTER SET = utf8;

DROP TABLE IF EXISTS oah_county_limits;
CREATE TABLE oah_county_limits (
  complete_fips CHAR(5),
  fha_limit   NUMERIC(12, 2),
  gse_limit   NUMERIC(12, 2),
  va_limit    NUMERIC(12, 2),
  CONSTRAINT oah_county_limits_pri_key PRIMARY KEY (complete_fips),
  FOREIGN KEY (complete_fips) REFERENCES oah_county(complete_fips)
)
  ENGINE = InnoDB
  DEFAULT CHARACTER SET = utf8;

-- ------------------------------------
-- procedure to populate county_limits
DROP PROCEDURE IF EXISTS county_limit;
DELIMITER $$
CREATE PROCEDURE county_limit(IN state VARCHAR(100), IN abbr CHAR(2), IN statefips CHAR(2), IN county VARCHAR(100),
    IN countyfips CHAR(3), IN fhalimit VARCHAR(100), IN gselimit VARCHAR(100), IN valimit VARCHAR(100))
  BEGIN
    DECLARE CheckExists int;
    SET CheckExists = 0;

    SELECT COUNT(*) INTO CheckExists FROM oah_state WHERE state_fips = statefips;
    IF (CheckExists = 0) THEN
      INSERT INTO oah_state VALUES(statefips, state, abbr);
    END IF;

    SELECT COUNT(*) INTO CheckExists FROM oah_county WHERE complete_fips = CONCAT(statefips, countyfips);
    IF (CheckExists = 0) THEN
      INSERT INTO oah_county VALUES(CONCAT(statefips, countyfips), countyfips, county);
    END IF;

    INSERT INTO oah_county_limits VALUES (CONCAT(statefips, countyfips), fhalimit, gselimit, valimit);
  END $$
DELIMITER ;

-- ------------------------------------
-- change path as needed
LOAD DATA INFILE '/tmp/oah_adjustment.txt' INTO TABLE oah_adjustment FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
  LINES TERMINATED BY '\r\n'
  (ruleid, adjvalue, affectratetype, minloanamt, maxloanamt, minltv, maxltv, minfico, maxfico, proptype, state,
  ruletext, @loadstatus_startdate, @batchdate)
  SET loadstatus_startdate = STR_TO_DATE(@loadstatus_startdate, '%m/%d/%Y %H:%i:%s'),
    batchdate = STR_TO_DATE(@batchdate, '%m/%d/%Y %H:%i:%s');

LOAD DATA INFILE '/tmp/oah_product.txt' INTO TABLE oah_product FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
  LINES TERMINATED BY '\r\n';

LOAD DATA INFILE '/tmp/oah_rate.txt' INTO TABLE oah_rate FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
  LINES TERMINATED BY '\r\n';

LOAD DATA INFILE '/tmp/oah_region.txt' INTO TABLE oah_region FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
  LINES TERMINATED BY '\r\n';

-- ------------------------------------
-- create user, change name and p@ssw0rd
CREATE USER 'dbuser'@'localhost' IDENTIFIED BY 'dbpass';
GRANT ALL ON dbname.* TO dbuser;
FLUSH PRIVILEGES;
