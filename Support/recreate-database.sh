#!/bin/sh
isql 1119 dba dba exec="shutdown;"
cd ./database
rm *.db *.log *.pxa *.trx *.lck
virtuoso-t