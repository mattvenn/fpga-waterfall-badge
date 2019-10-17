#!/usr/bin/env python3
import argparse
import sys
import math
import numpy as np


def hex3(n):
    return "0x%s"% ("00000000%x"%(n&0xffffffff))[-8:]

def gen_scale():
    fh = open("SCALE.hex", 'w')
    steps_per_inc = to_max / from_max
    print(steps_per_inc)
    log_map = np.logspace(math.log2(to_max-1), 0, from_max, base=2)
    for i in range(from_max):
        print("%4d => %4d" % (i, to_max - log_map[i]))
        fh.write(hex3(int(to_max - log_map[i])) + " // %3d => %d\n" % (i, to_max - log_map[i]))

if __name__ == '__main__':

    import argparse
    parser = argparse.ArgumentParser(description="generate scaling from one DATA WIDTH to another")
    parser.add_argument('--fr', action='store', type=int, help="bits of width from", default=8)
    parser.add_argument('--to', action='store', type=int, help="bits of width to",default=8)
    parser.add_argument('--log2', action='store_const', const=True, default=False, help="map log2")
    args = parser.parse_args()

    from_max = 2 ** args.fr
    to_max = 2 ** args.to

    gen_scale();

    print("from %d (max %d), to: %d (max %d)" % (args.fr, from_max, args.to, to_max))
