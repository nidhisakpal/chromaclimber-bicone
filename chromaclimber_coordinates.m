function [T, Conditions] = chromaclimber_coordinates(T)
%CHROMACLIMBER_COORDINATES Map recorded color logs without recalibrating them.
% Uses firmware H, L and (max-min)/max saturation. This is an HSL-inspired
% bicone, NOT standard HSL and NOT a perceptually uniform error metric.
% Lightness bounds are calculated from all eight colors in each condition.
% Logged raw measurements and logged final classification are preserved.

required = {'Room','Integration_ms','AmbientLight','TrueIndex', ...
    'PredictedIndex','RawR','RawG','RawB','HueLogged', ...
    'LightnessLogged','SaturationLogged'};
assert(istable(T),'Input must be a MATLAB table.');
assert(all(ismember(required,T.Properties.VariableNames)), ...
    'The input is missing required cleaned-log columns.');
assert(height(T)>0,'No measurements were supplied.');
T.Room = string(T.Room); T.AmbientLight = string(T.AmbientLight);
numericData = T{:,{'Integration_ms','TrueIndex','PredictedIndex','RawR', ...
    'RawG','RawB','HueLogged','LightnessLogged','SaturationLogged'}};
assert(all(isfinite(numericData(:))),'Numeric measurements must be finite.');
assert(all(T.SaturationLogged>=0 & T.SaturationLogged<=1), ...
    'Logged saturation is outside [0,1]; inspect the original records.');
assert(all(T.RawR>=0 & T.RawG>=0 & T.RawB>=0 & T.LightnessLogged>=0), ...
    'Negative RGB or lightness values require inspection.');
assert(all(ismember(T.PredictedIndex,0:7)) && all(ismember(T.TrueIndex,0:7)), ...
    'The expected firmware color indices are integers 0 through 7.');

names = ["Black";"White";"Red";"Yellow";"Green";"Cyan";"Blue";"Magenta"];
T.PredictedColor = names(T.PredictedIndex+1);
T.Correct = double(T.TrueIndex==T.PredictedIndex);
T.Condition = T.Room + " | " + T.AmbientLight + " | " + ...
    string(T.Integration_ms) + " ms";
T.HueWrapped = mod(T.HueLogged,1); % Printed 1.00 and 0.00 share the hue seam.

% Derive an explicitly UNCALIBRATED representation from the raw RGB values.
% No channel correction, reference fitting or test-set color relabeling.
R=T.RawR; G=T.RawG; B=T.RawB;
mx=max([R,G,B],[],2); mn=min([R,G,B],[],2); delta=mx-mn;
h=zeros(height(T),1); chromatic=delta>0;
a=chromatic & R==mx;
h(a)=(G(a)-B(a))./delta(a);
a=chromatic & G==mx;
h(a)=2+(B(a)-R(a))./delta(a);
a=chromatic & B==mx;
h(a)=4+(R(a)-G(a))./delta(a);
T.RawHue=mod(h/6,1);
T.RawSaturation=zeros(height(T),1);
a=mx>1e-4;
T.RawSaturation(a)=delta(a)./mx(a);
T.RawLightness=(mx+mn)/2;

[conditionNames,~,group]=unique(T.Condition);
calMin=splitapply(@min,T.LightnessLogged,group);
calMax=splitapply(@max,T.LightnessLogged,group);
rawMin=splitapply(@min,T.RawLightness,group);
rawMax=splitapply(@max,T.RawLightness,group);
T.CalLMin=calMin(group); T.CalLMax=calMax(group);
T.RawLMin=rawMin(group); T.RawLMax=rawMax(group);
T.CalLNorm=normalizeL(T.LightnessLogged,T.CalLMin,T.CalLMax);
T.RawLNorm=normalizeL(T.RawLightness,T.RawLMin,T.RawLMax);
T.CalZ=2*T.CalLNorm-1;
T.CalRadius=(1-abs(T.CalZ)).*T.SaturationLogged;
T.CalX=T.CalRadius.*cos(2*pi*T.HueWrapped);
T.CalY=T.CalRadius.*sin(2*pi*T.HueWrapped);
T.RawZ=2*T.RawLNorm-1;
T.RawRadius=(1-abs(T.RawZ)).*T.RawSaturation;
T.RawX=T.RawRadius.*cos(2*pi*T.RawHue);
T.RawY=T.RawRadius.*sin(2*pi*T.RawHue);

N=splitapply(@numel,T.Correct,group);
Correct=splitapply(@sum,T.Correct,group);
Conditions=table(conditionNames,N,Correct,Correct./N,calMin,calMax,rawMin,rawMax, ...
    'VariableNames',{'Condition','N','Correct','Accuracy', ...
    'CalLMin','CalLMax','RawLMin','RawLMax'});
assert(all(hypot(T.CalX,T.CalY)<=1-abs(T.CalZ)+1e-10), ...
    'Calculated calibrated coordinates are outside the bicone.');
end

function L=normalizeL(value,lo,hi)
span=hi-lo;
L=0.5*ones(size(value));
a=span>0;
L(a)=(value(a)-lo(a))./span(a);
if any(~a)
    warning('ChromaClimber:ConstantLightness', ...
        'A condition has constant lightness; its plotting lightness is set to 0.5.');
end
end
