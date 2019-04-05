#Parametros Azure
SUBSCRIPTIONID="358ee798-6994-472e-afee-6d1b1f0e9ca3"
AZCSUFF=$2
GLOC=$3
AZVMUser=$4
AZVMPass=$5
# Configuración Service Principal Ansible
AZURE_CLIENT_ID=fe53bf17-3b41-477d-9d8a-21d148f7a1fa
AZURE_SECRET=0e923912-9a01-42db-a2f8-57106c109d2e
AZURE_TENANT=ea32c813-6dbd-4e9b-9e64-afda1c9da76f
# Configuración Ansible
INTERNET="true"
RED="true"
VNETANSI="192.168.0.0/16"
VSNETANSI="192.168.4.0/24"
# Conf Red (false)
VSNNAME=$(echo $AZCSUFF | awk '{ print toupper($0) }')VSNETANSI
NGGROUP=$(echo $AZCSUFF | awk '{ print toupper($0) }')RGVNET
VNNAME=$(echo $AZCSUFF | awk '{ print toupper($0) }')VNET
#Ansible Configuration
VMANSISIZE=Standard_A2_v2
VMANSIIMG=CentOS
SOURCEIP="200.236.99.153"
#VM TEST
VMPROCSIZE=Standard_A2_v2