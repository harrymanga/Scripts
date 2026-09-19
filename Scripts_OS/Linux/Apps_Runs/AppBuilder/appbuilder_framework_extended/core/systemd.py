def make_service(app_name, install_path, user='root'):
    svc = f'''[Unit]
Description={app_name} service
After=network.target

[Service]
Type=simple
ExecStart={install_path}/start.sh prod
ExecStop={install_path}/stop.sh
Restart=always
User={user}
WorkingDirectory={install_path}

[Install]
WantedBy=multi-user.target
'''
    return svc
