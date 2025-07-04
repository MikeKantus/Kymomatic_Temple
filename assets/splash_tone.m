fs = 44100;
t = 0:1/fs:2;
y = 0.4*sin(2*pi*220*t) + 0.2*sin(2*pi*440*t) + 0.1*sin(2*pi*880*t);
y = y .* exp(-1.5*t);  % Desvanecimiento
audiowrite('assets/splash_tone.wav', y, fs);