#!/bin/bash
go mod tidy
echo `./build-mac-arm64.sh`
echo `./build-linux-amd64.sh`
#echo `./build-linux-mips.sh`
echo `./build-mac-amd64.sh`
echo `./build-win-amd64.sh`
echo `./build-linux-arm64.sh`
