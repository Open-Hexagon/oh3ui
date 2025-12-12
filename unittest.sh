#!/bin/bash

./love.AppImage . -u -c $@
status=$?
luacov
rm luacov.stats.out
exit $status