@echo off
set FILE=CPM230
set DISK=%FILE%-80T
if not exist JV3Disk.exe call mk_JV3Disk
jv3disk -x -i:%DISK%.JV3 -o:%FILE%.IMG -v:2
jv3disk -x -i:%DISK%.JV3 -o:%FILE%_boot.BIN -T:0 -S:1 -N:1
jv3disk -x -i:%DISK%.JV3 -o:%FILE%_cpm.BIN -T:0 -S:2 -N:35 -V:2
jv3disk -x -i:%DISK%.JV3 -o:%FILE%_bios.BIN -T:0 -S:24 -N:13 -V:2
