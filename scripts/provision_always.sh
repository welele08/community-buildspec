#!/bin/bash
vgscan
vgchange -a y
systemctl restart docker