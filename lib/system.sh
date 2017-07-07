#!/bin/bash

## Create user of system UNix
# params: $1 = username | $2 = home | $3 = servername | $4 = password
# return: 1 = No root | 2 = user exists | 0 = Done
# print: String - password created
function createUser(){

    if [ "$UID" -ne 0 ];then
        return 1
    fi

    if [ -z $3 ];then
        local sshRemote=""
    else
        local sshRemote="ssh root@$3"
    fi

    $sshRemote id -u $1 > /dev/null 2>&1
    if [ $? == 0 ];then
        return 2
    fi

    $sshRemote useradd -d "$2" -m "$1" -s /bin/bash
    
    if [ -z $4 ];then
            password=$(tr -cd '[:alnum:]' < /dev/urandom | fold -w10 | head -n1)
    else
            password="$4"
    fi

    echo $1:$password | $sshRemote chpasswd
    return 0

}

## Create key pair ssh for user in local server
# params: $1 = username
# return: 1 = Error | 0 = Done
function createKeyPair(){

    id -u "$1" > /dev/null 2>&1
    if [ $? != 0 ];then
        return 1
    fi

    local homeDir=$(getent passwd $1 | cut -d: -f6)

    if [[ ! -f "$homeDir/.ssh/id_rsa" ]];then
        su "$1" -c "ssh-keygen -b 2048 -t rsa -f $homeDir/.ssh/id_rsa -q -N \"\""
    fi
    return $?

}

## Add key pair from user in local server to user in remote server
# params: $1 = server | $2 = local username | $3 = server username  
# return: 1 = No pubkey | 2 = No home directory | 3 = Key exists in remote user | 4 = Error in copy key | 0 = Done
# print: String - Done or Error messages
function addKeyPair(){

    local homeDir=$(getent passwd $2 | cut -d: -f6)

    if [[ ! -f "$homeDir/.ssh/id_rsa.pub" ]];then
    	return 1
    fi

    local homeDirRemote=$(getent passwd $2 | cut -d: -f6)
     
    ssh root@$1 ls $homeDirRemote > /dev/null 2>&1
    if [ $? != 0 ];then
    	return 2
    fi

    ssh root@$1 ls $homeDirRemote/.ssh > /dev/null 2>&1
    if [ $? != 0 ];then
        ssh root@$1 "mkdir $homeDirRemote/.ssh && chown $3:$3 -R $homeDirRemote/.ssh" > /dev/null 2>&1
    fi

    key=$( cat $homeDir/.ssh/id_rsa.pub )

    ssh root@$1 "grep '$key' $homeDirRemote/.ssh/authorized_keys" > /dev/null 2>&1
    if [ $? == 0 ];then
        return 3
    fi

    ssh root@$1 "echo $key >> $homeDirRemote/.ssh/authorized_keys && chown $3:$3 -R $homeDirRemote/.ssh/authorized_keys" > /dev/null 2>&1
    if [ $? != 0 ];then
        return 4
    fi
    return 0

}

## Create Folder or structure of folders in local or remote server for user
# params: $1 = name folder | $2 = username | $3 =  servername
# return: 1 = Error | 0 = Done
function createFolder(){

    if [ -z $3 ];then
        local sshRemote=""
    else
        local sshRemote="ssh $2@$3"
    fi

    $sshRemote ls $1 > /dev/null 2>&1
    if [ $? == 0 ];then
        return 0
    fi

    $sshRemote mkdir -p "$1"
    return $?

}

## Check if exists the programs in system
# params: $1 = programs names
# return: 1 = Error | 0 = Done
# print: String - Name program not exist
function checkExistsPrograms(){

    local programs=( $1 )
    local j
    
    for (( j=0; j<${#programs[@]}; j++ ))
    do
        if [ ! $(type -P ${programs[$j]} ) ]; then
            echo "${programs[$j]}"
            return 1
        fi
    done

    return 0
}

## Check if exists connection between servers
# params: $1 = nameserver | $2 = user local and remote
function checkConnectionServer(){
    if [ "$UID" == 0 ];then
        su $2 -c "ssh -o ConnectTimeout=10 -o BatchMode=yes -o StrictHostKeyChecking=no $2@$1 exit > /dev/null 2>&1"
    else
        ssh -o ConnectTimeout=10 -o BatchMode=yes -o StrictHostKeyChecking=no $2@$1 exit > /dev/null 2>&1
    fi
    return $?
}

## Do print of output
# params: $1 = print | $2 = output
function doPrint(){
    if ( $1 );then
        printf "$2"
    fi
}

## Put output in log file
# params: $1 = doCopy | $2 = filePath | $3 = output
function outputToFile(){
    if ( $1 );then
        printf "$3" >> "$2"
    fi
}
