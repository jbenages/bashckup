#!/bin/bash

## Selection the databases 
# params: $1 = server | $2 = user name | $3 = user password | $4 = SGDB type
# return: 1 = Error | 0 = Done
# print: String - databases names to do backup with withe spaces.
function selectionDatabases(){

    local -a currentDatabases=( $(extractDatabases "${servers[$1]}" "$2" "$3" "$4") )
    if [ $? != 0 ];then
        return 1
    fi

    if [ "$4" == "mysql" ]; then

        if [ ! -z ${databasesMysql[$1]} ];then
            echo "${databasesMysql[$1]}"
            return 0
        fi

    elif  [ "$4" == "mongo" ]; then

        if [ ! -z ${databasesMongo[$1]} ];then
            echo "${databasesMongo[$1]}"
            return 0
        fi

    fi

    local -a blacklistDBS=( "${generalBlacklistDBS[$4]}" )

    if [ "$4" == "mysql" ]; then
        blacklistDBS=( "${blacklistDBS[@]}" "${blacklistMysql[$1]}" )
    elif [ "$4" == "mongo" ]; then
        blacklistDBS=( "${blacklistDBS[@]}" "${blacklistMongo[$1]}" )
    fi

    local -a selectedDBS
    stringBlacklistDBS="${blacklistDBS[@]}"
    local j

    for (( j=0; j<${#currentDatabases[@]}; j++ ));do
        inArray "${currentDatabases[$j]}" "$stringBlacklistDBS"
        if [ $? != 0 ];then
            selectedDBS=( "${selectedDBS[@]}" "${currentDatabases[$j]}" )
        fi
    done

    echo "${selectedDBS[@]}"

    return 0
}

## Do backup of System
# params: $1 = server | $2 = SGDB type
# return: 1 = Error | 0 = Done
# print: String - errors | String - progressbar | String - Done
function backupSystem(){

    logOutput "info" "$verbose" "$doLog" "$logDir" "$doLogMail" "$doAlertMail" "Make Backups of system database $2\n"

    checkConnectionServer "${servers[$1]}" "$username"
    if [ $? != 0 ];then
        logOutput "alert" "$verbose" "$doLog" "$logDir" "$doLogMail" "$doAlertMail" "SSH Not connect with user $username in server $1, please configure ssh-key or give right password\n"
        return 1
    fi

    local homeDir=$(getent passwd $username | cut -d: -f6)
	
    if [ ! -d "$homeDir/$1/$2" ];then
        mkdir "$homeDir/$1/$2"
    fi

    local -a databasesToCopy=( $(selectionDatabases "$1" "$username" "${passwordUserDefault[$1]}" "$2" ) )
    if [ $? != 0 ];then
        logOutput "alert" "$verbose" "$doLog" "$logDir" "$doLogMail" "$doAlertMail" "Fail extract current databases of $4 on $1\n"
        return 1
    fi

    if [ "${#databasesToCopy[@]}" == 0 ];then
        logOutput "alert" "$verbose" "$doLog" "$logDir" "$doLogMail" "$doAlertMail" "No databases to copy in system $2 on server $1\n"
        return 1
    fi

    local j
    for (( j=0; j<${#databasesToCopy[@]}; j++ ));do

        local -a tablesToCopy=( $( extractTables "${servers[$1]}" "$username" "${passwordUserDefault[$1]}" "$2" "${databasesToCopy[$j]}" ) )
        logOutput "info" "$verbose" "$doLog" "$logDir" "$doLogMail" "$doAlertMail" "Backup database: ${databasesToCopy[$j]} \n"

        local i
        for (( i=0; i<${#tablesToCopy[@]}; i++ ));do
            
            local folderTableServer="$homeDir/$2/${databasesToCopy[$j]}/${tablesToCopy[$i]}/" 
            mkdir -p "$homeDir/$1/$2/${databasesToCopy[$j]}/${tablesToCopy[$i]}"
            
            createFolder "$folderTableServer" "$username" "${servers[$1]}"
            if [ $? != 0 ];then
                logOutput "alert" "$verbose" "$doLog" "$logDir" "$doLogMail" "$doAlertMail" "Fail create folder table: ${tablesToCopy[$i]} ,database: ${databasesToCopy[$j]} ,server: $1\n"
                continue
            fi

            dumpTable "$2" "${databasesToCopy[$j]}" "${tablesToCopy[$i]}" "$folderTableServer" "$username" "${passwordUserDefault[$1]}" "${servers[$1]}" "${systemCpuLimit[$1]}"
            if [ $? != 0 ];then
                logOutput "alert" "$verbose" "$doLog" "$logDir" "$doLogMail" "$doAlertMail" "Fail dump table: ${tablesToCopy[$i]} ,database: ${databasesToCopy[$j]} ,server: $1\n"
                continue
            fi

            cpulimit -l ${systemCpuLimit[$1]} rdiff-backup "$username"@${servers[$1]}::"$folderTableServer" "$homeDir/$1/$2/${databasesToCopy[$j]}/${tablesToCopy[$i]}" > /dev/null 2>&1
            if [ $? != 0 ];then
                logOutput "alert" "$verbose" "$doLog" "$logDir" "$doLogMail" "$doAlertMail" "Fail rdiff-backup table: ${tablesToCopy[$i]} ,database: ${databasesToCopy[$j]} ,server: $1\n"
                continue
            fi

            ssh "$username"@${servers[$1]} rm -rf "$folderTableServer"
            if [ $? != 0 ];then
                logOutput "alert" "$verbose" "$doLog" "$logDir" "$doLogMail" "$doAlertMail" "Fail rm table: ${tablesToCopy[$i]} ,database: ${databasesToCopy[$j]} ,server: $1\n"
                continue
            fi

            outputNewline=""
            if (( $i + 1 == ${#tablesToCopy[@]} ));then
                outputNewline="\n"
            fi

            logOutput "done" "$verbose" "$doLog" "$logDir" "$doLogMail" "$doAlertMail" "${tablesToCopy[$i]} $outputNewline"

        done
    done

    ssh "$username"@${servers[$1]} rm -rf "$homeDir"/$2/
    if [ $? != 0 ];then
        logOutput "alert" "$verbose" "$doLog" "$logDir" "$doLogMail" "$doAlertMail" "Fail delete folder $homeDir/$2/ in server $1\n"
    fi

    return 0
}

## Do backup of server
# params: $1 = server | $2 = SGDB type
# print: String - Erros
function backupServer(){
    if [ $(whoami) != "$username" ];then
        logOutput "alert" "$verbose" "$doLog" "$logDir" "$doLogMail" "$doAlertMail" "Option backup needs execute with $username user\n"
        return 1
    fi

    logOutput "info" "$verbose" "$doLog" "$logDir" "$doLogMail" "$doAlertMail" "Make Backups of server $1\n"

    if [ "$2" == "all" ];then
        local -a systemDatabases=( ${typesDatabases[@]} )
    else
        local -a systemDatabases=( "$2" )
    fi

    local homeDir=$(getent passwd $username | cut -d: -f6)

    if [ ! -d "$homeDir/$1" ];then
        mkdir "$homeDir/$1"
    fi

    local j
    for (( j=0; j<${#systemDatabases[@]}; j++ ));do
        allowedDatabases="${systemDatabasesServers[$1]}"
        inArray "${systemDatabases[$j]}" "$allowedDatabases"
        if [ $? != 0 ];then
            logOutput "alert" "$verbose" "$doLog" "$logDir" "$doLogMail" "$doAlertMail" "Not allow or Invalid SGDB type ${systemDatabases[$j]} for server $1\n"
        else
            backupSystem "$1" "${systemDatabases[$j]}"
        fi
    done
}
