@echo off
call vcvars32.bat
if errorlevel 1 pause && exit /B %ERRORLEVEL%
cl MakeDisk.c
if errorlevel 1 pause && exit /B %ERRORLEVEL%
