#!/bin/bash

source ./init.sh $1

# do stuff I don't want public in the script
sfdx shane:ai:playground:setup -f ~/GoogleDrive/Emerging\ Tech/eps\ keys/dschultz.mo\@gmail.com/encrypted/einstein_platform.pem -e dschultz.mo@gmail.com -k cBKa1IJYCD+jWsf5Ti1QKQ==
sfdx force:data:record:update -s einsteinplay__Einstein_Settings__c -w "einsteinplay__Einstein_EMail__c=dschultz.mo@gmail.com" -v "einsteinplay__FeatureCode__c=EinsteinRocks"
