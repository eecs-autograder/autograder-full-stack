import argparse
import subprocess


SERVER_NAMES = [
    'class1',
    'class7',
    'class8',
    'class9',
    'class10',
    'g280-1',
]


def main():
    args = parse_args()

    for server in SERVER_NAMES:
        subprocess.run(['ssh', 'jameslp@{}'.format(server)] + args.cmd)


def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument('cmd', nargs='+')

    return parser.parse_args()


if __name__ == '__main__':
    main()
