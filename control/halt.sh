#!/bin/bash

NAME=win10
ID=$1

virsh destroy $NAME-$ID
