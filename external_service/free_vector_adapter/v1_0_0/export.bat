set PLAYWRIGHT_BROWSERS_PATH=0
playwright install firefox
pyinstaller -F -d all -c main.py