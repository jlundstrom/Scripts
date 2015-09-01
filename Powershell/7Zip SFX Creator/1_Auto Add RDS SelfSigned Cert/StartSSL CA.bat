@echo off
@setlocal enableextensions
@cd /d "%~dp0"
certutil -addstore "Root" "Self Signed RDS Cert.cer"
pause