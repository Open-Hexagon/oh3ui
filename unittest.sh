#!/bin/bash

./love.AppImage . -u -c $@
luacov
rm luacov.stats.out