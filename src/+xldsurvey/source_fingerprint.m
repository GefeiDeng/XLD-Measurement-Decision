function fingerprint = source_fingerprint(cfg)
%SOURCE_FINGERPRINT Hash code/input content + numerical settings for safe resume.
md=java.security.MessageDigest.getInstance('SHA-256');
% Hash MAT values rather than binary MAT headers: their timestamps change
% when stage 1/2 rewrites identical inputs during a resumed run_all.
files=string(cfg.DEMFile);
code=dir(fullfile(cfg.Root,'src','**','*.m'));files=[files;string(fullfile({code.folder},{code.name}))'];
for file=reshape(sort(files),1,[])
    fid=fopen(file,'rb');assert(fid>=0);cleaner=onCleanup(@()fclose(fid));
    while ~feof(fid),chunk=fread(fid,1024*1024,'*uint8');md.update(typecast(chunk,'int8'));end
    clear cleaner
end
channel=load(cfg.ChannelFile,'channelModel');
md.update(typecast(uint8(unicode2native(jsonencode(channel.channelModel),'UTF-8')),'int8'));
platforms=load(cfg.ModelFile,'Models');
for k=1:numel(platforms.Models)
 model=platforms.Models{k};p=model.Processing;
 fields=intersect(fieldnames(p),{'Root','TrackDir','ResultDir','FigureDir'});
 model.Processing=rmfield(p,fields);
 md.update(typecast(uint8(unicode2native(jsonencode(model),'UTF-8')),'int8'));
end
settings=rmfield(cfg,{'Root','DEMFile','ChannelFile','ModelFile','ResultDir','FigureDir', ...
 'ResumeCompletedCases','CaseIndices','PlotRasterStride','VerifyGeometryReference'});
md.update(typecast(uint8(unicode2native(jsonencode(settings),'UTF-8')),'int8'));
fingerprint=lower(reshape(dec2hex(typecast(md.digest(),'uint8'),2)',1,[]));
end
