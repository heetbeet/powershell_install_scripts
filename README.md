# powershell_install_scripts
Custom install scripts to make my python life easier

Things to keep in mind for portable python grabber
- Official portable python available: "Windows x86-64 embeddable zip file"
- get-pip.py with $curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py && python get-pip.py
- lots of missing dlls: api-ms-win... etc, Anaconda have these packaged
- missing sqlite3 dll for jupyter notebooks, on the official sqlite3 download site


I want to be able to determine the newest download links for the needed packages, download them, and bundle them.