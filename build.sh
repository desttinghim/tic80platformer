#!/usr/bin/env bash

# Builds the cartridges
EXPORT_NAME="platformer"

rm build/*
luacc -o build/$EXPORT_NAME.lua -p "<<luacc>>" -i ./ platformer "lib/tiny" "anim" "util" "level"
tic80 --skip --fs build/ --cmd "load $EXPORT_NAME.lua & save $EXPORT_NAME.tic & save $EXPORT_NAME.png & exit"
