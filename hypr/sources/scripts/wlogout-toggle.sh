#!/usr/bin/env bash

if pgrep wlogout > /dev/null; then
    pkill wlogout
else
    wlogout -b 4 -n -m 100
fi
