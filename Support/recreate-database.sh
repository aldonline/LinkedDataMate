#!/bin/sh
isql 1119 dba dba exec="shutdown;"
cd "$TM_BUNDLE_SUPPORT/database"
rm *.db *.log *.pxa *.trx *.lck
virtuoso-t