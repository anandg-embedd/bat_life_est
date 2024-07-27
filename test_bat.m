close all;
clear all;
clc;
prompt = {'DischargeTimes:','Decrement3634Vs:','MaxVoltageDischarV:','MinVoltageChargV:','Timeat415Vs:','Timeconstantcurrents:','Chargingtimes:'};
dlgtitle = 'Input';
fieldsize = [1 45; 1 45; 1 45; 1 45; 1 45; 1 45; 1 45;];
definput = {'7385.5','1080.3206666666665','4.25','3.225','5502.015999999996','6762.02','10322.81'};
answer = inputdlg(prompt,dlgtitle,fieldsize,definput);
load rnn_train.mat
k=1;
o = []; zt = []; ht = zeros(N_best, 1);
[o, ht, zt] = forward(str2double(answer)', Wih_best, Whh_best, Who_best, bh_best, ht, zt, o, k);
rul=o*(Zmax(end)-Zmin(end))+Zmin(end);
f = msgbox(o,'Remaining Useful Life');