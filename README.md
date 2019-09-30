# Resources

LCD datasheet: http://aitendo3.sakura.ne.jp/aitendo_data/product_img/lcd/tft/AT035DL01/LQ035NC111.pdf
19.5MHz

# Notes

## abs of complex fft out

using quick abs for complex number to avoid things getting too big
max error about 10%

but could also look at using the square and then a lookup table that converts the squared number to a log output for the gradient lookup

not a problem if it takes a long time? I have 480 fft cycles between bram updates to perform the conversion. each conversion takes 320 clocks. so can convert each bin in the same time as it takes to do an FFT and update them one by one.

use cordic?

## memory usage

* sdft.twiddle rom - the complex coefficients for the fft. need a pair of 8bit signed values for each bin
* sdft.frequency_bins_[real|imag] - output of the fft
* top.freq_bram - bram that stores absolute value of the fft bins: one for each bin at 8bit depth. Every screen update, the contents are copied to the frame buffer
* top.frame buffer - uses 3 x single port rams for 320 x 240 x 8bit frame buffer
* top.gradient rom - bram that maps 8 bit fft output value (stored in frame buffer) to a 24 bit colour. This is generated by the script in ./images

# Todo

* fix dsp/multiply issue - done
* buy mic pmod - done
* rgb driver for incoming amplitude
* work on colour scheme
* why does colour scheme change depending on SEED?
* auto gain control
