f_news() {
    RET=$?
    NOK=$1
    NBAD=$2

    if [ "$RET" -eq 0 ]; then
        echo "$NOK"
    else
        echo "$NBAD"
        exit
    fi
}

f_title() {
    TITLE=$1

    echo "Creando $1"

}

A_Group() {
    GNAME=$1
    GLOC=$2

    az group create --location $GLOC --name $GNAME >>~/bAnsi.log 2>&1
    f_news "Grupo $GNAME Creado" "Grupo $GNAME No Creado" >>~/bAnsi.log 2>&1

    echo $GNAME
}

A_FW() {
    NAME=$1
    GROUP=$2
    SRCIP=$3

    f_title "Network Security Group" >>~/bAnsi.log 2>&1
    az network nsg create --resource-group $GROUP --name $NAME >>~/bAnsi.log 2>&1
    f_news "NSG $NAME creado" "NSG $NAME no creado" >>~/bAnsi.log 2>&1

    f_title "NSG - SSH Allow" >>~/bAnsi.log 2>&1
    if [ "$SRCIP" == "" ]; then
        az network nsg rule create --resource-group $GROUP --nsg-name $NAME --name $NAME-SSH --protocol tcp --priority 1000 --destination-port-range 22 --access allow >>~/bAnsi.log 2>&1
        f_news "NSG $NAME-SSH creado" "NSG $NAME-SSH no creado" >>~/bAnsi.log 2>&1
    else
        az network nsg rule create --resource-group $GROUP --nsg-name $NAME --name $NAME-SSH --protocol tcp --priority 1000 --destination-port-range 22 --source-address-prefixes $SRCIP --access allow >>~/bAnsi.log 2>&1
        f_news "NSG $NAME-SSH creado" "NSG $NAME-SSH no creado" >>~/bAnsi.log 2>&1
    fi

    echo $NAME

}

C_Net() {

    CHECK=$(az group show -n $(echo $AZCSUFF)RGVNET)
    if [ "$?" -eq 0 ]; then
        CHECK=$(az network vnet show -g $(echo $AZCSUFF)RGVNET -n $(echo $AZCSUFF | awk '{ print toupper($0) }')VNET)
        if [ "$?" -eq 0 ]; then
            echo "Red  $(echo $AZCSUFF | awk '{ print toupper($0) }') Creada" >>~/bAnsi.log 2>&1
        else
            A_Net "$(echo $AZCSUFF | awk '{ print toupper($0) }')VNET" "$VNETANSI" "$(echo $AZCSUFF | awk '{ print toupper($0) }')RGVNET" >>~/bAnsi.log 2>&1
        fi
    else
        A_Group "$(echo $AZCSUFF | awk '{ print toupper($0) }')RGVNET" "$GLOC" >>~/bAnsi.log 2>&1
        A_Net "$(echo $AZCSUFF | awk '{ print toupper($0) }')VNET" "$VNETANSI" "$(echo $AZCSUFF | awk '{ print toupper($0) }')RGVNET" >>~/bAnsi.log 2>&1
    fi

    VNNAME="$(echo $AZCSUFF | awk '{ print toupper($0) }')VNET"
    echo $VNNAME

}

A_Net() {
    VNNAME=$1
    NPREFIX=$2
    NGGROUP=$3

    az network vnet create --resource-group $NGGROUP --name $VNNAME --address-prefixes $NPREFIX >>~/bAnsi.log 2>&1
    f_news "vNet $VNNAME Creado" "vNet $VNNAME No Creado" >>~/bAnsi.log 2>&1

    echo $VNNAME
}

C_SNet() {
    GROUP=$1
    VNETN=$2
    VSNETN=$3
    VSNPREFIX=$4

    CHECK=$(az network vnet subnet show -g $GROUP --vnet-name $VNETN -n $VSNETN)
    if [ "$?" -eq 0 ]; then
        echo "Subred Creada" >>~/bAnsi.log 2>&1
    else
        SUBNETNN=$(A_SNet "$VSNETN" "$VSNPREFIX" "$GROUP" "$VNETN")
    fi
    echo $SUBNETNN
}

A_SNet() {
    SUBNET=$1
    NPREFIX=$2
    NGGROUP=$3
    NETNAME=$4

    if [ "$LPIP" == "true" ]; then
        NNSG=$(A_FW "$SUBNET-NSG" $NGGROUP $SOURCEIP)
    else
        NNSG="\"\""
    fi

    az network vnet subnet create --network-security-group $NNSG --address-prefix $NPREFIX --name $SUBNET --resource-group $NGGROUP --vnet-name $NETNAME >>~/bAnsi.log 2>&1
    f_news "vSubnet $SUBNET Creado" "vSubnet $SUBNAME No Creado" >>~/bAnsi.log 2>&1
    echo $SUBNET
}

A_NIC() {
    ETHNAME=$1
    PIP=$2
    SUBN=$3

    case $PIP in
    true)
        az network public-ip create --resource-group $GNAME --name $ETHNAME-PIP --dns-name $(echo $ETHNAME | awk '{ print tolower($0) }')pip >>~/bAnsi.log 2>&1
        f_news "Public IP para $ETHNAME Creado" "Public IP para $ETHNAME No Creado" >>~/bAnsi.log 2>&1
        az network nic create --resource-group $GNAME --name $ETHNAME-NIC --public-ip-address $ETHNAME-PIP --subnet $(az network vnet subnet show -g $NGGROUP --vnet-name $VNNAME -n $SUBN -o json --query id | sed 's/\"//g') >>~/bAnsi.log 2>&1
        f_news "NIC para $ETHNAME Creado" "NIC para $ETHNAME No Creado" >>~/bAnsi.log 2>&1
        ;;
    false)
        az network nic create --resource-group $GNAME --name $ETHNAME-NIC --subnet $(az network vnet subnet show -g $NGGROUP --vnet-name $VNNAME -n $SUBN -o json --query id | sed 's/\"//g') >>~/bAnsi.log 2>&1
        f_news "NIC para $ETHNAME Creado" "NIC para $ETHNAME No Creado" >>~/bAnsi.log 2>&1
        ;;
    *) ;;

    esac
}

A_VM() {

    VMNAME=$1
    VMSIZE=$2
    VMIMG=$3
    VMUSR=$4
    VMPWD=$5
    VMPIP=$6
    GNAME=$7
    AVSET=$8
    VSNET=$9

    NAME="$(echo $AZCSUFF | awk '{ print toupper($0) }')$VMNAME"
    A_NIC "$NAME" "$VMPIP" $VSNET >>~/bAnsi.log 2>&1

    if [ "$AVSET" == "" ]; then
        AVCNF=""
    else
        AVCNF="--availability-set $AVSET"
    fi

    case $VMPIP in
    true)
        IPDOM=$(az vm create --resource-group $GNAME $AVCNF --nics $NAME-NIC --name $NAME --os-disk-name $NAME-VHD --size $VMSIZE --image $VMIMG --admin-username $VMUSR --admin-password $VMPWD | grep publicIpAddress | awk -F\" '{print $4}')
        f_news "VM $VMNAME Creada" "VM $VMNAME No Creada" >>~/bAnsi.log 2>&1
        ;;
    false)
        IPDOM=$(az vm create --resource-group $GNAME $AVCNF --nics $NAME-NIC --name $NAME --os-disk-name $NAME-VHD --size $VMSIZE --image $VMIMG --admin-username $VMUSR --admin-password $VMPWD | grep privateIpAddress | awk -F\" '{print $4}')
        f_news "VM $VMNAME Creada" "VM $VMNAME No Creada" >>~/bAnsi.log 2>&1
        ;;
    *) ;;

    esac
    echo $IPDOM
}

A_VMP() {

    VMNAME=$1
    VMSIZE=$2
    VMIMG=$3
    VMUSR=$4
    VMPWD=$5
    VMPIP=$6
    GNAME=$7
    AVSET=$8
    VSNET=$9

    NAME="$(echo $AZCSUFF | awk '{ print toupper($0) }')$VMNAME"
    A_NIC "$NAME" "$VMPIP" $VSNET >>~/bAnsi.log 2>&1

    if [ "$AVSET" == "" ]; then
        AVCNF=""
    else
        AVCNF="--availability-set $AVSET"
    fi

    case $VMPIP in
    true)
        IPDOM=$(az vm create --no-wait --resource-group $GNAME $AVCNF --nics $NAME-NIC --name $NAME --storage-sku Premium_LRS --os-disk-name $NAME-VHD --size $VMSIZE --image $VMIMG --admin-username $VMUSR --admin-password $VMPWD | grep publicIpAddress | awk -F\" '{print $4}')
        f_news "VM $VMNAME Creada" "VM $VMNAME No Creada" >>~/bAnsi.log 2>&1
        ;;
    false)
        IPDOM=$(az vm create --no-wait --resource-group $GNAME $AVCNF --nics $NAME-NIC --name $NAME --storage-sku Premium_LRS --os-disk-name $NAME-VHD --size $VMSIZE --image $VMIMG --admin-username $VMUSR --admin-password $VMPWD | grep privateIpAddress | awk -F\" '{print $4}')
        f_news "VM $VMNAME Creada" "VM $VMNAME No Creada" >>~/bAnsi.log 2>&1
        ;;
    *) ;;

    esac
    echo $IPDOM
}

A_VHD() {
    VMNAME=$1
    VMGROUP=$2
    VMSIZEGB=$3

    NAME=$(echo $AZCSUFF | awk '{ print toupper($0) }')$VMNAME

    for i in $(seq 1 $SSTRGVHD); do
        eval az vm disk attach -g $VMGROUP --vm-name $NAME --disk $NAME-DATA-$i --new --sku Premium_LRS --size-gb $3 >>~/bAnsi.log 2>&1
        f_news "VHD Data $NAME Creada" "VHD Data para $NAME No Creada" >>~/bAnsi.log 2>&1

        echo "$VMNAME-DATA"
    done
}
