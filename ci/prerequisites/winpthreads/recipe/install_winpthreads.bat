@echo on

mkdir %LIBRARY_BIN%
if "%target_platform%"=="win-64" (
  xcopy %SRC_DIR%\binary-winpthreads\ucrt64\lib\* %LIBRARY_LIB%\ /s /e /y
  xcopy %SRC_DIR%\binary-winpthreads\ucrt64\include\* %LIBRARY_INC%\ /s /e /y
)
if "%target_platform%"=="win-arm64" (
  xcopy %SRC_DIR%\binary-winpthreads-arm64\clangarm64\lib\* %LIBRARY_LIB%\ /s /e /y
  xcopy %SRC_DIR%\binary-winpthreads-arm64\clangarm64\include\* %LIBRARY_INC%\ /s /e /y
)

echo LIBRARY libwinpthread-1 > libwinpthread-1.def
echo EXPORTS >> libwinpthread-1.def
for /f "skip=19 tokens=4" %%A in ('dumpbin /exports %LIBRARY_BIN%\libwinpthread-1.dll') do echo %%A >> libwinpthread-1.def

if "%target_platform%"=="win-64" (
  lib /def:libwinpthread-1.def /out:pthread.lib /machine:x64
)
if "%target_platform%"=="win-arm64" (
  lib /def:libwinpthread-1.def /out:pthread.lib /machine:arm64
)
copy pthread.lib %LIBRARY_LIB%
