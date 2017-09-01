#! /usr/bin/env python3

import argparse
import subprocess


GRADER_NODES = [
    'class7',
    'class8',
    'class9',
    'class10',
    'g280-1',
]


def main():
    args = parse_args()

    cmd_base = 'docker node update --availability {} {}'

    if args.solo:
        for node in GRADER_NODES:
            if node == args.solo:
                subprocess.run(cmd_base.format('active', node).split())
                continue

            cmd = cmd_base.format('pause', node)
            subprocess.run(cmd.split())
    elif args.start_all:
        for node in GRADER_NODES:
            subprocess.run(cmd_base.format('active', node).split())
    elif args.pause_all:
        for node in GRADER_NODES:
            subprocess.run(cmd_base.format('pause', node).split())


def parse_args():
    parser = argparse.ArgumentParser()
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("--solo", nargs='?')
    group.add_argument("--start_all", action='store_true')
    group.add_argument("--pause_all", action='store_true')

    return parser.parse_args()


if __name__ == '__main__':
    main()
