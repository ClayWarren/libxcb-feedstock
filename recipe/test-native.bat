@echo on
setlocal

for %%L in (xcb-1 xcb-composite-0 xcb-damage-0 xcb-dbe-0 xcb-dpms-0 xcb-dri2-0 xcb-glx-0 xcb-randr-0 xcb-record-0 xcb-render-0 xcb-res-0 xcb-screensaver-0 xcb-shape-0 xcb-shm-0 xcb-sync-1 xcb-xf86dri-0 xcb-xfixes-0 xcb-xinerama-0 xcb-xinput-0 xcb-xkb-1 xcb-xtest-0 xcb-xv-0 xcb-xvmc-0) do (
  if not exist "%LIBRARY_BIN%\%%L.dll" exit /b 1
  dumpbin /headers "%LIBRARY_BIN%\%%L.dll" | findstr /I /C:"AA64 machine (ARM64)"
  if errorlevel 1 exit /b 1
)

for %%L in (xcb xcb-composite xcb-damage xcb-dbe xcb-dpms xcb-dri2 xcb-glx xcb-randr xcb-record xcb-render xcb-res xcb-screensaver xcb-shape xcb-shm xcb-sync xcb-xf86dri xcb-xfixes xcb-xinerama xcb-xinput xcb-xkb xcb-xtest xcb-xv xcb-xvmc) do (
  if not exist "%LIBRARY_LIB%\%%L.lib" exit /b 1
  if not exist "%LIBRARY_LIB%\pkgconfig\%%L.pc" exit /b 1
)

for %%L in (xcb-dri3 xcb-ge xcb-present xcb-xevie xcb-xprint xcb-xselinux) do (
  if exist "%LIBRARY_LIB%\pkgconfig\%%L.pc" exit /b 1
)
for %%L in (xcb-dri3 xcb-present) do (
  if exist "%LIBRARY_BIN%\%%L-*.dll" exit /b 1
  if exist "%LIBRARY_LIB%\%%L.lib" exit /b 1
)

dumpbin /imports "%LIBRARY_BIN%\xcb-1.dll" | findstr /I /C:"libwinpthread-1.dll"
if errorlevel 1 exit /b 1
dumpbin /imports "%LIBRARY_BIN%\xcb-1.dll" | findstr /I /C:"Xau-6.dll"
if errorlevel 1 exit /b 1
dumpbin /imports "%LIBRARY_BIN%\xcb-1.dll" | findstr /I /C:"Xdmcp-6.dll"
if errorlevel 1 exit /b 1
dumpbin /imports "%LIBRARY_BIN%\xcb-1.dll" | findstr /I /C:"WS2_32.dll"
if errorlevel 1 exit /b 1
dumpbin /exports "%LIBRARY_BIN%\xcb-1.dll" | findstr /C:"xcb_connect"
if errorlevel 1 exit /b 1
dumpbin /exports "%LIBRARY_BIN%\xcb-render-0.dll" | findstr /C:"xcb_render_id"
if errorlevel 1 exit /b 1
dumpbin /imports "%LIBRARY_BIN%\xcb-render-0.dll" | findstr /I /C:"xcb-1.dll"
if errorlevel 1 exit /b 1

cl /nologo /MD /W4 /WX /I"%LIBRARY_INC%" test-native.c /Fe:consumer-msvc.exe /link /LIBPATH:"%LIBRARY_LIB%" xcb.lib xcb-render.lib
if errorlevel 1 exit /b 1
call %CC% %CFLAGS% -Wall -Wextra -Werror -I"%LIBRARY_INC%" test-native.c -L"%LIBRARY_LIB%" -lxcb -lxcb-render %LDFLAGS% -o consumer-clang.exe
if errorlevel 1 exit /b 1
for %%E in (consumer-msvc.exe consumer-clang.exe) do (
  dumpbin /headers %%E | findstr /C:"AA64 machine (ARM64)"
  if errorlevel 1 exit /b 1
)
set "PATH=%LIBRARY_BIN%;%PATH%"
python test-protocol.py .\consumer-msvc.exe .\consumer-clang.exe
if errorlevel 1 exit /b 1
