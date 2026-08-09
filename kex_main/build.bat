@ECHO OFF

if exist main.kex del main.kex
c-- -KEX main.c

if errorlevel 1 goto build_failed
if not exist main.kex goto build_failed

if exist warning.txt del warning.txt
echo Built main.kex
exit /b 0

:build_failed
echo KEX build failed.
pause
exit /b 1
