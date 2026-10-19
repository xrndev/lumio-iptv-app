@echo off
rem Doble clic para instalar Lumio (sin administrador, sin dependencias).
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Install.ps1" %*
if errorlevel 1 (
  echo.
  echo La instalacion ha fallado. Pulsa una tecla para cerrar.
  pause >nul
)
