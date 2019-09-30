#!/usr/bin/env python
import math

# test a quick and dirty complex absolute algorithm
# http://dspguru.com/dsp/tricks/magnitude-estimator/

def quick_abs(i, r):
    if abs(i) > abs(r):
        return abs(i) + 0.5 * abs(r)
    else:
        return abs(r) + 0.5 * abs(i)

N = 30
max_val = 10
max_error = 0
for i in range(int(N)):
    cos_v = (max_val * math.cos(2 * math.pi * i / N))
    sin_v = (max_val * math.sin(2 * math.pi * i / N))
    c = complex(cos_v, sin_v)

    real_a = abs(c)
    quick_a = quick_abs(c.imag, c.real)
    error = (quick_a / real_a) * 100
    if error > max_error:
        max_error = error
    print("%2.2f %2.2f %2.2f%%" % (real_a, quick_a, error - 100))

print("max error: %2.2f%%" % (max_error - 100))
