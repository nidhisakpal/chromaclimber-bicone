function [T, Conditions] = clean_chromaclimber_logs(inputFiles, outputDir)
%CLEAN_CHROMACLIMBER_LOGS Convert the original wide log sheets to tidy rows.
% Usage:
%   [T,Conditions] = clean_chromaclimber_logs;
%   [T,Conditions] = clean_chromaclimber_logs(fileList,outputFolder);
%
% Defaults to the original workbooks in ./input_workbooks. When that folder
% is absent, a file picker opens. Requires MATLAB with readcell/sheetnames
% (R2019b or later). No third-party toolbox is required.
%
% Only sheets named 60/300/600_lights_on/off are parsed. The hex code above
% each log column supplies the intended color. Sheet2 is an excluded copied
% template, not additional data. Identical repeated samples are RETAINED.
% Original workbooks are never edited. Output CSV/XLSX files are snapshots.

base=fileparts(mfilename('fullpath'));
if nargin<1 || isempty(inputFiles)
    folder=fullfile(base,'input_workbooks');
    listing=dir(fullfile(folder,'*.xlsx'));
    if isempty(listing)
        [f,p]=uigetfile('*.xlsx','Select the three original RGB workbooks', ...
            'MultiSelect','on');
        if isequal(f,0), error('No input workbooks were selected.'); end
        inputFiles=fullfile(string(p),string(f));
    else
        inputFiles=fullfile(string(folder),string({listing.name}));
    end
end
inputFiles=string(inputFiles);
inputFiles=inputFiles(:);
if nargin<2 || isempty(outputDir), outputDir=fullfile(base,'matlab_output'); end
outputDir=char(outputDir);
if ~isfolder(outputDir), mkdir(outputDir); end

names=["Black";"White";"Red";"Yellow";"Green";"Cyan";"Blue";"Magenta"];
hexes=["#000000";"#FFFFFF";"#FF0000";"#FFFF00";"#00FF00";"#00FFFF";"#0000FF";"#FF00FF"];
variables={'Room','Integration_ms','AmbientLight','TrueColor','TrueHex', ...
    'TrueIndex','SampleInBlock','RawR','RawG','RawB','RawClear', ...
    'HueLogged','LightnessLogged','SaturationLogged','CalClearLogged', ...
    'PredictedIndex','SourceFile','SourceSheet','SourceCell','RawRecord'};
values=cell(0,numel(variables));
roomsSeen=strings(0,1);

for f=1:numel(inputFiles)
    file=inputFiles(f);
    assert(isfile(file),'Cannot find input workbook: %s',file);
    [~,stem,ext]=fileparts(file); basename=stem+ext;
    if contains(lower(stem),'gitc')
        room="GITC Lecture Hall";
    elseif contains(lower(stem),'meche')
        room="MECHE Lecture Hall";
    elseif contains(lower(stem),'swissler')
        room="Swissler Lab";
    else
        error('Unrecognized room in filename %s. Supply GITC, MECHE or Swissler files.',basename);
    end
    assert(~any(roomsSeen==room), ...
        'More than one workbook was selected for %s. Select only the intended version.',room);
    roomsSeen(end+1,1)=room;
    sheets=sheetnames(file);
    nBefore=size(values,1);
    for si=1:numel(sheets)
        sheet=sheets(si);
        token=regexp(char(sheet),'^(60|300|600)_lights_(on|off)$','tokens','once');
        if isempty(token), continue; end
        integration=str2double(token{1}); ambient=string(token{2});
        % Explicit origin preserves Excel source-cell coordinates, including
        % sheets where the first color column begins at C rather than A.
        cells=readcell(file,'Sheet',sheet,'Range','A1');
        assert(~isempty(cells),'The expected log sheet %s is empty.',sheet);
        for col=1:size(cells,2)
            header=upper(strtrim(textCell(cells{1,col})));
            truePosition=find(hexes==header,1);
            count=0;
            for row=2:size(cells,1)
                line=strtrim(textCell(cells{row,col}));
                if ~startsWith(line,"C,"), continue; end
                assert(~isempty(truePosition), ...
                    'Log without an exact-column color header: %s %s column %d.',basename,sheet,col);
                fields=split(line,",");
                assert(numel(fields)==10, ...
                    'Expected C plus nine numbers: %s %s row %d.',basename,sheet,row);
                nums=str2double(fields(2:end));
                assert(all(isfinite(nums)) && ismember(nums(9),0:7), ...
                    'Invalid numeric log record: %s %s row %d.',basename,sheet,row);
                count=count+1;
                record={room,integration,ambient,names(truePosition),hexes(truePosition), ...
                    truePosition-1,count,nums(1),nums(2),nums(3),nums(4),nums(5), ...
                    nums(6),nums(7),nums(8),nums(9),basename,sheet, ...
                    string(excelColumn(col))+string(row),line};
                values(end+1,:)=record; %#ok<AGROW>
            end
        end
    end
    assert(size(values,1)>nBefore,'No valid color log rows were found in %s.',file);
end
assert(~isempty(values),'No valid log data were found.');
T=cell2table(values,'VariableNames',variables);
textFields={'Room','AmbientLight','TrueColor','TrueHex','SourceFile','SourceSheet','SourceCell','RawRecord'};
for i=1:numel(textFields), T.(textFields{i})=string(T.(textFields{i})); end
T=sortrows(T,{'Room','Integration_ms','AmbientLight','TrueIndex','SampleInBlock'});
T.RecordID=(1:height(T))';
[T,Conditions]=chromaclimber_coordinates(T);

N=zeros(8,1); Correct=zeros(8,1);
for i=1:8
    a=T.TrueIndex==i-1; N(i)=sum(a); Correct(i)=sum(T.Correct(a));
end
Accuracy=table(names,(0:7)',N,Correct,Correct./N, ...
    'VariableNames',{'TrueColor','TrueIndex','N','Correct','Accuracy'});
Metadata=table(["Input interpretation";"Excluded sheet";"Calibration";"Normalization"; ...
    "Precision";"Raw representation";"Scope"], ...
    ["Room labels follow input filenames, not the copied template."; ...
    "Sheet2 is a duplicated template; its room/projector metadata is not used."; ...
    "Logged H/L/S is preserved. The missing 50-sample calibration references are not reconstructed."; ...
    "Min-max lightness within room x lights x integration, using all eight colors."; ...
    "Decimal outputs have two-digit precision. Final labels are taken from the logged indices."; ...
    "Derived from raw RGB in these same runs; not an independent pre-calibration experiment."; ...
    "These workbooks do not contain the original 13-classroom data."], ...
    'VariableNames',{'Topic','Description'});

xlsx=fullfile(outputDir,'ChromaClimber_Cleaned_MATLAB.xlsx');
csvfile=fullfile(outputDir,'ChromaClimber_Cleaned_MATLAB.csv');
if isfile(xlsx), delete(xlsx); end % Only a generated output, never an input.
writetable(T,xlsx,'Sheet','Readings');
writetable(Conditions,xlsx,'Sheet','Conditions');
writetable(Accuracy,xlsx,'Sheet','Accuracy');
writetable(Metadata,xlsx,'Sheet','Method');
writetable(T,csvfile);
fprintf('Parsed %d samples from %d environments. Logged accuracy: %.2f%%.\n', ...
    height(T),numel(unique(T.Room)),100*mean(T.Correct));
fprintf('Cleaned outputs: %s\n',outputDir);
end

function s=textCell(v)
if ischar(v) || (isstring(v) && isscalar(v))
    s=string(v); if ismissing(s), s=""; end
else
    s="";
end
end

function s=excelColumn(n)
s='';
while n>0
    r=mod(n-1,26); s=[char(65+r),s]; %#ok<AGROW>
    n=floor((n-1)/26);
end
end
