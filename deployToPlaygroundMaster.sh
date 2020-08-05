#!/bin/bash
rm -rf mdapioutput

# Convert to metadata format to deploy to non-scratch org
sfdx force:source:convert -d mdapioutput/

# Deploy to org
sfdx force:mdapi:deploy -d mdapioutput/ -u PlaygroundMaster -w 100