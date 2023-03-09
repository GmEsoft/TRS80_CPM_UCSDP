@echo off

if not "%1" == "" set SOURCEHD=%1
if not defined SOURCEHD set SOURCEHD=cpm4

if not "%2" == "" set HARDDISK=%2
if not defined HARDDISK set HARDDISK=ucsd-st

set CPM_DISK=CPM230
set UCSD_DIR=softech/dist
set UCSDBOOT=UCSDBOOT_SBIOS
set SECBOOT=SECBOOT_SBIOS


echo :: Building tools ::

if not exist JV3Disk.exe call mk_JV3Disk
if errorlevel 1 goto :eof

if not exist MakeDisk.exe call mk_MakeDisk
if errorlevel 1 goto :eof

if not exist HardDisk.exe call mk_HardDisk
if errorlevel 1 goto :eof


echo :: Getting ZMAC ::

set ZMAC=zmac\zmac.exe
if not exist %ZMAC% getzmac.sh


echo :: Getting UCSD disk images ::

if not exist %UCSD_DIR:/=\%\*.dsk (
	getucsd_softech.sh
	call conv_softech.bat
)


echo :: Assembling primary bootstrap ::

%ZMAC% %UCSDBOOT%.asm --od build --oo cim,lst -c -s -g
if errorlevel 1 pause && goto :eof


echo :: Converting %CPM_DISK% to usable format ::

if not exist %HARDDISK% copy %SOURCEHD% %HARDDISK%


echo == Disk #4 Bootstrap ==

set UCSDDISK=HZP40DB

makedisk -L:128 -SO:36 -M:SECBOOT.BIN ^
	-I:%UCSD_DIR%/%UCSDDISK%.dsk -SI:26 -XI:%3 -KI:%4 -F:2 -T:18 -D:0>%HARDDISK%.out
if errorlevel 1 pause && goto :eof

HardDisk -x -1 -H:0 -I:%SOURCEHD% -O:HARDBIOS.BIN -S:24 -N:26>>%HARDDISK%.out
if errorlevel 1 pause && goto :eof

HardDisk -u -1 -H:0 -I:HARDBIOS.BIN -O:%HARDDISK% -S:24 -N:26>>%HARDDISK%.out
if errorlevel 1 pause && goto :eof

HardDisk -u -1 -H:0 -I:build/%UCSDBOOT%.cim -O:%HARDDISK% -S:2 -N:22>>%HARDDISK%.out
if errorlevel 1 pause && goto :eof

HardDisk -u -1 -H:0 -I:SECBOOT.BIN -O:%HARDDISK% -S:3 -N:8>>%HARDDISK%.out
if errorlevel 1 pause && goto :eof

echo == Disk #4 ==

call :HardDisk softech-sys 0-2

echo == Disk #5 ==

::call :HardDisk ucsd-apps 3
call :HardDisk ucsd-games 3

echo == Disk #9 ==

call :HardDisk softech-interp 4

echo == Disk #10 ==

::call :HardDisk ucsd-games 5
::call :HardDisk ucsd-advx 5
::call :HardDisk ucsd-advsrc 5
::call :HardDisk ucsd-startrek 5
::call :HardDisk ucsd-kbdbx 5
::call :HardDisk ucsd-kbdb 5
call :HardDisk softech-util 5


echo == DONE ==
goto :eof



:HardDisk
set UCSDDISK=%1
set HEAD=%2

set OUTFILE=%CPM_DISK%_%UCSDDISK%
set PAYLOAD=%OUTFILE%_Payload.IMG

echo Checking %PAYLOAD%
if exist %PAYLOAD% goto Update

echo Checking %OUTFILE%.JV3
if not exist %OUTFILE%.JV3 goto Extract

echo Extracting %PAYLOAD% from Floppy image %OUTFILE%.JV3
JV3Disk -X -I:%OUTFILE%.JV3 -O:%PAYLOAD%  -T:2 -1 -V:2>>%HARDDISK%.out
if errorlevel 1 pause && goto :eof

goto Update

:Extract
echo Extracting %PAYLOAD% from Hard image %HARDDISK% Head %HEAD%
HardDisk -x -1 -H:%HEAD% -I:%HARDDISK% -O:%PAYLOAD% -T:2>>%HARDDISK%.out
if errorlevel 1 pause && goto :eof

:Update
echo Updating Hard image %HARDDISK% Head %HEAD% with %PAYLOAD%
HardDisk -u -1 -H:%HEAD% -I:%PAYLOAD% -O:%HARDDISK% -T:2>>%HARDDISK%.out
if errorlevel 1 pause && goto :eof

goto :eof
