source ./include/functions.sh
source ./conf/setup.sh

#AVNAME=$(echo $AZCSUFF | awk '{ print toupper($0) }')AVSANSI
AVNAME=""

f_title "Ansible"
f_title "Networking"
case $RED in
true)
    NGGROUP="$(echo $AZCSUFF | awk '{ print toupper($0) }')RGVNET"
    VNNAME=$(C_Net)
    VSNAME=$(C_SNet "$NGGROUP" "$VNNAME" "$(echo $AZCSUFF | awk '{ print toupper($0) }')VSNETANSI" "$VSNETANSI")
    VNNAMES=$(az network vnet show -n $VNNAME -g $NGGROUP -o tsv --query 'addressSpace.addressPrefixes')
    ;;
false)
    VSNAME=$VSNNAME
    NGGROUP=$NGGROUP
    VNNAME=$VNNAME
    VNNAMES=$(az network vnet show -n $VNNAME -g $NGGROUP -o tsv --query 'addressSpace.addressPrefixes')
    ;;

*) ;;
esac
f_title "Grupo de Recursos"
CHECK=$(az group show -n $(echo $AZCSUFF)RGANSI)
if [ "$?" -eq 0 ]; then
    echo "Grupo Encontrado"
    VGROUP=$(echo $AZCSUFF)RGANSI
else
    VGROUP=$(A_Group $(echo $AZCSUFF | awk '{ print toupper($0) }')RGANSI $GLOC)
fi

if [ "$AVNAME" == "" ]; then
    echo "Saltando Availability-Set"
else
    f_title "Availability-Set"
    CHECK=$(az vm availability-set show -g $VGROUP -n $AVNAME)
    if [ "$?" -eq 0 ]; then
        echo "$AVNAME ya Existe"
    else
        az vm availability-set create -g "$VGROUP" -n $AVNAME
        f_news "AV Creado" "AV No Creado"
    fi
fi

ANSIMNAME="$(echo $AZCSUFF | awk '{ print toupper($0) }')VMANSIM"

f_title "Nodo Maestro Ansible"

AZIPVMB=$(A_VM "VMANSIM" "$VMANSISIZE" "$VMANSIIMG" "$AZVMUser" "$AZVMPass" "$LPIP" "$VGROUP" "$AVNAME" "$VSNAME")
sleep 30
if sshpass -p $AZVMPass ssh -o ConnectTimeout=3 $AZVMUser@$AZIPVMB "hostname"; then
    sshpass -p $AZVMPass ssh -o ConnectTimeout=3 $AZVMUser@$AZIPVMB "echo '$AZVMPass' |sudo -S yum -y update"
    sshpass -p $AZVMPass ssh -o ConnectTimeout=3 $AZVMUser@$AZIPVMB "echo '$AZVMPass' |sudo -S yum check-update; sudo yum install -y sshpass gcc libffi-devel python-devel openssl-devel epel-release"
    sshpass -p $AZVMPass ssh -o ConnectTimeout=3 $AZVMUser@$AZIPVMB "echo '$AZVMPass' |sudo -S yum install -y python-pip python-wheel"
    sshpass -p $AZVMPass ssh -o ConnectTimeout=3 $AZVMUser@$AZIPVMB "echo '$AZVMPass' |sudo -S rpm --import https://packages.microsoft.com/keys/microsoft.asc"

    sshpass -p $AZVMPass ssh -o ConnectTimeout=3 $AZVMUser@$AZIPVMB "echo '$AZVMPass' |sudo -S touch /etc/yum.repos.d/azure-cli.repo"
    sshpass -p $AZVMPass ssh -o ConnectTimeout=3 $AZVMUser@$AZIPVMB "echo '$AZVMPass' |sudo -S sh -c 'echo -e \"[azure-cli]\nname=Azure CLI\nbaseurl=https://packages.microsoft.com/yumrepos/azure-cli\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc$(hostname)\"> /etc/yum.repos.d/azure-cli.repo'"
    sshpass -p $AZVMPass ssh -o ConnectTimeout=3 $AZVMUser@$AZIPVMB "echo '$AZVMPass' |sudo -S yum -y install azure-cli"
    sshpass -p $AZVMPass ssh -o ConnectTimeout=3 $AZVMUser@$AZIPVMB "echo '$AZVMPass' |sudo -S pip install ansible[azure]"
    sshpass -p $AZVMPass ssh -o ConnectTimeout=3 $AZVMUser@$AZIPVMB "pip install ansible[azure]"

    sshpass -p $AZVMPass ssh -o ConnectTimeout=3 $AZVMUser@$AZIPVMB "sh -c 'mkdir ~/.azure'"
    sshpass -p $AZVMPass ssh -o ConnectTimeout=3 $AZVMUser@$AZIPVMB "sh -c 'mkdir ~/playbooks'"
    sshpass -p $AZVMPass ssh -o ConnectTimeout=3 $AZVMUser@$AZIPVMB "sh -c 'mkdir ~/bin'"

    # Cambios a Archivos
    cp ./include/azcredentials ./include/azcredentials1
    cp ./include/credentialsaz ./include/credentialsaz1

    SUFFL=$(echo $AZCSUFF | awk '{ print tolower($0) }')
    SUFFH=$(echo $AZCSUFF | awk '{ print toupper($0) }')

    eval sed -i 's/SPSUBSCRIPTION/$SUBSCRIPTIONID/g' ./include/azcredentials1
    eval sed -i 's/SPCLIENT/$AZURE_CLIENT_ID/g' ./include/azcredentials1
    eval sed -i 's/SPSECRET/$AZURE_SECRET/g' ./include/azcredentials1
    eval sed -i 's/SPTENANT/$AZURE_TENANT/g' ./include/azcredentials1

    eval sed -i 's/SPSUBSCRIPTION/$SUBSCRIPTIONID/g' ./include/credentialsaz1
    eval sed -i 's/SPCLIENT/$AZURE_CLIENT_ID/g' ./include/credentialsaz1
    eval sed -i 's/SPSECRET/$AZURE_SECRET/g' ./include/credentialsaz1
    eval sed -i 's/SPTENANT/$AZURE_TENANT/g' ./include/credentialsaz1

    sshpass -p $AZVMPass scp ./include/azcredentials1 $AZVMUser@$AZIPVMB:~/.azure/credentials
    sshpass -p $AZVMPass scp ./include/credentialsaz1 $AZVMUser@$AZIPVMB:~/.

    cp ./playbooks/vm.yml ./playbooks/vm1.yml

    eval sed -i 's/AZSUBSCRIPTION/$SUBSCRIPTIONID/g' ./playbooks/vm1.yml
    eval sed -i 's/VMPROCSIZE/$VMPROCSIZE/g' ./playbooks/vm1.yml
    eval sed -i 's/azcsuff/$SUFFL/g' ./playbooks/vm1.yml
    eval sed -i 's/AZCSUFF/$SUFFH/g' ./playbooks/vm1.yml
    eval sed -i 's/PROCLOC/$GLOC/g' ./playbooks/vm1.yml
    eval sed -i 's/AZVMUser/$AZVMUser/g' ./playbooks/vm1.yml
    eval sed -i 's/AZVMPass/$AZVMPass/g' ./playbooks/vm1.yml
    VNETANSI1=$(echo $VNETANSI | awk -F\\/ '{ print $1"\\/"$2}')
    eval sed -i 's/AZVNET/$VNETANSI1/g' ./playbooks/vm1.yml
    VSNETANSI1=$(echo $VSNETANSI | awk -F\\/ '{ print $1"\\/"$2}')
    eval sed -i 's/AZVSNET/$VSNETANSI1/g' ./playbooks/vm1.yml

    sshpass -p $AZVMPass scp ./playbooks/rg.yml $AZVMUser@$AZIPVMB:~/playbooks/.
    sshpass -p $AZVMPass scp ./playbooks/vm1.yml $AZVMUser@$AZIPVMB:~/playbooks/.

    sshpass -p $AZVMPass scp ./conf/profiled.conf $AZVMUser@$AZIPVMB:~/.
    sshpass -p $AZVMPass ssh -o ConnectTimeout=3 $AZVMUser@$AZIPVMB "sh -c 'cat /home/$AZVMUser/profiled.conf >> ~/.bashrc'"
    sshpass -p $AZVMPass ssh -o ConnectTimeout=3 $AZVMUser@$AZIPVMB "sh -c 'cat /home/$AZVMUser/credentialsaz1 >> ~/.bashrc'"
    sshpass -p $AZVMPass ssh -o ConnectTimeout=3 $AZVMUser@$AZIPVMB "sh -c 'rm -rf /home/$AZVMUser/credentialsaz1'"
    sshpass -p $AZVMPass ssh -o ConnectTimeout=3 $AZVMUser@$AZIPVMB "sh -c '. .bashrc'"
    sshpass -p $AZVMPass ssh -o ConnectTimeout=3 $AZVMUser@$AZIPVMB "sh -c 'chown $AZVMUser: ~/.azure/credentials'"
    sshpass -p $AZVMPass ssh -o ConnectTimeout=3 $AZVMUser@$AZIPVMB "sh -c 'wget https://raw.githubusercontent.com/ansible/ansible/devel/contrib/inventory/azure_rm.py -O ~/bin/azure_rm.py'"
    sshpass -p $AZVMPass ssh -o ConnectTimeout=3 $AZVMUser@$AZIPVMB "sh -c 'chmod +x ~/bin/azure_rm.py'"
    sshpass -p $AZVMPass ssh -o ConnectTimeout=3 $AZVMUser@$AZIPVMB "sh -c 'ansible-playbook ~/playbooks/vm1.yml'"
    sshpass -p $AZVMPass ssh -o ConnectTimeout=3 $AZVMUser@$AZIPVMB "sh -c 'az login --service-principal -u $AZURE_CLIENT_ID -p $AZURE_SECRET --tenant $AZURE_TENANT'"
    sshpass -p $AZVMPass ssh -o ConnectTimeout=3 $AZVMUser@$AZIPVMB "sh -c 'az resource tag --tags ANSIBLE --name $ANSIMNAME-TEST -g $VGROUP-TEST --resource-type Microsoft.Compute/virtualMachines'"
    sshpass -p $AZVMPass ssh -o ConnectTimeout=3 $AZVMUser@$AZIPVMB "sh -c 'ansible -i ~/bin/azure_rm.py $(echo $VGROUP-TEST | awk '{ print tolower($0) }') -m ping '"

fi
