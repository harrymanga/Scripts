@echo off
	wmic /output:C:\Users\harry\Desktop\programas_instalados_cmd.txt product get name,version
@pause