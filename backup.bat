@echo off
set HORA=%time:~0,2%%time:~3,2%%time:~6,2%
set DATA=%date:~6,4%%date:~3,2%%date:~0,2%
set NOME=ConectaPro_%DATA%_%HORA%
set DESTINO=C:\Users\Antonio\BackupsConectaPro\%NOME%

echo.
echo ========================================
echo   BACKUP CONECTAPRO
echo   Salvando em: %DESTINO%
echo ========================================

xcopy /E /I /H /Y "C:\Users\Antonio\Desktop\1.4\ConectaPro" "%DESTINO%"

echo.
echo Backup concluido: %NOME%
echo.
pause