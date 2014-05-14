"""Load limits for a (state, county) pairs into PostgreSQL.
  Expects MS Excel file(s) as input.

  !! Will work with data on 1st worksheet in the xls file.

  !! First row is skipped. So if your xls file doesn't have column names in row 1, some data can lost.

  possible args:

  --fha         - path to xls file that holds FHA limits, default fha-limits.xlsx

  --gse         - path to xls file that hold GSE limits, default gse-limits.xlsx

  --state_row   - column number that stores state value, default 12

  --county_row  - column number that stores county value, default 13

  --limit_row   - column number that stores limit value, default 6
"""

import psycopg2
import os
import getopt
import sys
import xlrd


def recreate_tables():
    """Drop state, county and county_limits tables, and create them anew."""
    print "Re-creating tables ...."
    cur = conn.cursor()
    cur.execute("DROP TABLE IF EXISTS county_limits")
    cur.execute("DROP TABLE IF EXISTS state")
    cur.execute("DROP TABLE IF EXISTS county")

    query = """
        CREATE TABLE state(
            state_id SERIAL PRIMARY KEY,
            state_name VARCHAR(100) NOT NULL
        )
    """
    cur.execute(query)

    query = """
        CREATE TABLE county(
            county_id SERIAL PRIMARY KEY,
            county_name VARCHAR(100) NOT NULL
        )
    """
    cur.execute(query)

    query = """
        CREATE TABLE county_limits(
            limit_id SERIAL PRIMARY KEY,
            state_id INTEGER REFERENCES state(state_id) NOT NULL,
            county_id INTEGER REFERENCES county(county_id) NOT NULL,
            gse_limit NUMERIC(12, 2) NOT NULL,
            fha_limit NUMERIC(12, 2) NOT NULL
        )
    """
    cur.execute(query)


def read_data():
    """Load data from xls file."""
    print "Reading data..."
    try:
        opts, args = getopt.getopt(sys.argv[1:], "", ["gse=", "fha=", "state_row=", "county_row=", "limit_row="])

        options = {
            'fha': 'fha-limits.xlsx',
            'gse': 'gse-limits.xlsx',
            'state_row': 12,
            'county_row': 13,
            'limit_row': 6
        }
        for pair in opts:
            keyword = pair[0][2:]
            options[keyword] = pair[1]

        data = {}
        states = {}
        counties = {}
        cur = conn.cursor()
        state_query = "INSERT INTO state (state_name) VALUES (%s) RETURNING state_id"
        county_query = "INSERT INTO county (county_name) VALUES (%s) RETURNING county_id"
        limit_query = "INSERT INTO county_limits (state_id, county_id, gse_limit, fha_limit) VALUES (%s, %s, %s, %s)"

        print "  working with %s..." % options['fha']
        fha_data = xlrd.open_workbook(options['fha'])
        worksheet = fha_data.sheets()[0]
        for i in xrange(worksheet.nrows):
            if not i:
                continue
            row = worksheet.row_values(i)
            state = row[options['state_row']]
            county = row[options['county_row']]
            if state not in states:
                cur.execute(state_query, (state,))
                the_id = cur.fetchone()
                states[state] = the_id
            if county not in counties:
                cur.execute(county_query, (county,))
                the_id = cur.fetchone()
                counties[county] = the_id
            data["%s|%s" % (state, county)] = [states[state], counties[county], -1, row[options['limit_row']]]

        print "  working with %s..." % options['gse']
        gse_data = xlrd.open_workbook(options['gse'])
        worksheet = gse_data.sheets()[0]
        for i in xrange(worksheet.nrows):
            if not i:
                continue
            row = worksheet.row_values(i)
            state = row[options['state_row']]
            county = row[options['county_row']]
            if state not in states:
                cur.execute(state_query, (state,))
                the_id = cur.fetchone()
                states[state] = the_id
            if county not in counties:
                cur.execute(county_query, (county,))
                the_id = cur.fetchone()
                counties[county] = the_id
            data["%s|%s" % (state, county)][2] = row[options['limit_row']]

        print "  inserting data..."
        for i in data:
            cur.execute(limit_query, (data[i][0], data[i][1], data[i][2], data[i][3]))

    except getopt.GetoptError as e:
        print "Error: %s " % e
    except IOError as e:
        print "Error: %s " % e
    except xlrd.biffh.XLRDError as e:
        print "Error: %s " % e

dbname = os.environ.get('OAH_DB_NAME', 'pg_test')
dbhost = os.environ.get('OAH_DB_HOST', 'localhost')
conn = psycopg2.connect('dbname=%s host=%s' % (dbname, dbhost))
conn.set_isolation_level(0)

recreate_tables()
read_data()
