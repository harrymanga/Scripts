import os, zipfile, shutil, textwrap

TEMPLATE_ZIP = os.path.join(os.path.dirname(__file__), '..', 'templates', 'miapp_template.zip')

def create_app_project(name, destination, interpreter, interpreter_args, exec_file):
    try:
        destination = os.path.abspath(destination)
        target = os.path.join(destination, name)
        if os.path.exists(target):
            return False, f"El directorio {target} ya existe."

        # extract template
        with zipfile.ZipFile(TEMPLATE_ZIP, 'r') as z:
            z.extractall(target)

        # edit common.env
        env_path = os.path.join(target, 'conf', 'common.env')
        if os.path.exists(env_path):
            with open(env_path, 'r') as f:
                content = f.read()
            content = content.replace('APP_NAME="MiAplicacion"', f'APP_NAME="{name}"')
            content = content.replace('APP_INTER="java"', f'APP_INTER="{interpreter}"')
            content = content.replace('INTER_ARGS="-jar"', f'INTER_ARGS="{interpreter_args}"')
            content = content.replace('APP_EXEC="app.jar"', f'APP_EXEC="{exec_file}"')
            with open(env_path, 'w') as f:
                f.write(content)

        # create executable placeholder
        app_file = os.path.join(target, 'app', exec_file)
        os.makedirs(os.path.dirname(app_file), exist_ok=True)
        open(app_file, 'a').close()
        # make scripts executable
        for s in ['start.sh','stop.sh','restart.sh','install.sh','uninstall.sh']:
            p = os.path.join(target, s)
            if os.path.exists(p):
                st = os.stat(p)
                os.chmod(p, st.st_mode | 0o111)

        # rename service
        svc_old = os.path.join(target, 'miapp.service')
        svc_new = os.path.join(target, f"{name}.service")
        if os.path.exists(svc_old):
            with open(svc_old, 'r') as f:
                svc = f.read()
            svc = svc.replace('Mi Aplicacion', name)
            svc = svc.replace('miapp', name)
            with open(svc_new, 'w') as f:
                f.write(svc)
            os.remove(svc_old)

        return True, f"Proyecto creado en: {target}"
    except Exception as e:
        return False, str(e)
