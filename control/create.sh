#!/bin/bash

NAME=win10
ID=$1

UUID=$(uuidgen)
# batu -> ba:40
MAC=$(hexdump -n4 -e'/4 "ba:40" 4/1 ":%02x"' /dev/urandom)

echo "Creating $NAME-$1"
echo "UUID - $UUID"
echo "MAC -  $MAC"

# Create a new VM using new credentials
# TODO : Check duplicates with existing VMs across network
cp /etc/batu/skeleton/$NAME.xml          /tmp/$NAME-$1-$UUID.xml
sed -i -e s@BATU_CREATE_NAME@$NAME-$ID@g /tmp/$NAME-$1-$UUID.xml
sed -i -e s@BATU_CREATE_UUID@$UUID@g     /tmp/$NAME-$1-$UUID.xml
sed -i -e s@BATU_CREATE_MAC@$MAC@g       /tmp/$NAME-$1-$UUID.xml

virsh define /tmp/$NAME-$1-$UUID.xml
rm /tmp/$NAME-$1-$UUID.xml
