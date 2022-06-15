#! /usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Time    : 2022.06.14
Author  : neeyongliang
File    : tool-pyldd.py
Descript: write auto check and list dynamic libraries for ldd
"""
import os
import sys
import subprocess
import shutil


class PyLdd(object):
    def __init__(self) -> None:
        self.cmd_path = ""
        self.raw_libs = []
        self.all_libs = []
        self.paths = []

    def pre_check(self, cmd_path):
        self.cmd_path = cmd_path
        if not os.path.exists(self.cmd_path):
            self.print_usage()
            return False
        return True

    def get_raw_libs(self):
        try:
            cmd_str = "ldd " + self.cmd_path
            p = subprocess.check_output(cmd_str, shell=True)
            raw_output = p.decode().replace('\t', '\n')
            outputs = raw_output.split('\n')
            self.raw_libs = []
            for output in outputs:
                if not output:
                    continue
                items = output.split(' ')
                if len(items) != 4:
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
                print(cmd)
            else:
                print("warn: cannot find: ", lib)

    def single_parse(self, cmd_path):
        self.pre_check(cmd_path)
        self.get_raw_libs()
        self.get_all_libs()
        self.copy_libs()

    def run(self, cmds):
        for cmd in cmds:
            self.single_parse(cmd)

    def print_usage(self):
        print("tool-get-link-target.py BINARY_PATH")


if __name__ == '__main__':
    try:
        pyldd = PyLdd()
        if len(sys.argv) > 1:
            pyldd.run(sys.argv[1:])
        else:
            pyldd.print_usage()
    except Exception as e:
        print("Ooooops: something wrong, ", e)
