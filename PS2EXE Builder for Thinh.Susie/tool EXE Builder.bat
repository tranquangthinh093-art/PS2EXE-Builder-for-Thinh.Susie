@echo off
cd /d "%~dp0"
title Auto PS1 to EXE Builder for Thinh.Susie
color 0A

set "PS1_FILE="
for %%F in (*.ps1) do (
    set "PS1_FILE=%%F"
    set "BASE_NAME=%%~nF"
    goto :FOUND_PS1
)

echo [ERROR] No .ps1 file found in this directory!
pause
exit /b

:FOUND_PS1
set "EXE_FILE=%BASE_NAME%.exe"
set "CS_FILE=%TEMP%\%BASE_NAME%_wrapper.cs"

set "ICON_OPT="
if exist "icon.ico" (
    set "ICON_OPT=/win32icon:icon.ico"
    echo [*] Found icon.ico - Applying custom icon to EXE.
) else (
    echo [!] icon.ico not found - Using default application icon.
)

set "CSC_PATH=C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe"
if not exist "%CSC_PATH%" set "CSC_PATH=C:\Windows\Microsoft.NET\Framework\v4.0.30319\csc.exe"

echo [*] Building "%EXE_FILE%" from "%PS1_FILE%"...

> "%CS_FILE%" (
    echo using System;
    echo using System.Diagnostics;
    echo using System.IO;
    echo using System.Reflection;
    echo class Program {
    echo     [STAThread]
    echo     static void Main^(^) {
    echo         string tempPs1 = Path.Combine^(Path.GetTempPath^(^), Guid.NewGuid^(^).ToString^(^) + ".ps1"^);
    echo         try {
    echo             using ^(Stream s = Assembly.GetExecutingAssembly^(^).GetManifestResourceStream^("payload.ps1"^)^)
    echo             using ^(FileStream fs = new FileStream^(tempPs1, FileMode.Create^)^) {
    echo                 s.CopyTo^(fs^);
    echo             }
    echo             ProcessStartInfo psi = new ProcessStartInfo^(^);
    echo             psi.FileName = "powershell.exe";
    echo             psi.Arguments = "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File \"" + tempPs1 + "\"";
    echo             psi.UseShellExecute = true;
    echo             psi.Verb = "runas";
    echo             psi.WindowStyle = ProcessWindowStyle.Hidden;
    echo             Process p = Process.Start^(psi^);
    echo             if ^(p != null^) p.WaitForExit^(^);
    echo         } catch { } finally {
    echo             if ^(File.Exists^(tempPs1^)^) try { File.Delete^(tempPs1^); } catch { }
    echo         }
    echo     }
    echo }
)

"%CSC_PATH%" /nologo /target:winexe %ICON_OPT% /resource:"%PS1_FILE%",payload.ps1 /out:"%EXE_FILE%" "%CS_FILE%"
del "%CS_FILE%" >nul 2>&1

if exist "%EXE_FILE%" (
    echo [SUCCESS] Created executable: "%EXE_FILE%"
) else (
    echo [FAILED] Compilation failed. Verify that icon.ico is a valid Windows icon file.
)
pause
