% RUN_CHROMACLIMBER_BICONE
% Put this script and the other .m files in the extracted bundle folder.
% Click Run. The existing cleaned CSV opens immediately.
base=fileparts(mfilename('fullpath'));
addpath(base);
cleanedCSV=fullfile(base,'ChromaClimber_Cleaned.csv');
if isfile(cleanedCSV)
    plot_chromaclimber_bicone(cleanedCSV);
else
    [T,Conditions]=clean_chromaclimber_logs; %#ok<ASGLU>
    plot_chromaclimber_bicone(T);
end

% To rebuild the cleaned data from the original uploaded workbooks instead:
% [T,Conditions] = clean_chromaclimber_logs;
% plot_chromaclimber_bicone(T);
