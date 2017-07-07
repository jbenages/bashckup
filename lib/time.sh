#!/bin/bash

## Print secs to hour minuts and seconds
# params: $1 = secs
# print: String - With converions to h: m: s: 
function convertSecs(){
    h=$(($1/3600))
    m=$((($1/60)%60))
    s=$(($1%60))
    printf "h:$h m:$m s:$s"
}
