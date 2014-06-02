"""Load limits for a (state, county) pairs into MySQL.
  Expects MS Excel file(s) as input.

  !! Will work with data on 1st worksheet in the xls file.

  !! First row is skipped. So if your xls file doesn't have column names in row 1, some data can lost.

  !! EXPECTED ORDER: State,State FIPS,County FIPS,Complete FIPS,County Name,GSE limit,FHA limit,VA limit

  possible args:

    --input_file    - xlsx file to read data from, default combined_limits.xlsx

    --dbname        - db name, default dbname

"""

import os
import getopt
import sys
import xlrd

# from http://www.50states.com/abbreviations.htm
abbr_to_name = {
    'AL': 'Alabama', 'AK': 'Alaska', 'AZ': 'Arizona', 'AR': 'Arkansas', 'CA': 'California', 'CO': 'Colorado',
    'CT': 'Connecticut', 'DE': 'Delaware', 'FL': 'Florida', 'GA': 'Georgia', 'HI': 'Hawaii', 'ID': 'Idaho',
    'IL': 'Illinois', 'IN': 'Indiana', 'IA': 'Iowa', 'KS': 'Kansas', 'KY': 'Kentucky', 'LA': 'Louisiana',
    'ME': 'Maine', 'MD': 'Maryland', 'MA': 'Massachusetts', 'MI': 'Michigan', 'MN': 'Minnesota', 'MS': 'Mississippi',
    'MO': 'Missouri', 'MT': 'Montana', 'NE': 'Nebraska', 'NV': 'Nevada', 'NH': 'New Hampshire', 'NJ': 'New Jersey',
    'NM': 'New Mexico', 'NY': 'New York', 'NC': 'North Carolina', 'ND': 'North Dakota', 'OH': 'Ohio', 'OK': 'Oklahoma',
    'OR': 'Oregon', 'PA': 'Pennsylvania', 'RI': 'Rhode Island', 'SC': 'South Carolina', 'SD': 'South Dakota',
    'TN': 'Tennessee', 'TX': 'Texas', 'UT': 'Utah', 'VT': 'Vermont', 'VA': 'Virginia', 'WA': 'Washington',
    'WV': 'West Virginia', 'WI': 'Wisconsin', 'WY': 'Wyoming', 'AS': 'American Samoa', 'DC': 'District of Columbia',
    'FM': 'Federated States of Micronesia', 'GU': 'Guam', 'MH': 'Marshall Islands', 'MP': 'Northern Mariana Islands',
    'PW': 'Palau', 'PR': 'Puerto Rico', 'VI': 'Virgin Islands', 'AE': 'Armed Forces Africa', 'AA': 'Armed Forces Americas',
    'AE': 'Armed Forces Canada', 'AE': 'Armed Forces Europe', 'AE': 'Armed Forces Middle East', 'AP': 'Armed Forces Pacific',
}


def read_data():
    """Load data from xls file."""
    print "Reading data..."
    try:
        opts, args = getopt.getopt(sys.argv[1:], "", ["input_file=", "dbname="])

        options = {
            'input_file': 'combined_limits.xlsx',
            'dbname': 'dbname'
        }
        for pair in opts:
            keyword = pair[0][2:]
            options[keyword] = pair[1]

        data = {}
        proc_query = 'CALL county_limit("%s", "%s", "%s", "%s", "%s", "%s", "%s", "%s");\n'

        print " ... working with %s " % options['input_file']
        sql_output = open('county_limits.sql', 'w')
        sql_output.write('USE %s;\n' % options['dbname'])
        fha_data = xlrd.open_workbook(options['input_file'])
        worksheet = fha_data.sheets()[0]
        for i in xrange(worksheet.nrows):
            if not i:
                continue
            row = worksheet.row_values(i)
            state, state_fips, county_fips, complete_fips, county, gse, fha, va = row
            sql_output.write(proc_query % (abbr_to_name[state], state, state_fips, county, county_fips, fha, gse, va))
        sql_output.close()

    except getopt.GetoptError as e:
        print "Error: %s " % e
    except IOError as e:
        print "Error: %s " % e
    except xlrd.biffh.XLRDError as e:
        print "Error: %s " % e

read_data()
