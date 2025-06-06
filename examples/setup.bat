@echo off


goto main


:fail
	echo Error: %*
	:: pause
	exit 1


:main
	if "%TEXTURES_PATH%"=="" (
		call :fail TEXTURES_PATH needs to be set
	)
	if "%MAPS_PATH%"=="" (
		call :fail MAPS_PATH needs to be set
	)

	cd packages
	cmd /C call gen_font_tex.bat
	cmd /C call make.bat

	cd ..
	copy textures\*.utx "%TEXTURES_PATH%"
	copy maps\*.unr "%MAPS_PATH%"