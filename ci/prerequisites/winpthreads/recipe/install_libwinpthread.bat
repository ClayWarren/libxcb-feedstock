mkdir %LIBRARY_BIN%
if "%target_platform%"=="win-64" (
  xcopy %SRC_DIR%\binary-libwinpthread\ucrt64\bin\* %LIBRARY_BIN%\ /s /e /y
)
if "%target_platform%"=="win-arm64" (
  xcopy %SRC_DIR%\binary-libwinpthread-arm64\clangarm64\bin\* %LIBRARY_BIN%\ /s /e /y
)
