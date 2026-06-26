@echo off
setlocal EnableExtensions
cd /d "%~dp0"
title Bali Rocket Forever Safe
call "%~dp0START_BALI_ROCKET_SAFE.cmd"
exit /b %ERRORLEVEL%
