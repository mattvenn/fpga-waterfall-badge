import time
import struct
import serial
import numpy as np

def sample(store=False):
    ser=serial.Serial()
    ser.port="/dev/ttyUSB1"
    ser.baudrate=115200
    ser.timeout=1
    ser.open()

    count = 0
    while ser.inWaiting():
        count += 1
        ser.read()

    print("flushed %d samples" % count)
    print("triggering new sample set by sending char")

    samples = 4096  * 2
    ser.write("A");
    data = ser.read(samples)
    print("got %d samples OK" % len(data))
    #assert len(data) == samples

    y = []
    x = []
    for i in range(samples/2-1):
        val, =struct.unpack('<H', data[i*2] + data[i*2+1])

        y.append(val)
        x.append(i)

    if store:
        with open("data.csv", 'w') as fh:
            fh.writelines([str(v) + "\n" for v in y])

    return x, y

def load():
    y = []
    x = []
    with open("data.csv") as fh:
        for val in fh.readlines():
            x.append(len(x))
            y.append(val)

    return x, y

def plot(x, y):
    n = len(x)
    import matplotlib.pyplot as plt
    fig = plt.figure()
    ax = fig.add_subplot(3,1,1)
    # time plot
    ax.plot(x, y, 'g')
    ax.set_ylim(0,5000)

    ax.set_xlabel('samples')
    ax.set_ylabel('ADC count')

    # freq plot
    ax = fig.add_subplot(3,1,2)

    Fs = 12000000 / 16.0;  # sampling rate
    Ts = 1.0/Fs; # sampling interval

    k = np.arange(n/2)
    T = n/Fs
    frq = k/T # two sides frequency range
    #frq = frq[range(n/2)] # one side frequency range

    y = np.array(y).astype(np.int32)
    Y = np.fft.fft(y)/n # fft computing and normalization
    Y = Y[range(n/2)]

    ax.set_xlabel('Freq (Hz)')
    ax.set_ylabel('|Y(freq)|')

    ax.plot(frq, abs(Y), 'r')

    # bin plot
    ax = fig.add_subplot(3,1,3)
    ax.set_xlabel('ADC count')
    ax.set_ylabel('count')

    counts = np.arange(2**12)
    bins = np.zeros(2**12)

    for s in y:
        bins[s] += 1;

    ax.bar(counts, bins)
    ax.set_ylim(0,5000)
    ax.set_xlim(0,2**12)

    plt.show()

x, y = sample(store=True)
