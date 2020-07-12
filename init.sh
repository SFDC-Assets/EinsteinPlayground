#!/bin/bash
if [ "$1" == "" ]; then
    echo "You need a parameter which will be the alias of the scratch org"
    exit 1
fi

sfdx force:org:create -f config/project-scratch-def.json -s -a $1
sfdx force:source:push -u $1
sfdx force:user:permset:assign --permsetname Einstein_Playground -u $1

sfdx force:data:record:update -s User -w "Alias=UUser" -v "UserPreferencesUserDebugModePref=true"