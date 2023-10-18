@echo off
pushd %~dp0

del /s /q  log.txt >nul 2>&1
pixel_volte_easy_no_log.bat | tools\wtee.exe -a log.txt