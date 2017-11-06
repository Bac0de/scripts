#!/bin/bash

NAME=win10
ID=$1

virsh reboot $NAME-$ID
