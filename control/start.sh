#!/bin/bash

NAME=win10
ID=$1

virsh start $NAME-$ID
