#!/bin/bash

cd /home/tgstation/repos/civ/

if [ -d ".git" ]; then
  mkdir -p $1/.git/logs
  cp -r .git/logs/* $1/.git/logs/
fi

cp civ13.dmb civ13.rsc $1/
