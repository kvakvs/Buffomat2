#!/usr/bin/env python3
#
# Buffomat2 Release and Install tool
#

import argparse
import os
import shutil
import subprocess
import sys
import zipfile

VERSION = '2022.1.0'  # year.month.build_num

ADDON_NAME = "Buffomat2"
COPY_DIRS = [
    'Src', 'Xml', 'Libs', ]

COPY_FILES = [
    'Buffomat2.lua', 'Buffomat2-Classic.toc', 'Buffomat2-BCC.toc', ]


class BuildTool:
    def __init__(self, args: argparse.Namespace):
        self.args = args
        self.version = VERSION
        self.copy_dirs = COPY_DIRS[:]
        self.copy_files = COPY_FILES[:]

    def do_install(self, addon_name: str):
        dst_path = f'{self.args.dst}/{addon_name}'

        if os.path.isdir(dst_path):
            print("Warning: Folder already exists, removing!")
            shutil.rmtree(dst_path)

        os.makedirs(dst_path, exist_ok=True)

        print(f'Destination: {dst_path}')

        for copy_dir in self.copy_dirs:
            print(f'Copying directory: {copy_dir}/*')
            shutil.copytree(copy_dir, f'{dst_path}/{copy_dir}')

        for copy_file in self.copy_files:
            print(f'Copying: {copy_file}')
            shutil.copy(copy_file, f'{dst_path}/{copy_file}')

    @staticmethod
    def do_zip_add_dir(zip: zipfile.ZipFile, dir: str, addon_name: str):
        for file in os.listdir(dir):
            file = dir + "/" + file
            print(f'ZIP: Directory {file}/')
            if os.path.isdir(file):
                BuildTool.do_zip_add_dir(zip,
                                         dir=file,
                                         addon_name=addon_name)
            else:
                zip.write(file, f'{addon_name}/{file}')

    def do_zip(self, addon_name: str):
        zip_name = f'{self.args.dst}/{addon_name}-{self.version}.zip'

        with zipfile.ZipFile(zip_name, "w", zipfile.ZIP_DEFLATED,
                             allowZip64=True) as zip_file:
            for input_dir in self.copy_dirs:
                BuildTool.do_zip_add_dir(zip_file,
                                         dir=input_dir,
                                         addon_name=addon_name)

            for input_f in self.copy_files:
                print(f'ZIP: File {input_f}')
                zip_file.write(input_f, f'{addon_name}/{input_f}')

    @staticmethod
    def git_hash() -> str:
        # Call: git rev-parse HEAD
        p = subprocess.check_output(
            ["git", "rev-parse", "HEAD"])
        hash = str(p).rstrip("\\n'").lstrip("b'")
        return hash[:8]


def main():
    parser = argparse.ArgumentParser(
        description="Buffomat Release and Install tool")
    parser.add_argument(
        '--dst', type=str, required=True, action='store',
        help='The destination directory where the game Addons will be copied, '
             'or where ZIP will be stored. TOC name will serve as directory '
             'name.')

    parser.add_argument(
        '--version', choices=['classic', 'tbc'],
        help='The version to copy or zip, classic or TBC')

    parser.add_argument(
        'command', choices=['help', 'zip', 'install'],
        help='The action to take. ZIP will create an archive. '
             'Install will copy')

    args = parser.parse_args(sys.argv[1:])
    print(args)

    if args.command == 'install':
        bt = BuildTool(args)
        bt.do_install(addon_name=ADDON_NAME)

    elif args.command == 'zip':
        bt = BuildTool(args)
        bt.do_zip(addon_name=ADDON_NAME)
    else:
        parser.print_help()


if __name__ == "__main__":
    main()
