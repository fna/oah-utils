-- change vars, if different
-- dbname = DATABASE NAME
-- dbuser = DB USER ACCOUNT
-- dbpass = DB USER ACCOUNT PASSWORD

CREATE DATABASE dbname;
USE dbname;

DROP TABLE IF EXISTS oah_state;
CREATE TABLE oah_state (
  stateid     SERIAL,
  state_name  VARCHAR(100),
  CONSTRAINT oah_state_pri_key PRIMARY KEY (stateid)
)
  ENGINE = InnoDB
  DEFAULT CHARACTER SET = utf8;

DROP TABLE IF EXISTS oah_county;
CREATE TABLE oah_county (
  countyid    SERIAL,
  county_name VARCHAR(100),
  CONSTRAINT oah_county_pri_key PRIMARY KEY (countyid)
)
  ENGINE = InnoDB
  DEFAULT CHARACTER SET = utf8;

DROP TABLE IF EXISTS oah_county_limits;
CREATE TABLE oah_county_limits (
  limitid     SERIAL,
  stateid     BIGINT(20) UNSIGNED NOT NULL,
  countyid    BIGINT(20) UNSIGNED NOT NULL,
  gse_limit   NUMERIC(12, 2),
  fha_limit   NUMERIC(12, 2),
  CONSTRAINT oah_county_limits_pri_key PRIMARY KEY (limitid),
  FOREIGN KEY (stateid) REFERENCES oah_state(stateid),
  FOREIGN KEY (countyid) REFERENCES oah_county(countyid)
)
  ENGINE = InnoDB
  DEFAULT CHARACTER SET = utf8;

DROP TABLE IF EXISTS oah_limits;
CREATE TABLE oah_limits (
  planid      SERIAL,
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
  proptype    VARCHAR(3),
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
CREATE PROCEDURE county_limit(IN state VARCHAR(100), IN county VARCHAR(100), IN fhalimit VARCHAR(100), IN gselimit VARCHAR(100))
  BEGIN
    DECLARE sid BIGINT(20) UNSIGNED;
    DECLARE cid BIGINT(20) UNSIGNED;
    SELECT stateid INTO sid FROM oah_state WHERE state_name = state;
    IF (sid IS NULL) THEN
      INSERT INTO oah_state (state_name) VALUES (state);
      SET sid = LAST_INSERT_ID();
    END IF;
    SELECT countyid INTO cid FROM oah_county WHERE county_name = county;
    IF (cid IS NULL) THEN
      INSERT INTO oah_county (county_name) VALUES (county);
      SET cid = LAST_INSERT_ID();
    END IF;

    INSERT INTO oah_county_limits (stateid, countyid, fha_limit, gse_limit) VALUES (sid, cid, fhalimit, gselimit);
  END $$
DELIMITER ;

-- ------------------------------------
-- change path as needed
LOAD DATA INFILE 'Limits.csv' INTO TABLE oah_limits;
LOAD DATA INFILE 'Adjustments.csv' INTO TABLE oah_adjustments;
LOAD DATA INFILE 'Rates.csv' INTO TABLE oah_rates;

-- ------------------------------------
-- create user, change name and password
CREATE USER 'dbuser'@'localhost' IDENTIFIED BY 'password';
GRANT ALL ON dbname.* TO dbuser;
FLUSH PRIVILEGES;
