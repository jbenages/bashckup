#!/bin/bash

## Usage
# ./install.sh

source ./conf/system.cfg

. lib/system.sh
. func/log.sh

declare doAction="install"

if [ "$1" == "-u" ];then
    doAction="uninstall"
fi

logOutput "info" true false "" false false "$doAction Bashckup $version\n"

output=$(checkExistsPrograms "bashckup")
if [ $? == 1 ];then
    if [ "$doAction" == "uninstall" ];then
        logOutput "alert" true false "" false false "Program not exists, cant uninstall it\n"
        exit 0
    fi
else
    if [ "$1" != "-f" ];then
        if [ "$doAction" == "install" ];then
            logOutput "alert" true false "" false false "Program exists, cant install it\n"
            exit 0
        fi
    fi
fi

funcOutput=$(createUser "$username" "$dir")
funcReturn=$?
if [ $funcReturn == 1 ];then
    logOutput "alert" true false "" false false "For add user need root permisions, please run me with root user or sudo\n"
    return 1
elif [ $funcReturn == 2 ];then
    logOutput "nodone" true false "" false false "User $username exists in local, dont create us\n"
else
    logOutput "done" true false "" false false "Created user $username with random password \n"
fi

if [ "$doAction" == "install" ];then
    cp -R . /opt/bashckup/
    chown root:root -R /opt/bashckup/
    mkdir /var/log/bashckup/ 2>/dev/null
    mkdir /etc/bashckup/ 2>/dev/null
    chown $username:$username /var/log/bashckup/ -R 
    cp -n conf/example.bashckup.cfg /etc/bashckup/bashckup.cfg
    chown root:root -R /etc/bashckup
    ln -s /opt/bashckup/bin/bashckup /usr/local/bin/bashckup 2>/dev/null
    logOutput "done" true false "" false false "Installation done\n"
fi

if [ "$doAction" == "uninstall" ];then
    rm -R /opt/bashckup
    rm /usr/local/bin/bashckup
    logOutput "done" true false "" false false "Uninstall done, the folders /var/log/bashckup,/var/lib/bashckup and /etc/bashckup/ aren't empty, do it yourself if is required\n" 
fi

