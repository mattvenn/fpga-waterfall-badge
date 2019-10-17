#!/usr/bin/env python3
import argparse
import sys
import math


def to_bytes(n, length, endianess='big'):
    h = '%x' % n
    s = ('0'*(len(h) % 2) + h).zfill(length*2).decode('hex')
    return s if endianess == 'big' else s[::-1]

def hex2(n):
    return hex (n & 0xffffffff)[:-1]

def hex3(n):
    return "0x%s"% ("00000000%x"%(n&0xffffffff))[-8:]

def twos_comp(val, bits):
    """compute the 2's complement of int value val"""
    if (val & (1 << (bits - 1))) != 0: # if sign bit is set e.g., 8bit: 128-255
        val = val - (1 << bits)        # compute negative value
    return val                         # return positive value as is

def num_to_bin(num, wordsize):
    if num < 0:
        num = 2**wordsize+num
    base = bin(num)[2:]
    padding_size = wordsize - len(base)
    return '0' * padding_size + base

def gen_twiddle():
    real_fh = open("twiddle_real.list", 'w')
    imag_fh = open("twiddle_imag.list", 'w')
    coeffs = []
    for i in range(int(args.bins/args.half)):
        if args.log:
            maxb = math.log2(args.bins+1)
            angle = 2*math.pi * (1-math.log2(args.bins-i+1)/maxb)
        else:
            angle = 2*math.pi * i / args.bins

        cos_v = max_val * math.cos(angle)
        sin_v = max_val * math.sin(angle)
        coeffs.append(complex(cos_v, sin_v))
        print("%7.2f %7.2f -> %s %s (%.2f %.2f error)" % (cos_v, sin_v, hex3(int(round(cos_v,0))), hex3(int(round(sin_v,0))), cos_v-round(cos_v,0), sin_v-round(sin_v,0)))
        real_fh.write(hex3(int(cos_v)) + " // %3d => %d\n" % (i, int(cos_v)))
        imag_fh.write(hex3(int(sin_v)) + " // %3d => %d\n" % (i, int(sin_v)))
    
    if args.no_pad:
        return

    addr_w = math.ceil(math.log(args.bins/args.half,2))
    file_len = 2**addr_w;
    num_zeros = int(file_len - args.bins/args.half)
    print("adding %d zeros to create total length %d" % (num_zeros, file_len))
    for i in range(num_zeros):
        real_fh.write(hex3(0) + "\n")
        imag_fh.write(hex3(0) + "\n")
    
    return coeffs

def gen_freq_bram():
    bram_fh = open("freq_bram.list", 'w')
    for i in range(int(args.bins)):
        bram_fh.write(hex3(i) + "\n")


if __name__ == '__main__':

    import argparse
    parser = argparse.ArgumentParser(description="generate twiddle co-efficients for FFT/SDFT")
    parser.add_argument('--bins', action='store', type=int, help="how many bins", required=True)
    parser.add_argument('--width', action='store', type=int, help="data width (signed), max value used will be automatically calculated",required=True)
    parser.add_argument('--half', action='store_const', const=2, help="only generate first half of bins", default=1)
    parser.add_argument('--no-pad', action='store_const', const=True, default=False, help="pad file with zeros up to nearest power of 2")
    parser.add_argument('--log', action='store_const', const=True, default=False, help="spread bin frequencies logarithmically instead of linearly")
    args = parser.parse_args()


    max_val = (2 ** args.width - 1)/2

    gen_twiddle()
    print("N: %d, width: %d, max (signed) %d" % (args.bins, args.width, max_val))
