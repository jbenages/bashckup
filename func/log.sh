#!/bin/bash

## Log differents outputs in different levels
# params: $1 = type | $2 = verbose | $3 = logFile | $4 = logDir | $5 = logMail | $6 = logAlert | $7 = output
function logOutput(){

    local -A symbol=( [alert]="!" [info]="i" [done]="+" [nodone]="-" [input]="?" )
    local -A color=( [alert]="31" [info]="34" [done]="32" [nodone]="33" [input]="35" )
    local -A colorHTML=( [alert]="red" [info]="blue" [done]="green" [nodone]="yellow" )

    outputConsole="\e[${color[$1]}m\e[1m[${symbol[$1]}]\e[0m $7"

    outputMail="<b style='color:${colorHTML[$1]}'>[${symbol[$1]}]</b> $7"
 
    outputFile="[${symbol[$1]}] $7"
	
    doPrint $2 "$outputConsole"

    outputToFile $3 "$4" "$outputFile"

    if ( $5 );then
	logMail="$logMail$outputMail<br/>"
    fi
   
    if ( $6 );then
        alertMail="$alertMail$outputMail<br/>"	
    fi
	
}
