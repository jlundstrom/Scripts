@echo off
@setlocal enableextensions
@cd /d "%~dp0"
certutil -addstore "Root" "StartSSL CA.cer"
pause