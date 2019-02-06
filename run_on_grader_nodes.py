#! /usr/bin/env python3

import argparse
import subprocess


SERVER_NAMES = [
    #'class2',
    'class1',
    'class7',
    'class8',
    'class9',
    'class10',
    'g280-1',
    'autograderio01',
    'autograderio02',
    'autograderio04',
]


def main():
    args = parse_args()

    for server in SERVER_NAMES:
        print('---------------- ', server, ' --------------')
        subprocess.run(['ssh', 'jameslp@{}'.format(server)] + args.cmd)
#        input()


def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument('cmd', nargs=argparse.REMAINDER)

    return parser.parse_args()


if __name__ == '__main__':
    main()
