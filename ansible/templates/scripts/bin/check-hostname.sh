#!/bin/sh

if [ ! -r ~/.hostname ] || ! diff /etc/hostname ~/.hostname; then
  echo "Error: hostname has changed. To continue, run: cp /etc/hostname ~/.hostname"
  exit 1
fi
