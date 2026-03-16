
import argparse
from pathlib import Path
from jar_manager.core.jar_service import JarService

def run():
    parser = argparse.ArgumentParser()
    parser.add_argument("--unpack", nargs="+")
    parser.add_argument("--pack", nargs="+")
    parser.add_argument("--output", required=True)
    args = parser.parse_args()

    destination = Path(args.output)

    if args.unpack:
        for file in args.unpack:
            JarService.unpack(Path(file), destination)

    if args.pack:
        for folder in args.pack:
            JarService.pack(Path(folder), destination)
