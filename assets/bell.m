fs = 44100;
t = 0:1/fs:0.8;
y = sin(2*pi*1760*t) .* exp(-6*t) + 0.3*sin(2*pi*3520*t) .* exp(-5*t);
audiowrite('assets/bell.wav', y, fs);
