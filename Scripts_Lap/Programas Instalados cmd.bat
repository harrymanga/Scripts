@echo off
	wmic /output:C:\programas_instalados_cmd.txt product get name,version
@pause