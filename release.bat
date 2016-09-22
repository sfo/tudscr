@echo off
cd %~dp0
echo =========================================================================
echo  Festlegen der Version, welche erstellt werden soll
echo =========================================================================
echo.
for /f "tokens=1,2,3 delims= " %%a in (
  'findstr /r \TUD@Version@Check{[0-9][0-9][0-9][0-9]/[0-9][0-9]/[0-9][0-9] source\tudscr-version.dtx'
) do (
  if "%%c" == "TUD-Script}" (
    set version=%%b
  ) else (
    set version=%%b-%%c
  )
)
if exist temp rmdir temp /s /q > nul
if exist release-%version% rmdir release-%version% /s /q > nul
echo.
echo TUD-Script %version%
echo.
echo =========================================================================
echo  Erzeugen der Klassen und der inline-Dokumentation fuer %version%
echo =========================================================================
echo.
call update_classes.bat
xcopy source temp\ /s
cd temp
call clearsource.bat
del  clearsource.bat
cd doc
call cleardoc.bat
del  cleardoc.bat
cd ..
if exist test rmdir test/s /q > nul
mkdir tex\latex\tudscr
mkdir source\latex\tudscr
mkdir doc\latex\tudscr\tutorials
echo \BaseDirectory{.}> docstrip.cfg
echo \UseTDS>> docstrip.cfg
tex tudscr.ins
pdflatex "\def\tudfinalflag{}\input{tudscrsource.tex}"
pdflatex --shell-escape "\def\tudfinalflag{}\input{tudscrsource.tex}"
pdflatex --shell-escape "\def\tudfinalflag{}\input{tudscrsource.tex}"
pdflatex "\def\tudfinalflag{}\input{tudscrsource.tex}"
move  *.dtx               source\latex\tudscr\
move  tudscr.ins          source\latex\tudscr\
move  tudscrsource.tex    source\latex\tudscr\
xcopy doc                 source\latex\tudscr\doc\ /s
del source\latex\tudscr\test.tex /s > nul
for /f %%f in ('dir /b ..\*.md') do copy ..\%%f doc\latex\tudscr\%%~nf
move tudscrsource.pdf doc\latex\tudscr\
move logo             tex\latex\tudscr\
del *.* /q > nul
echo.
echo =========================================================================
echo  Erzeugen des Benutzerhandbuchs
echo =========================================================================
echo.
cd doc
pdflatex --shell-escape "\def\tudfinalflag{}\input{tudscr.tex}"
pdflatex "\def\tudfinalflag{}\input{tudscr.tex}"
pdflatex "\def\tudfinalflag{}\input{tudscr.tex}"
pdflatex "\def\tudfinalflag{}\input{tudscr.tex}"
pdflatex --shell-escape "\def\tudfinalflag{}\input{tudscr.tex}"
pdflatex "\def\tudfinalflag{}\input{tudscr.tex}"
pdflatex "\def\tudfinalflag{}\def\tudprintflag{}\input{tudscr.tex}"
copy tudscr.pdf tudscr_print.pdf
pdflatex "\def\tudfinalflag{}\input{tudscr.tex}"
del tutorials\*autopp*.* /q > nul
attrib +h "tutorials\*-standalone-*.pdf"
attrib +h "tutorials\*-pics.pdf"
move tudscr*.pdf             latex\tudscr\
move tutorials\*.pdf         latex\tudscr\tutorials\
move tutorials\*-example.tex ..\source\latex\tudscr\doc\examples\
del *.* /q > nul
rmdir examples /s /q > nul
rmdir tutorials /s /q > nul
echo.
echo =========================================================================
echo  Erzeugen der Installationdateien
echo =========================================================================
echo.
cd ..\install
copy  ..\source\latex\tudscr\tudscr-version.dtx ..\.
tex tudscr-install.ins
rename *.bxt *.bat
setlocal enabledelayedexpansion
set "pattern=_V_"
set "replace=_%version%_"
for %%a in (*.*) do (
  set "file=%%~a"
  rename "%%a" "!file:%pattern%=%replace%!"
)
endlocal
del ..\tudscr-version.dtx
echo.
echo =========================================================================
echo  Release fuer GitHub
echo =========================================================================
echo.
cd %~dp0
mkdir release-%version%\temp
mkdir release-%version%\GitHub
copy *.md                                   release-%version%\temp\
xcopy addon                                 release-%version%\temp\ /s
copy development\fonts\*.*                  release-%version%\temp\
copy development\tools\*.*                  release-%version%\temp\
copy temp\doc\latex\tudscr\tudscr.pdf       release-%version%\temp\
copy temp\doc\latex\tudscr\tudscr_print.pdf release-%version%\temp\
move temp\install\*.*                       release-%version%\temp\
rmdir temp\install /s /q > nul
rmdir temp\cwl /s /q > nul
cd release-%version%\temp
for /f %%f in ('dir /b *.bat') do unix2dos -k %%f
7za a -tzip tudscr_%version%_full.zip   .\..\..\temp\*
7za a -tzip tudscr_%version%_update.zip .\..\..\temp\* -xr!logo
7za a -tzip tudscr_fonts_install.zip                                              @7za_files_metrics.txt
call tudscr_fonts_convert.bat
7za a -tzip tudscr_fonts_converted.zip                                            @7za_files_fonts.txt
for /f %%f in ('dir /b *.md') do unix2dos -n -k %%f %%~nf.txt
7za a -tzip .\..\TUD-Script_%version%_Windows_all.zip    -x!*.sh             @7za_files_full.txt @7za_files_postscript.txt
7za a -tzip .\..\TUD-Script_%version%_Windows_full.zip   -x!*.sh             @7za_files_full.txt
7za a -tzip .\..\TUD-Script_%version%_Windows_update.zip -x!*.sh             @7za_files_update.txt
7za a -tzip .\..\TUD-Script_fonts_Windows.zip            -x!*.sh             @7za_files_fonts_install.txt
7za a -tzip .\..\TUD-Script_fonts_converted_Windows.zip  -x!*.sh             @7za_files_fonts_converted.txt
for /f %%f in ('dir /b *.md') do copy %%f %%~nf.txt
7za a -tzip .\..\TUD-Script_%version%_Unix_all.zip       -x!*.bat -x!7za.exe @7za_files_full.txt @7za_files_postscript.txt
7za a -tzip .\..\TUD-Script_%version%_Unix_full.zip      -x!*.bat -x!7za.exe @7za_files_full.txt
7za a -tzip .\..\TUD-Script_%version%_Unix_update.zip    -x!*.bat -x!7za.exe @7za_files_update.txt
7za a -tzip .\..\TUD-Script_fonts_Unix.zip               -x!*.bat -x!7za.exe @7za_files_fonts_install.txt
7za a -tzip .\..\TUD-Script_fonts_converted_Unix.zip     -x!*.bat -x!7za.exe @7za_files_fonts_converted.txt
7za a -tzip .\..\tudscr4lyx.zip       .\tudscr4lyx\*
7za a -tzip .\..\tudscr4texstudio.zip .\tudscr4texstudio\*
cd..
attrib +h *_all.zip
attrib +h *_converted*.zip
move *.zip GitHub\
attrib -h *_converted*.zip
attrib -h *_all.zip
move temp\tudscr_%version%_full.zip  GitHub\tudscr_%version%.zip
copy temp\tudscr_uninstall.*         GitHub\
move temp\tud_fonts_install.*        GitHub\
echo.
echo =========================================================================
echo  Release fuer CTAN
echo =========================================================================
echo.
mkdir CTAN\tudscr\doc
mkdir CTAN\tudscr\source
mkdir CTAN\tudscr\logo
xcopy ..\temp\doc\latex\tudscr\*.*      CTAN\tudscr\doc\    /s
xcopy ..\temp\source\latex\tudscr\*.*   CTAN\tudscr\source\ /s
xcopy ..\temp\tex\latex\tudscr\logo\*.* CTAN\tudscr\logo\   /s
move  CTAN\tudscr\doc\README            CTAN\tudscr\README
cd temp
(
  echo With WScript
  echo   ZipFile = .Arguments^(0^) 
  echo   Folder = .Arguments^(1^) 
  echo End With
  echo CreateObject^("Scripting.FileSystemObject"^).CreateTextFile^(ZipFile, True^).Write "PK" ^& Chr^(5^) ^& Chr^(6^) ^& String^(18, vbNullChar^) 
  echo With CreateObject^("Shell.Application"^) 
  echo   .NameSpace^(ZipFile^).CopyHere .NameSpace^(Folder^).Items
  echo End With
  echo wScript.Sleep 2000 
) > winzip.vbs
cd ..
CScript  temp\winzip.vbs %cd%\tudscr.zip %cd%\CTAN
move %cd%\tudscr.zip %cd%\CTAN\
echo.
echo =========================================================================
echo  Loeschen aller temporaeren Dateien
echo =========================================================================
echo.
pause.
cd %~dp0
if exist release-%version%\temp        rmdir release-%version%\temp /s /q > nul
if exist release-%version%\CTAN\tudscr rmdir release-%version%\CTAN\tudscr /s /q > nul
if exist temp                          rmdir temp /s /q > nul
