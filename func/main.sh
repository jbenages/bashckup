#!/bin/bash

## Main function
function main(){

    startTotalTime=`date +%s`
    
    local -A options=( [-i]="install" [install]="install" [-b]="backupServer" [backup]="backupServer" [-v]="version" [version]="version" )
    optionsReceived=( "$@" )
    optionsCompare="${!options[@]}"
    inArray "${optionsReceived[0]}" "$optionsCompare"
    if [ $? != 0 ];then
        logOutput "alert" "$verbose" "$doLog" "$logDir" "$doLogMail" "$doAlertMail" "Invalid option ${optionsReceived[0]}\n"
        return 1
    fi

    if [ "${optionsReceived[0]}" == "-v" -o "${optionsReceived[0]}" == "version" ];then
        logOutput "info" true false "" false false "Bashckup vesion $version\n" 
        return 1
    fi

    serversCompare="${!servers[@]}"
    inArray "${optionsReceived[1]}" "$serversCompare"
    if [ $? != 0 ];then
        logOutput "alert" "$verbose" "$doLog" "$logDir/bashckup.log" "$doLogMail" "$doAlertMail" "Invalid server ${optionsReceived[1]}\n"
        return 1
    fi

    logDir="$logDir/${optionsReceived[1]}.log"

    #logOutput $verbose $doLog "$logDir" $doLogMail $doAlertMail
    logOutput "info" $verbose $doLog "$logDir" false false "$defaultHeader"

    programsCheck=${programsNeedBashckup[@]}
    output=$(checkExistsPrograms "$programsCheck")
    if [ $? != 0 ];then
        logOutput "alert" "$verbose" "$doLog" "$logDir" "$doLogMail" "$doAlertMail" "Program: $output Not exists\n"
        logOutput "done" "$verbose" false "$logDir" false false "Exit\n"
        exit 0
    fi

    if [ "${optionsReceived[2]}" != "all" ];then
        typesdbCompare="${typesDatabases[@]}"
        inArray "${optionsReceived[2]}" "$typesdbCompare"
    	if [ $? != 0 ];then
            logOutput "alert" "$verbose" "$doLog" "$logDir" "$doLogMail" "$doAlertMail" "Invalid database type ${optionsReceived[2]}\n"
       	    return 1
    	fi
    fi

    ${options[${optionsReceived[0]}]} "${optionsReceived[1]}" "${optionsReceived[2]}"
    
    endTotalTime=`date +%s`
    totalTime=$((endTotalTime-startTotalTime))
    timeResult=$(convertSecs $totalTime)

    logOutput "info" "$verbose" "$doLog" "$logDir" "$doLogMail" "$doAlertMail" "Total time Bashckup execution: $timeResult\n"
    output=$(sendMails $2)
    if [ $? != 0 ];then
        logOutput "alert" "$verbose" "$doLog" "$logDir" "$doLogMail" "$doAlertMail" "$output\n"
    fi
    logOutput "done" "$verbose" false "$logDir" false false "Exit\n"

}
