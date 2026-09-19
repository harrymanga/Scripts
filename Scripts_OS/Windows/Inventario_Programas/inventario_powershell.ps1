# Inventario de programas instalados vía el registro de Windows.
# Cubre programas de 32 bits (y de 64 bits según vista del registro).
# Salida en el Escritorio del usuario actual.
Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* |
  Select-Object DisplayName, DisplayVersion, Publisher, InstallDate |
  Format-Table -AutoSize > "$env:USERPROFILE\Desktop\Programas_instalados_powershell.txt"
