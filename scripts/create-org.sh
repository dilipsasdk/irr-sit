#!/bin/bash

# A script for creating more useful scratch orgs.
# 
# In addition to creating the org and pushing source into it, the script
# also sets up authentication providers and named credentials towards UAT,
# and populates the org with some fake data.
# 
# After running this script you'll still need to authenticate to APIM within
# Salesforce.

scratchDef="config/project-scratch-def.json"

orgAlias="FCS2020Salesforce"
orgDuration="7"

dataPlan="scripts/create-org-mock-data/plan.json"

while getopts "a:d:" opt
do 
  case "${opt}" in
    a) orgAlias=${OPTARG} ;;
    d) orgDuration=${OPTARG} ;;
  esac
done

echo "This script creates a scratch org and prepares it for development."
echo

echo "[1 / 7] Creating Scratch org..."
sf org create scratch --definition-file $scratchDef --alias $orgAlias --duration-days $orgDuration --set-default || exit 1

echo "[2 / 7] Installing packages..."
# Nebula Logger
echo y | sf package install --wait 10 --security-type AdminsOnly --package 04t5Y0000027L98QAE --target-org $orgAlias || exit 1
# Netomi Agent Assist
sf package install --wait 10 --security-type AdminsOnly --package 04tQQ0000000PxhYAE --target-org $orgAlias || exit 1
echo

echo "[3 / 8] Creating auth providers and named credentials..."
# Auth provider requires the admin user's username so it cannot be pushed normally.
# The others require the auth provider before they can be pushed.

if [ ! -d sas-core/main/default/authproviders ]; then
  mkdir sas-core/main/default/authproviders
fi
if [ ! -d sas-core/main/default/namedCredentials ]; then
  mkdir sas-core/main/default/namedCredentials
fi

userName=`sf org list auth | awk -v user="$orgAlias" '$1 == user {print $2}'` # Get admin user username
# Create auth provider with username from above
sed 's/'{userName}'/'"$userName"'/' scripts/create-org-templates/APIM_Auth.authprovider-meta-template.xml > sas-core/main/default/authproviders/APIM_Auth.authprovider-meta.xml

# Copy named credentials
cp scripts/create-org-templates/SAS_APIM_Auth.namedCredential-meta-template.xml sas-core/main/default/namedCredentials/SAS_APIM_Auth.namedCredential-meta.xml
cp scripts/create-org-templates/SAS_APIM_TEDS_FCS.namedCredential-meta-template.xml sas-core/main/default/namedCredentials/SAS_APIM_TEDS_FCS.namedCredential-meta.xml
cp scripts/create-org-templates/CLM_APIM.namedCredential-meta-template.xml sas-core/main/default/namedCredentials/CLM_APIM.namedCredential-meta.xml

cp scripts/create-org-templates/C_GeneralSetting.APIM_TEDS_Subscription_Key.template.xml sas-core/main/default/customMetadata/C_GeneralSetting.APIM_TEDS_Subscription_Key.md-meta.xml
cp scripts/create-org-templates/C_GeneralSetting.APIM_Subscription_Key.template.xml sas-core/main/default/customMetadata/C_GeneralSetting.APIM_Subscription_Key.md-meta.xml
cp scripts/create-org-templates/C_GeneralSetting.CLM_APIM_Subscription_Key.template.xml sas-core/main/default/customMetadata/C_GeneralSetting.CLM_APIM_Subscription_Key.md-meta.xml

cp scripts/create-org-templates/LocalAuthProvider.APIM_Auth.template.xml sas-core/main/default/customMetadata/LocalAuthProvider.APIM_Auth.md-meta.xml

# Sleep to ensure sharing rule calculation from org creation has finished before pushing sources
echo "[4 / 8] Sleeping for 3m to ensure org creation has finished..."
echo "Zzz..."
sleep 180

echo "[5 / 8] Pushing source..."
sf org assign permset --name ContactCenterAdminExternalTelephony --target-org $userName || exit 1
sf project deploy start --target-org $orgAlias || exit 1
echo

echo "[6 / 8] Assigning extra permissions sets to admin..."
sf org assign permset --name SAS_Customer_Claims --target-org $userName || exit 1
echo

echo "[7 / 8] Pushing data..."
cd scripts/create-org-mock-data/
sf sfdmu:run --targetusername $orgAlias --sourceusername csvfile --quiet || exit 1
cd ../../
echo

echo "[8 / 8] Org created successfully. Remember to enter authentication credentials."
echo "Opening the org in your browser..."
sf org open --path lightning/setup/NamedCredential/home --target-org $orgAlias
