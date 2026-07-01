@echo off
set HORA=%time:~0,2%%time:~3,2%%time:~6,2%
set DATA=%date:~6,4%%date:~3,2%%date:~0,2%
set NOME=ConectaPro_%DATA%_%HORA%
set DESTINO=C:\Users\Antonio\Desktop\Backp_diario\%NOME%

if not exist "C:\Users\Antonio\Desktop\Backp_diario" (
    mkdir "C:\Users\Antonio\Desktop\Backp_diario"
)

echo ========================================
echo BACKUP CONECTAPRO
echo ========================================

xcopy "C:\Users\Antonio\Desktop\1.4\ConectaPro" "%DESTINO%" /E /H /I /Y

echo.
echo Backup realizado com sucesso!
explorer "%DESTINO%"
pause