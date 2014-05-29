"""Load limits for a (state, county) pairs into MySQL.
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

import os
import getopt
import sys
import xlrd


def read_data():
    """Load data from xls file."""
    print "Reading data..."
    try:
        opts, args = getopt.getopt(sys.argv[1:], "", ["gse=", "fha=", "state_row=", "county_row=", "limit_row=", "dhname="])

        options = {
            'fha': 'fha-limits.xlsx',
            'gse': 'gse-limits.xlsx',
            'state_row': 12,
            'county_row': 13,
            'limit_row': 6,
            'dbname': 'dbname'
        }
        for pair in opts:
            keyword = pair[0][2:]
            options[keyword] = pair[1]

        data = {}
        proc_query = 'CALL county_limit("%s", "%s", "%s", "%s");\n'

        print "  working with %s..." % options['fha']
        fha_data = xlrd.open_workbook(options['fha'])
        worksheet = fha_data.sheets()[0]
        for i in xrange(worksheet.nrows):
            if not i:
                continue
            row = worksheet.row_values(i)
            state = row[options['state_row']]
            county = row[options['county_row']]
            data["%s|%s" % (state, county)] = [state, county, row[options['limit_row']], -1]

        print "  working with %s..." % options['gse']
        gse_data = xlrd.open_workbook(options['gse'])
        worksheet = gse_data.sheets()[0]
        for i in xrange(worksheet.nrows):
            if not i:
                continue
            row = worksheet.row_values(i)
            state = row[options['state_row']]
            county = row[options['county_row']]
            data["%s|%s" % (state, county)][3] = row[options['limit_row']]

        print "  inserting data..."
        sql_output = open('county_limits.sql', 'w')
        sql_output.write('USE %s;\n' % options['dbname'])
        for i in data:
            sql_output.write(proc_query % (data[i][0], data[i][1], data[i][2], data[i][3]))
        sql_output.close()

    except getopt.GetoptError as e:
        print "Error: %s " % e
    except IOError as e:
        print "Error: %s " % e
    except xlrd.biffh.XLRDError as e:
        print "Error: %s " % e

read_data()
