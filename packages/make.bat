@echo off


goto main


:setupPkg
	del "%GAME_PATH%\System\%*.u"
	mklink /J "%GAME_PATH%\%*" "%~dp0\%*"
	exit /B


:fail
	echo Error: %*
	exit 1


:success
	echo Done!
	exit


:main
	if "%GAME_PATH%"=="" (
		call :fail GAME_PATH needs to be set
		goto :eof
	)

	call :setupPkg VisualStreamPlayer

	"%GAME_PATH%\System\UCC" make "ini=%~dp0\make.ini"
	
	if %errorlevel%==0 (
		call :success
	) else (
		call :fail An error occurred.
	)