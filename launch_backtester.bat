@echo off
REM VECTORUM EA Backtester Launcher for Windows
REM Double-click this file to launch the GUI backtester

cd /d "%~dp0"
python3 backtester_gui.py
pause
