using quick abs for complex number to avoid things getting too big
max error about 10%

but could also look at using the square and then a lookup table that converts the squared number to a log output for the gradient lookup

not a problem if it takes a long time? I have 480 fft cycles between bram updates to perform the conversion. each conversion takes 320 clocks. so can convert each bin in the same time as it takes to do an FFT and update them one by one.

use cordic?
