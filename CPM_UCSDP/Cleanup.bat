@echo off
call :del *.dasm
call :del *.prn
call :del *.obj
call :del *.lst
call :del *.img
call :del *.map
call :del *.new
call :del *.tra
call :del *.tst
call :del *.bin
call :del *.obj
call :del *.bak
call :del *.out
call :del DISK2?.DSK
call :del DISK3?.DSK
call :del *Disk.exe
call :rmdir build
call :rmdir zmac
call :rmdir cpmsim
call :rmdir softech
call :rmdir sage
call :rmdir sourceiv
goto :eof

:del
if exist %1 del %1
if errorlevel 1 echo del %1 failed
goto :eof

:rmdir
if exist %1 rmdir /S /Q %1
if errorlevel 1 rmdir /S /Q %1 failed
goto :eof
