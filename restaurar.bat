@echo off
echo.
echo ========================================
echo   RESTAURAR BACKUP CONECTAPRO
echo ========================================
echo.
echo Backups disponíveis:
echo.
dir /B "C:\Users\Antonio\BackupsConectaPro"
echo.
set /p ESCOLHA="Digite o nome exato do backup que quer restaurar: "

if not exist "C:\Users\Antonio\BackupsConectaPro\%ESCOLHA%" (
  echo.
  echo Backup nao encontrado!
  pause
  exit
)

echo.
echo ATENCAO: Isso vai SUBSTITUIR o projeto atual pelo backup escolhido!
set /p CONFIRMA="Tem certeza? Digite SIM para continuar: "

if /i not "%CONFIRMA%"=="SIM" (
  echo Cancelado.
  pause
  exit
)

echo.
echo Restaurando...
xcopy /E /I /H /Y "C:\Users\Antonio\BackupsConectaPro\%ESCOLHA%" "C:\Users\Antonio\Desktop\1.4\ConectaPro"

echo.
echo Projeto restaurado com sucesso!
echo.
pause