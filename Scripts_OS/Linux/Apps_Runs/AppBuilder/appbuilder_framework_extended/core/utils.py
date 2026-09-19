import os
def read_env(path):
    data = {}
    if not os.path.exists(path):
        return data
    with open(path, 'r') as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith('#') or '=' not in line:
                continue
            k,v = line.split('=',1)
            data[k.strip()] = v.strip().strip('"')
    return data
