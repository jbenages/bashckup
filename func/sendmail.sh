#!/bin/bash

## Send mails of logs and/or alerts to emails accounts
# params: $1 = nameserver
# print: String - Emails that fail send 
function sendMails(){
    local fail=0

    if ( $doLogMail );then
        local i
        for (( i=0; i<${#mails[@]}; i++ ));do
            subject="Bashckups Log - $1 - "$(date +"%Y-%m-%d %H:%M:%S")
            echo -e "<html><header></header><body>"$logMail"</body></html>" | mail  -a 'Content-Type: text/html' -s "$subject" ${mails[$i]} 2>/dev/null
            if [ $? -ne 0 ]; then
                printf "${mails[$i]}"
                fail=1
            fi
        done
    fi
    if ( $doAlertMail );then
        if [[ ! -z "$alertMail" ]]; then
            local i
            for (( i=0; i<${#mails[@]}; i++ ));do
                subject="Bashckups Alert! - $1 - "$(date +"%Y-%m-%d %H:%M:%S")
                echo -e "<html><header></header><body>"$alertMail"</body></html>" | mail  -a 'Content-Type: text/html' -s "$subject" ${mails[$i]} 2>/dev/null
                if [ $? -ne 0 ]; then
                    printf "${mails[$i]}"
                    fail=1
                fi
            done
        fi
    fi
    return $fail
}
