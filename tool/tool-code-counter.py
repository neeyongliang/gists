#! /usr/bin/python3
# -*- coding: utf-8 -*-

import os
import subprocess

# 存放修改后的源码目录，可修改
SOURCE_CODE_DIR = '/home/someone/SourceCode'
# 存放上游源码的目录，可修改
UPSTREAM_CODE_DIR = '/home/someone/Downloads/open-source'


class CodeCount:
    """代码统计脚本

    说明：
        DebianCodeCount 是专门为源码统计而编写的脚本, 使用本脚本之前，要在系统中安装 cloc 和 dpkg-dev 包。
        其中 cloc 统计代码数量， dpkg-dev 中 dpkg-source -x 用于解压源码包
        使用本脚本之前，根据需要修改 SOURCE_CODE_DIR、UPSTREAM_CODE_DIR 如果出现卡死等情况，
        需要更新 __init__ 函数中的参数

    注意：
        此脚本在运行仍然存在失败的风险，原因在于根据我们的命名规则，我们默认上游源码解压的文件夹名称，
        与维护的文件夹名称相同, 或者是子集，即：
        gnome-help-1.4 --> upstream
        gnome-help --> source, will FAILED
        gnome-help-1.2 --> source, will FAILED
        gnome-help-1.4 --> source, will SUCCESS
        gnome-help-1.2+1debian1 --> source, will SUCCESS

        Debian 软件包名称太复杂：
        python3.6-dev
        libgtk-3-dev
        libvte-2.91-common
        无法简单的通过 -[0-9](.*) 匹配到

    作者：
        yongliang

    版本：
        0.2
    """

    def __init__(self):
        """初始化"""
        # 不适合运行解压缩的包的黑名单
        # debian-webrt-1.4.9 太过庞大，cloc 直接会卡死
        self.black_dsc_list = ['debian-webrt_1.4.9.dsc']
        # 根据需要修改
        self.diff_cmd = "diff -Nur -x \".git\" -x \".pc\" "
        self.cloc_cmd = " cloc --autoconf --by-file --exclude-dir .pc "

    @staticmethod
    def get_folders_or_files(object_path, is_get_directory, file_suffix):
        """ 获取指定地址的文件夹列表或者文件列表

        :param object_path: 指定的地址
        :param is_get_directory: 获取类型是否为文件夹
        :param file_suffix: 文件后缀名
        :return: 目标类型的列表
        """
        if object_path is None or len(object_path) == 0:
            print("Path get failed, cannot get directories or files.")
            return None

        all_files = os.listdir(object_path)
        if is_get_directory is True:
            object_list = []
            for path in all_files:
                if path == 'code-count':
                    continue
                if os.path.isdir(object_path + '/' + path) is False:
                    continue
                object_list.append(path)
        else:
            object_list = []
            for path in all_files:
                if os.path.isdir(object_path + '/' + path):
                    # print("not file!")
                    continue
                if len(path) < len(file_suffix):
                    # print("file name too short!")
                    continue
                if path[-len(file_suffix):] != file_suffix:
                    # print("not correct suffix!")
                    continue
                object_list.append(path)

        return object_list

    def get_code_dirs(self, dir_path):
        """获取 dir_path 下所有目录

        :param dir_path：指定目录
        :return: 给定目录下的所有文件夹
        """
        dirs = self.get_folders_or_files(dir_path, True, "")
        return dirs

    def test_get_code_dirs(self, dir_path):
        """get_code_dirs 的测试函数

        :param dir_path: 获取指定子目录的地址
        """
        dirs = self.get_code_dirs(dir_path)

        if dirs is None or len(dirs) == 0:
            print("directory is None")
            return

        print("test_get_code_dirs:")
        for file in dirs:
            print('dir list %s' % file)

    def get_dsc_files(self, dsc_files_path):
        """获取指定目录下的 dsc 文件

        :param dsc_files_path: dsc文件指定目录
        :return: dsc 文件列表
        """
        dsc_files = self.get_folders_or_files(dsc_files_path, False, ".dsc")
        return dsc_files

    def test_get_dsc_files(self, dsc_files_path):
        """get_dsc_files的测试函数

        :param dsc_files_path: dsc文件指定目录
        """
        dsc_files = self.get_dsc_files(dsc_files_path)

        if dsc_files is None or len(dsc_files) == 0:
            print("dsc files is None")
            return

        print("find following dsc files:")
        for dsc in dsc_files:
            print(dsc_files_path + '/' + dsc)

    @staticmethod
    def subprocess_run_command(cmd, success_message, output_file):
        """ 使用 subprocess 运行命令

        :param cmd: 运行的 shell 命令
        :param success_message: 成功之后输出的信息
        :param output_file: 是否要输出到文件
        """
        try:
            if output_file is None:
                subprocess.run(cmd, shell=True)
            else:
                p = subprocess.run(cmd, shell=True, stdout=subprocess.PIPE,stderr=subprocess.PIPE)
                # print(p.stdout)
                with open(output_file, 'wb') as f:
                    f.write(p.stdout)
        except subprocess.TimeoutExpired as e:
            print(e)
        except subprocess.SubprocessError as e:
            print(e)
        except Exception as e:
            print(e)
        else:
            print(success_message)

    def unpack_source_packages(self, dsc_directory):
        """解压源码包

        :param dsc_directory: 路径下的 dsc 文件列表
        :return:
        """
        if dsc_directory is None or len(dsc_directory) == 0:
            print("Cannot find directory to unpack!")
            return

        dsc_files = self.get_dsc_files(dsc_directory)
        if dsc_files is None or len(dsc_files) == 0:
            print("No package need to unpack!")
            return

        for dsc in dsc_files:
            if dsc in self.black_dsc_list:
                continue
            cmd = 'cd ' + dsc_directory + ';dpkg-source -x ' + dsc
            print(cmd)
            self.subprocess_run_command(cmd, "package unpack success!", None)

    def generic_cloc_log(self, directory, unpack_dirs):
        """生成 cloc 日志

        :param directory: 解压后的目录存放地址:
        :param unpack_dirs: 解压生成的目录列表
        """
        if unpack_dirs is None:
            return

        for path in unpack_dirs:
            cmd = 'cd ' + directory + ';' + self.cloc_cmd + path
            # print(cmd)
            self.subprocess_run_command(cmd, "generate cloc log OK!", path + '.count')

    def generic_diff_log(self, directory_source_dirs, directory_upstream_dirs):
        """生成 diff 日志

        :param directory_source_dirs: 上游源码目录
        :param directory_upstream_dirs: 修改后的源码目录
        """
        if directory_source_dirs is None or len(directory_source_dirs) == 0:
            print("source dirs not None failed!")
            return
        if directory_upstream_dirs is None or len(directory_upstream_dirs) == 0:
            print("object dirs not None failed!")
            return

        for i in directory_upstream_dirs:
            tmp_len = len(i)
            # print("%s length: %d" %(i, tmp_len))
            for j in directory_source_dirs:
                if len(j) < len(i):
                    continue
                if j[0:tmp_len] == i:
                    cmd = self.diff_cmd + UPSTREAM_CODE_DIR + "/" + i + " " + SOURCE_CODE_DIR + "/" + j
                    print(cmd)
                    self.subprocess_run_command(cmd, "Diff " + i + " log generate OK!", i + '.diff')
                # else:
                #     print("jump %s.diff generate, maybe directory name error in source directory" % i)

    @staticmethod
    def analyze_log_file(log_path, log_type, message):
        """分析日志的函数

        :param log_path: 日志存放地址
        :param log_type: 日志类型
        :param message: 提示信息
        """
        all_files = os.listdir(log_path)
        if all_files is None or len(all_files) == 0:
            return

        for f in all_files:
            if f[-len(log_type):] != log_type:
                print(f + message)
                continue

            print("log name is %s" % f)
            if log_type == ".diff":
                cmd = "cd " + log_path + "; diffstat " + f + " | tail -n 1"
            else:
                cmd = "cd " + log_path + "; cat " + f + " | tail -n 2"
            p = subprocess.run(cmd, shell=True, stdout=subprocess.PIPE)
            if log_type == ".diff":
                print(str(p.stdout).split('\\n')[0].replace('b\' ', ''))
            else:
                log_out_list = str(p.stdout).split('\\n')[0].split()[1:]
                log_out_list = list(map(int, log_out_list))
                log_out = log_out_list[0] + log_out_list[1] + log_out_list[2]
                print("blank:%d comment:%d code:%d" % (log_out_list[0], log_out_list[1], log_out_list[2]))
                print("cloc code number: %d" % log_out)

    def analyze_diff_log(self, diff_log_path):
        """ 输出 diff 结果

        :param diff_log_path: diff log 存放目录
        :return:
        """
        self.analyze_log_file(diff_log_path, ".diff", " is not diff file, skip!")

    def analyze_cloc_log(self, cloc_log_path):
        """ 输出 count 结果

        :param cloc_log_path: cloc log 存放目录
        :return:
        """
        self.analyze_log_file(cloc_log_path, ".count", " is not count file, skip!")


if __name__ == "__main__":
    cc = CodeCount()

    # test get dsc files
    # ================================================
    print("test get %s dsc files" % SOURCE_CODE_DIR)
    cc.test_get_dsc_files(SOURCE_CODE_DIR)
    print("test get %s dsc files" % UPSTREAM_CODE_DIR)
    cc.test_get_dsc_files(UPSTREAM_CODE_DIR)

    # 以下函数可以根据需要打开，如果调制到一般终止，又不想从头再来，可以注释掉几个步骤

    # unpack fix code
    print("==================================")
    cc.unpack_source_packages(SOURCE_CODE_DIR)
    cc.unpack_source_packages(UPSTREAM_CODE_DIR)

    # generate diff log
    print("==================================")
    source_dirs = cc.get_code_dirs(SOURCE_CODE_DIR)
    # cc.test_get_code_dirs(SOURCE_CODE_DIR)
    upstream_dirs = cc.get_code_dirs(UPSTREAM_CODE_DIR)
    # cc.test_get_code_dirs(UPSTREAM_CODE_DIR)
    cc.generic_diff_log(source_dirs, upstream_dirs)
    # generate cloc log
    cc.generic_cloc_log(SOURCE_CODE_DIR, source_dirs)

    # analyze diff log
    print("==================================")
    cc.analyze_diff_log(".")

    # analyze cloc log
    print("==================================")
    cc.analyze_cloc_log(".")
