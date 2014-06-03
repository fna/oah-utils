-- change vars, if different
-- dbname = DATABASE NAME
-- dbuser = DB USER ACCOUNT
-- dbpass = DB USER ACCOUNT PASSWORD

CREATE DATABASE dbname;
USE dbname;

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

DROP TABLE IF EXISTS oah_limits;
CREATE TABLE oah_limits (
  planid      BIGINT(20) UNSIGNED,
  minltv      FLOAT UNSIGNED,
  maxltv      FLOAT UNSIGNED,
  minfico     SMALLINT UNSIGNED,
  maxfico     SMALLINT UNSIGNED,
  minloanamt  DOUBLE UNSIGNED,
  maxloanamt  DOUBLE UNSIGNED,
  CONSTRAINT oah_limits_pri_key PRIMARY KEY (planid)
)
  ENGINE = InnoDB
  DEFAULT CHARACTER SET = utf8;
  -- COLLATE = utf8_bin

DROP TABLE IF EXISTS oah_rates;
CREATE TABLE oah_rates (
  rateid      SERIAL,
  institution VARCHAR(250) NOT NULL,
  stateid     CHAR(2) NOT NULL,
  loanpurpose CHAR(5),
  pmttype     VARCHAR(5) NOT NULL,
  loantype    VARCHAR(6),
  loanterm    SMALLINT UNSIGNED,
  intadjterm  FLOAT UNSIGNED,
  `lock`        SMALLINT UNSIGNED,
  baserate    FLOAT,
  totalpoints FLOAT,
  io          BOOLEAN,
  offersagency  BOOLEAN,
  planid      BIGINT(20) UNSIGNED,
  armindex    VARCHAR(5),
  interestrateadjustmentcap FLOAT,
  annualcap   FLOAT UNSIGNED,
  loancap     FLOAT UNSIGNED,
  armmargin   FLOAT UNSIGNED,
  aivalue     FLOAT UNSIGNED,
  CONSTRAINT oah_rates_pri_key PRIMARY KEY (rateid)
)
  ENGINE = InnoDB
  DEFAULT CHARACTER SET = utf8;

DROP TABLE IF EXISTS oah_adjustments;
CREATE TABLE oah_adjustments (
  planid      BIGINT(20) UNSIGNED,
  affectratetype  CHAR(1),
  adjvalue    FLOAT,
  minloanamt  DOUBLE UNSIGNED,
  maxloanamt  DOUBLE UNSIGNED,
  proptype    VARCHAR(25),
  minfico     FLOAT UNSIGNED,
  maxfico     FLOAT UNSIGNED,
  minterm     SMALLINT UNSIGNED,
  maxterm     SMALLINT UNSIGNED,
  minltv      FLOAT UNSIGNED,
  maxltv      FLOAT UNSIGNED,
  mincltv     FLOAT,
  maxcltv     FLOAT,
  minunits    SMALLINT UNSIGNED,
  maxunits    SMALLINT UNSIGNED,
  state       CHAR(2),
  va          VARCHAR(10),
  adjtextpoint  TEXT,
  adjtextrate   TEXT
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
LOAD DATA INFILE '/tmp/Limits.csv' INTO TABLE oah_limits FIELDS TERMINATED BY ',';
LOAD DATA INFILE '/tmp/Adjustments.csv' INTO TABLE oah_adjustments FIELDS TERMINATED BY ',';
LOAD DATA INFILE '/tmp/Rates.csv' INTO TABLE oah_rates FIELDS TERMINATED BY ',' (institution, stateid, loanpurpose,
  pmttype, loantype, loanterm, intadjterm, `lock`, baserate, totalpoints, io, offersagency, planid, armindex,
  interestrateadjustmentcap, annualcap, loancap, armmargin, aivalue);

-- ------------------------------------
-- create user, change name and p@ssw0rd
CREATE USER 'dbuser'@'localhost' IDENTIFIED BY 'dbpass';
GRANT ALL ON dbname.* TO dbuser;
FLUSH PRIVILEGES;
