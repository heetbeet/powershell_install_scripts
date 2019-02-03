@echo off
REM SET PATH=C:\download_routine\Miniconda3;C:\download_routine\Miniconda3\Scripts;%userprofile%\Miniconda3;%userprofile%\Miniconda3\Scripts;%programdata%\Miniconda3;%programdata%\Miniconda3\Scripts;%userprofile%\Anaconda3;%userprofile%\Anaconda3\Scripts;%programdata%\Anaconda3;%programdata%\Anaconda3\Scripts;%PATH%
SET PATH=C:\download_routine\Miniconda3;C:\download_routine\Miniconda3\Scripts;%PATH%
SET PYCODE="import os; import sys; print( ';'.join( [ DIR+'\\'+dir for DIR, dirs, files in os.walk(os.path.split(sys.executable)[0]+'\\Library') for dir in dirs if len([i for i in os.listdir(DIR+'\\'+dir) if len([j for j in ['.bat','.exe','.vbs','.dll'] if i.lower().endswith(j)])]) ]+[os.environ['PATH']]))"

for /f %%i in ('python -c %PYCODE%') do set PATH=%%i

python -m jupyter notebook %~dp0
