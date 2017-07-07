#!/bin/bash

## Install bashckup in server and clients.
# params: $1 = server | $2 = SGDB type
function install(){

    logOutput "info" "$verbose" false "$logDir" false false "Install bashckup in server $1\n"

    createUser "$username" "$dir"
    funcReturn=$? 
    if [ $funcReturn == 1 ];then
        logOutput "alert" "$verbose" false "$logDir" false false "For add user need root permisions, please run me with root user or sudo\n"
        return 1
    elif [ $funcReturn == 2 ];then
        logOutput "nodone" "$verbose" false "$logDir" false false "User $username exists in local, not create it\n"
    else
        logOutput "done" "$verbose" false "$logDir" false false "Created user $username with random password \n"
    fi

    createKeyPair "$username"
    if [ $? == 1 ];then
        logOutput "alert" "$verbose" false "$logDir" false false "User $username not exists in current server\n"
        return 1
    fi

    serversList=${!servers[@]}
    inArray "$1" "$serversList"
    if [ $? != 0 ]; then
        logOutput "alert" "$verbose" false "$logDir" false false "This server $1 not in Servers list ${servers[@]}\n"
        return 1
    fi

    checkConnectionServer "${servers[$1]}" "root"
    if [ $? != 0 ];then
        logOutput "alert" "$verbose" false "$logDir" false false "We cant access with root account in server $1, configure ssh-key please or give right password\n"
        return 1
    fi

    ssh root@${servers[$1]} "type -P rdiff-backup > /dev/null 2>&1"
    if [ $? != 0 ];then
        ssh root@${servers[$1]} "apt-get update > /dev/null 2>&1 && apt-get -y install rdiff-backup cpulimit > /dev/null 2>&1"
        if [ $? != 0 ];then
                logOutput "alert" "$verbose" false "$logDir" false false "Can't install packages in server $1, please install it manually\n"
                return 1
        fi
        logOutput "done" "$verbose" false "$logDir" false false "Installed necesaries packages rdiff-backups and cpulimit\n"
    fi

    createUser "$username" "$dir" "${servers[$1]}"
    funcReturn=$?
    if [ $funcReturn == 1 ];then
        logOutput "alert" "$verbose" false "$logDir" false false "For add user need root permisions, please run me with root user or sudo\n"
        return 1
    elif [ $funcReturn == 2 ];then
        logOutput "nodone" "$verbose" false "$logDir" false false "User $username exists in server $1, not create it\n"
    else
        logOutput "done" "$verbose" false "$logDir" false false "Created user $username with random password \n"
    fi

    addKeyPair "${servers[$1]}" "$username" "$username"
    funcReturn=$?
    if [ $funcReturn == 1 ];then
        logOutput "alert" "$verbose" false "$logDir" false false "User $usernamei in local not have public key\n"
        return 1
    elif [ $funcReturn == 2 ];then
        logOutput "alert" "$verbose" false "$logDir" false false "No home directory to user $username in server $1\n"
        return 1
    elif [ $funcReturn == 3 ];then
        logOutput "nodone" "$verbose" false "$logDir" false false "Key of local user $username exist in remote server $1\n"
    elif [ $funcReturn == 4 ];then
        logOutput "alert" "$verbose" false "$logDir" false false "Error in copy key from $username to remote server $1\n"
        return 1 
    else
        logOutput "done" "$verbose" false "$logDir" false false "Add public key of user $username to remote server $1\n"
    fi

    checkConnectionServer "${servers[$1]}" "$username"
    if [ $? != 0 ];then
        logOutput "alert" "$verbose" false "$logDir" false false "We cant access with user $username in server $1, please configure ssh-key or give right password\n"
        return 1
    fi

    logOutput "input" true false "$logDir" false false "Type the password for root user in mysql in server $1\n"
    read -s -p "password:" passwordMysql
    if [[ -z $passwordMysql ]];then
        logOutput "alert" "$verbose" false "$logDir" false false "Need password of mysql user root in server $1 to config user $username\n"
        return 1
    fi

    createUserMysql "${servers[$1]}" "$username" "${passwordUserDefault[$1]}" "SELECT,SHOW VIEW" "$passwordMysql"
    funcReturn=$?
    if [ $funcReturn == 1 ];then
        logOutput "alert" "$verbose" false "$logDir" false false "Cant connect to mysql of server $1 with user root, wrong password?\n"
        return 1
    elif [ $funcReturn == 2 ];then
        logOutput "nodone" "$verbose" false "$logDir" false false "User $2 exists in mysql of server $1\n"
    elif [ $funcReturn == 3 ];then
        logOutput "alert" "$verbose" false "$logDir" false false "Error create $username on mysql to remote server $1\n"
        return 1
    else
        logOutput "done" "$verbose" false "$logDir" false false "Created user:$2 in mysql of server $1 with privileges $4\n"
    fi

    if [ "$2" == "all" ];then
        local -a foldersDBS=( "${typesDatabases[@]}" )
    else
        local -a foldersDBS=( "$2" )
    fi

    local i
    for (( i=0; i<${#foldersDBS[@]}; i++ ));do
        su "$username" -c" ssh -o StrictHostKeyChecking=no $username@${servers[$1]} mkdir ${foldersDBS[$i]} > /dev/null 2>&1"
        if [ $? == 0 ];then
            logOutput "done" "$verbose" false "$logDir" false false "Created folder ${foldersDBS[$i]}\n"
        else
            su "$username" -c " ssh -o StrictHostKeyChecking=no $username@${servers[$1]} ls ${foldersDBS[$i]} > /dev/null 2>&1 "
            if [ $? == 0 ];then
                logOutput "nodone" "$verbose" false "$logDir" false false "Exists folder ${foldersDBS[$i]}\n"
            else
                logOutput "alert" "$verbose" false "$logDir" false false "Fail create folder ${foldersDBS[$i]}, please check permissions and similar errors\n"
                return 1
            fi
        fi
    done
    logOutput "done" "$verbose" false "$logDir" false false "Correct Install to server $1\n"
    return 0
}
