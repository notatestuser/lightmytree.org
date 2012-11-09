#!/bin/sh
COFFEE=/usr/local/bin/coffee
$COFFEE -c app/*.coffee && $COFFEE -c app/routes/*.coffee && $COFFEE -c app/configs/*.coffee
echo "Built all server-side coffee sources"
