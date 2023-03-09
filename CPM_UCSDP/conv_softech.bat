@echo off

set HXCFE=..\HxC\hxcfe.exe

for /R softech %%f in ( *.IMD ) do (
	call :conv %%f
)
::pause

goto :eof


:conv
set FINPUT=%1
set FOUTPUT=%FINPUT:.IMD=.DSK%

set CMD=%HXCFE% -finput:%FINPUT% -foutput:%FOUTPUT% -conv:RAW_LOADER
if not exist %FOUTPUT% echo %CMD% && %CMD%
if errorlevel 1 pause
goto :eof
