#!/bin/bash

## Create user in mysql
# params: Prompt= password of root in mysql | $1=server | $2=user to create | $3 = user password to create | $4 = user privileges to create | $5 = Password root
# return: 1 = Cant connect to mysql | 2 = User exists in mysql | 3 = Fail create user | 0 = Done
# print: String - Errors  
function createUserMysql(){

    ssh root@$1 "mysql -u root -p$5 -e \"exit\"" >> /dev/null
    if [ $? != 0 ];then
        return 1
    fi
    ssh root@$1 "mysql -u root -p$5 -e \"SELECT * FROM mysql.user WHERE user = '$2';\" | grep -i '$2'" >> /dev/null
    if [ $? == 0 ];then
        return 2
    fi
    ssh root@$1 "mysql -u root -p$5 -e \"GRANT $4 ON *.* TO '$2'@'localhost' IDENTIFIED BY '$3'; \" " >> /dev/null
    if [ $? != 0 ];then
        return 3
    fi
    return 0
}
