@echo off
rem Rebuild the sound banks with ca65/ld65 and compare them with the ROM.
cd /d "%~dp0"
python tool\verify.py "..\McDonaldLand (E) [!].nes"
