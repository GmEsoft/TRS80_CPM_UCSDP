@echo off

echo :::::::::::::::::::::::::::::::::::::::::::::::::::
echo :: Make floppy UCSD p-System from SOFTECH images ::
echo :::::::::::::::::::::::::::::::::::::::::::::::::::

set CPM=CPM230
set CPM_DISK=%CPM%-80T
set UCSD_DIR=softech/dist
set UCSDBOOT=UCSDBOOT_SBIOS
set SECBOOT=SECBOOT_SBIOS
set JV3_PARAMS=-ST:6

echo :: Building tools ::
if not exist JV3Disk.exe call mk_JV3Disk
if errorlevel 1 goto :eof

if not exist MakeDisk.exe call mk_MakeDisk
if errorlevel 1 goto :eof


echo :: Getting ZMAC ::

set ZMAC=zmac\zmac.exe
if not exist %ZMAC% getzmac.sh

echo :: Assembling primary bootstrap ::

%ZMAC% %UCSDBOOT%.asm --od build --oo cim,lst -c -s -g
if errorlevel 1 pause && goto :eof

echo :: Converting %CPM_DISK% to usable format ::

if not exist %CPM_DISK%.JV3 (
	echo !! %CPM_DISK%.JV3 not found !!
	pause
	exit /B 1
)

JV3Disk -A -I:%CPM_DISK%.JV3>%CPM_DISK%.LST
JV3Disk -X -I:%CPM_DISK%.JV3 -O:%CPM_DISK%.IMG>%CPM_DISK%.MAP

echo :: Getting UCSD disk images ::

if not exist %UCSD_DIR:/=\%\*.dsk (
	getucsd_softech.sh
	call conv_softech.bat
)

echo :: Extracting Secondary Bootstrap ::

makedisk -L:128 -SO:36 -M:%SECBOOT%.BIN ^
	-I:%UCSD_DIR%/HZP40DB.dsk -SI:26 -XI:1 -KI:0 -F:2 -T:18 -D:0
if errorlevel 1 echo %UCSDDISK% to %SECBOOT%.BIN failed && pause && goto :eof

echo :: Checking for missing files ::
if exist %CPM%_boot.bin if exist %CPM%_bios.bin goto checkok

echo !! %CPM% binaries not found -- extract them !!
pause
exit /B 1

:checkok

echo :: MAKING DISKS ::

call :makedisk %CPM%_softech-sys   HZP40DB	1 0  1 25

goto :eof


:makedisk
echo :: Creating disk "%1" from UCSD-P disk "%2" (T%5-T%6 interleave=%3 skew=%4)
set OUTFILE=%1
set UCSDDISK=%UCSD_DIR%/%2.dsk
echo :: Creating disk "%1" from UCSD-P disk "%2" (T%5-T%6 interleave=%3 skew=%4)>%OUTFILE%.OUT

if not exist %UCSDDISK% (
	echo !! %UCSDDISK% NOT FOUND !!
	pause
	exit /B 1
)

if exist %OUTFILE%.JV3 goto _update
echo ?? BUILD %OUTFILE%.JV3 ??
pause
makedisk -L:128 -SO:36 -M:%OUTFILE%_Pascal.IMG ^
	-I:%UCSDDISK% -SI:26 -XI:%3 -KI:%4 -F:T%5 -T:T%6 -D:T2 -P:T80>>%OUTFILE%.OUT
if errorlevel 1 echo %UCSDDISK% to %OUTFILE%_Pascal.IMG failed && pause && goto :eof

goto _build

:_update
JV3Disk -X -I:%OUTFILE%.JV3 -O:%OUTFILE%_Pascal.IMG  -1 -V:2>>%OUTFILE%.OUT
if errorlevel 1 echo %OUTFILE%.JV3 to %OUTFILE%_Pascal.IMG failed && pause && goto :eof

:_build
JV3Disk -C -O:%OUTFILE%.JV3 -I:%OUTFILE%_Pascal.IMG -T:80 -1 -V:2 %JV3_PARAMS%>>%OUTFILE%.OUT
if errorlevel 1 echo %OUTFILE%_Pascal.IMG to %OUTFILE%.JV3 failed && pause && goto :eof

JV3Disk -U -O:%OUTFILE%.JV3 -I:%CPM%_BOOT.BIN -T:0 -S:1 -N:2 -V:2 -1>>%OUTFILE%.OUT
if errorlevel 1 echo %CPM%_BOOT.BIN to %OUTFILE%.JV3 failed && pause && goto :eof

JV3Disk -U -O:%OUTFILE%.JV3 -I:build/%UCSDBOOT%.CIM -T:0 -S:2 -N:22 -V:2 -1>>%OUTFILE%.OUT
if errorlevel 1 echo build/%UCSDBOOT%.CIM to %OUTFILE%.JV3 failed && pause && goto :eof

JV3Disk -U -O:%OUTFILE%.JV3 -I:%SECBOOT%.BIN -T:0 -S:3 -N:8 -V:2 -1>>%OUTFILE%.OUT
if errorlevel 1 echo %SECBOOT%.BIN to %OUTFILE%.JV3 failed && pause && goto :eof

JV3Disk -U -O:%OUTFILE%.JV3 -I:%CPM%_BIOS.BIN -T:0 -S:24 -N:13 -V:2 -1>>%OUTFILE%.OUT
if errorlevel 1 echo %CPM%_BIOS.BIN to %OUTFILE%.JV3 failed && pause && goto :eof

JV3Disk -X -I:%OUTFILE%.JV3 -O:%OUTFILE%.IMG  -1 -V:2>>%OUTFILE%.OUT
if errorlevel 1 echo %OUTFILE%.JV3 to %OUTFILE%.IMG failed && pause && goto :eof

JV3Disk -A -I:%OUTFILE%.JV3>>%OUTFILE%.OUT

goto :eof
