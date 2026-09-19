#!/usr/bin/env python3
import argparse, os
from core.generator import create_app_project

parser = argparse.ArgumentParser(description="AppBuilder CLI")

parser.add_argument("--name", required=True, help="Application name")
parser.add_argument("--dest", default=".", help="Destination folder")
parser.add_argument("--inter", default="python3", help="Interpreter")
parser.add_argument("--args", default="", help="Interpreter args")
parser.add_argument("--exec", dest="exec_file", default="main.py", help="Main executable file")

args = parser.parse_args()

ok, msg = create_app_project(args.name, args.dest, args.inter, args.args, args.exec_file)
print(msg)
