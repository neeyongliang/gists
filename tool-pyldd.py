#! /usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Time    : 2022.06.26
Author  : neeyongliang
Descript: A enhanced version for linux ldd by python
"""
import os
import sys
import subprocess
# import shutil
import platform
import argparse


class PyLdd(object):
    def __init__(self, sys_ld=None, do_copy=False) -> None:
        self.cmd_path = ""
        self.raw_libs = []
        self.all_libs = []
        self.paths = []
        self.arch = platform.machine()
        self.failed_libs = []
        self.do_copy = do_copy
        if not sys_ld:
            self.sys_ld = "/lib/{}-linux-gnu/ld-2.31.so".format(self.arch)
        else:
            self.sys_ld = sys_ld

    def pre_check(self, cmd_path):
        self.cmd_path = cmd_path
        if not os.path.exists(self.cmd_path):
            print("Error: cannot find at %s", cmd_path)
            return False
        if not os.path.exists(self.sys_ld):
            print("Error: cannot find system ld file at: ", self.sys_ld)
            return False
        return True

    def get_raw_libs(self):
        try:
            cmd_str = "{} {} {}".format("LD_TRACE_LOADED_OBJECTS=1",
                                        self.sys_ld, self.cmd_path)
            p = subprocess.check_output(cmd_str, shell=True)
            raw_output = p.decode().replace('\t', '\n')
            outputs = raw_output.split('\n')
            self.raw_libs = []
            self.failed_libs = []
            for output in outputs:
                if not output:
                    continue
                items = output.split(' ')
                if len(items) != 4:
                    continue
                if items[2] == "not":
                    self.failed_libs.append(items[0])
                    continue
                self.raw_libs.append(items[2])
            # print(self.raw_libs)
        except subprocess.CalledProcessError as e:
            print("Error: get ldd outputs failed, ", e)

    def get_all_libs(self):
        self.all_libs = []
        raw_lib_dir = ""
        self.paths = []
        if not self.raw_libs:
            return None
        for raw_lib in self.raw_libs:
            self.all_libs.append(raw_lib)
            while os.path.islink(raw_lib):
                raw_lib_dir = os.path.dirname(raw_lib)
                if raw_lib_dir not in self.paths:
                    os.makedirs(raw_lib_dir[1:], exist_ok=True)
                tmp = os.path.join(raw_lib_dir, os.readlink(raw_lib))
                self.all_libs.append(tmp)
                raw_lib = tmp
        # print(self.all_libs)

    def copy_libs(self):
        for lib in self.all_libs:
            if os.path.exists(lib):
                lib_dir = os.path.dirname(lib)
                cmd = "cp -a {} {}".format(lib,
                                           os.path.join(os.getcwd(),
                                                        lib_dir[1:]))
                if self.do_copy:
                    subprocess.call(cmd, shell=True)
                else:
                    print(cmd)
            else:
                print("Error: cannot find ", lib)

    def collect_failed(self):
        if not self.failed_libs:
            return
        print("Failed list:")
        for lib in self.failed_libs:
            print(lib)
        print("Find above library path, and add it to $LD_LIBRARY_PATH env")

    def single_parse(self, file_path):
        if not self.pre_check(file_path):
            return
        self.get_raw_libs()
        self.get_all_libs()
        self.copy_libs()
        self.collect_failed()

    def run(self, files=None):
        for file in files:
            self.single_parse(file)

    def print_usage(self):
        print(sys.argv[0], " BINARY_PATH")


def parse_args():
    parser = argparse.ArgumentParser(description='Ldd enhanced tool by python')
    parser.add_argument('-l', '--ld', type=str,
                        help="Cannot found ld-x.xx.so path")
    parser.add_argument('-n', '--nocopy', action='store_false',
                        help="Do not really copy, False default")
    parser.add_argument('-f', '--files', type=str, nargs='*', required=True,
                        help="ELF binary file path")
    parser.add_argument('-v', '--version', action='version',
                        version="1.0, create by neeyongliang for Linux ❤️")
    args = parser.parse_args()
    return args


if __name__ == '__main__':
    try:
        inputs = parse_args()
        pyldd = PyLdd(inputs.ld, inputs.nocopy)
        pyldd.run(files=inputs.files)
    except Exception as e:
        print("Oooooooooopt, because ", e)
