#!/usr/bin/env python3
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
    for i in range(int(N/2)):
        cos_v = (max_val * math.cos(2*math.pi * i / N))
        sin_v = (max_val * math.sin(2*math.pi * i / N))
        coeffs.append(complex(cos_v, sin_v))
        print("%7.2f %7.2f -> %s %s" % (cos_v, sin_v, hex3(int(cos_v)), hex3(int(sin_v))))
        real_fh.write(hex3(int(cos_v)) + " // %3d => %d\n" % (i, int(cos_v)))
        imag_fh.write(hex3(int(sin_v)) + " // %3d => %d\n" % (i, int(sin_v)))
#        real_fh.write(num_to_bin(int(cos_v), width) + "\n")
#        imag_fh.write(num_to_bin(int(sin_v), width) + "\n")
    
    addr_w = math.ceil(math.log(N/2,2))
    num_zeros = int(2**addr_w - N/2)
    print("adding %d zeros" % num_zeros)
    for i in range(num_zeros):
#        real_fh.write(num_to_bin(0, width) + "\n")
#        imag_fh.write(num_to_bin(0, width) + "\n")
        real_fh.write(hex3(0) + "\n")
        imag_fh.write(hex3(0) + "\n")
    
    return coeffs

def gen_freq_bram():
    bram_fh = open("freq_bram.list", 'w')
    for i in range(int(N)):
        bram_fh.write(hex3(i) + "\n")


if __name__ == '__main__':

    if len(sys.argv) != 3:
        sys.exit("give number bins as first arg, data width as second arg")

    N = int(sys.argv[1])
    width = int(sys.argv[2])

    max_val = (2 ** width - 1)/2

    gen_twiddle()
    print("N: %d, width: %d, max (signed) %d" % (N, width, max_val))

