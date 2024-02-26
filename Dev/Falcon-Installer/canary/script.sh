#!/bin/bash

while [ "$1" != "" ]; do
  if [ "$1" == "-b" ]; then
    shift
  fi
  echo "$1"
  shift
done