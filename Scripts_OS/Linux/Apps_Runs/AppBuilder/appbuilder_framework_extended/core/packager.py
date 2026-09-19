import shutil, os

def package_as_zip(project_path, output_path=None):
    output = output_path or (project_path.rstrip('/\\') + '.zip')
    base = os.path.abspath(project_path)
    shutil.make_archive(os.path.splitext(output)[0], 'zip', base)
    return output
