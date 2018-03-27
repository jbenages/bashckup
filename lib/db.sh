#!/bin/bash

## Dump table in file
# params: $1 = SGDB type | $2 = database name | $3 = table name | $4 = folder to output | $5 = username | $6 = password | $7 = servername | $8 = cpulimit
# return: >1 = Error | 0 = Done
function dumpTable(){
    if [ -z $7 ];then
        local sshRemote=""
    else
        local sshRemote="ssh $5@$7"
    fi
    if [ "$1" == "mysql" ]; then
        $sshRemote "cpulimit -l $8 -- mysqldump --lock-tables=false -u $5 -p'$6' $2 $3  > $4$3.sql"
    elif [ "$1" == "mongo" ]; then
        $sshRemote "cpulimit -l $8 -- mongodump -d $2 -c $3 -o $4/ > /dev/null"
    fi
    return $?
}

## Extract tables name of SGDB
# params: $1 = server | $2 = user name | $3 = user password | $4 = SGDB type | $5 = database name
# return: >1 = Error | 0 = Done 
# print: String | Tables separated with white spaces.

function extractTables(){
    if [ "$4" == "mysql" ]; then
        tablesDatabase=$(ssh $2@$1 "mysql -u $2 -p$3 -e \"show tables from $5\" | awk 'NR!=1{print \$1}'")
    elif  [ "$4" == "mongo" ]; then
        tablesDatabase=$(ssh $2@$1 "echo show collections | mongo $5 | awk 'NR>1{ print \$1}' | sed '1d; \$d'")
    fi
    result=$?
    echo "$tablesDatabase"
    return $result
}

## Extract datbases in SGDB of server
# params: $1 = server | $2 = user name | $3 = user password | $4 = SGDB type
function extractDatabases(){
    if [ "$4" == "mysql" ]; then
        databasesSystem=$(ssh $2@$1 "mysql -u $2 -p'$3' -e \"show databases;\" | awk 'NR!=1{print \$1}'")
    elif  [ "$4" == "mongo" ]; then
        databasesSystem=$(ssh $2@$1 "echo 'show dbs' | mongo | awk 'NR>1{ print \$1}' | sed '1d; \$d'")
    fi
    result=$?
    echo "$databasesSystem"
    return $result
}
