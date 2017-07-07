#!/bin/bash

## Exists key in array
# params: $1 = key | $2 = array
# return: 1 = exists | 0 = not exists
# print: Integer - position in array.
function keyArray(){

    local arraySearch=( $2 )
    local i
    for (( i=0; i<${#arraySearch[@]}; i++ ));do
        if [ "$1" == "${arraySearch[$i]}" ];then
            printf $i
            return 0
        fi
    done
    return 1

}

## Search if value exists in array
# params: $1 = value | $2 = array
# return: 1 = exists | 0 = not exists 
function inArray(){

    local arraySearch=( $2 )
    local i
   
    for (( i=0; i<${#arraySearch[@]}; i++ ));do
        if [ "$1" == "${arraySearch[$i]}" ];then
            return 0
        fi
    done
    return 1

}
