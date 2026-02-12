@echo off
echo.
echo  ========================================
echo   CursorOS - Combining ISO parts...
echo  ========================================
echo.

if not exist "CursorOS-3.0.0-00.bin" (
    echo  ERROR: CursorOS-3.0.0-00.bin not found!
    echo  Put all 3 .bin files in the same folder as this script.
    pause
    exit /b 1
)
if not exist "CursorOS-3.0.0-01.bin" (
    echo  ERROR: CursorOS-3.0.0-01.bin not found!
    pause
    exit /b 1
)
if not exist "CursorOS-3.0.0-02.bin" (
    echo  ERROR: CursorOS-3.0.0-02.bin not found!
    pause
    exit /b 1
)

echo  Combining 3 parts into CursorOS-3.0.0-amd64.iso ...
echo  (This takes about 30 seconds)
echo.

copy /b CursorOS-3.0.0-00.bin+CursorOS-3.0.0-01.bin+CursorOS-3.0.0-02.bin CursorOS-3.0.0-amd64.iso

echo.
echo  ========================================
echo   Done! Created: CursorOS-3.0.0-amd64.iso
echo  ========================================
echo.
echo  Next steps:
echo    1. Open VirtualBox
echo    2. Click "New"
echo    3. Name: CursorOS / Type: Linux / Version: Debian 64-bit
echo    4. RAM: 4096 MB / Processors: 2
echo    5. Skip hard disk
echo    6. Settings ^> Storage ^> click empty disc ^> choose the ISO
echo    7. Settings ^> Display ^> Video Memory: 128 MB
echo    8. Click Start!
echo.
echo  Login: cursor / password: cursor
echo.
echo  You can delete the .bin files now.
echo.
pause
