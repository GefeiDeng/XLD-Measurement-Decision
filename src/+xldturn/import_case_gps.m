function [tracks,summary]=import_case_gps(cfg)
% Import the seven unfiltered, full-precision daily raw GPS records.
files=dir(fullfile(cfg.Root,'data','raw','gps','*.mat'));
assert(numel(files)==7,'Exactly seven raw study days are required.');
outdir=fullfile(cfg.ResultDir,'rebuilt_gps');if ~isfolder(outdir),mkdir(outdir);end
tracks=cell(7,1);rows=cell(7,1);
for i=1:7
 s=load(fullfile(files(i).folder,files(i).name),'rawDay');r=s.rawDay;
 [tracks{i},audit]=xldturn.prepare_gps(r,cfg);rows{i}=struct2table(audit);
 writetable(tracks{i},fullfile(outdir,sprintf('%s_%d_track.csv',lower(r.Dataset),r.DateKey)));
end
summary=vertcat(rows{:});writetable(summary,fullfile(cfg.ResultDir,'raw_gps_preprocessing.csv'));
end
