% This code is designed to process FCM data that has already been processed in FlowJo. 
%
% When run from the folder "Master_Code", this code will prompt for a
% folder. The code will go a maximum of two directories inwards to find any
% folders labeled as HOT#, with no underscores. For example, in the below
% path, the FCM directory would not be valid, while all later folders are.
% FCM\HOT_FCM\HOT_2021_326_to_334\HOT327
%
% If running a non-HOT cruise, ensure that the folders and files listed 
% below are listed in the folder selected. This will override the earlier
% checks, which are looking for HOT folder formatting.
%
% All HOT# folders that contain the following dependencies and have not been 
% been processed previously will be processed. If a folder has been
% previously processed, this program will check line by line to determine
% whether the code has been altered. If the copied code is unaltered and
% the output of a specific code exists, that portion of the code will not
% be rerun.
%
% If changes have been made, the user will be prompted whether they would
% like to reprocess the cruise. Pressing yes will archive all data and
% process the new data. Pressing no will skip the cruise.
%
% This code assumes that the following folders and files exist within a cruise folder:
% *_CONFIG -> Inside should be .xml files
% *_FCS -> Inside should be .fcs files
% *.wsp -> in main folder, the FlowJo workspace file
% *.xlsx -> spreadsheet which should contain a sheet labelled 'fcsinfo',
%           pairing .xml and .fcs files.
%
% The output files of this program will be in *_MAT.
% All code used to create the output will be archived in *_MFILES.
%
% Written by Eric Shimabukuro, Andrew Hirzel, 2023


% 0--------------------------------------0
% | OVERRIDE - REPROCESS ALL DATA SWITCH |
% 0--------------------------------------0
% Behavior: 
% 0 = Off, skip to next step
% 1 = On, reprocess data for this step (old files will be archived)
% 2 = On, overwrite data
% -1 = Ask before reprocessing (choices to each existing file: SKIP, ARCHIVE, or OVERWRITE)
overrideswitch = 2;


% First establish where the code is being run from:
mfilepath = mfilename('fullpath');
if contains(mfilepath,'LiveEditorEvaluationHelper')
    mfilepath = matlab.desktop.editor.getActiveFilename;
end
[rootpath,mfiledir,~]=fileparts(fileparts(mfilepath));
% Determine if archived code or master code:
if strcmp(mfiledir,'Master_Code'),mcchk=true;
else,mcchk=false;end
mfilepath=[rootpath filesep mfiledir];
cd(mfilepath);%Change directory to prioritize present code
% Prompt for target folder location:
userpath = uigetdir(rootpath);
if userpath == 0,error('No folder selected');end
% Check to determine where the target folder is:
dirpath={};
dirname={};%Assume folder name is the cruise
[tmpdp,tmpdn]=HasDependencies(userpath);
if ~isempty(tmpdp),dirpath(end+1,1)=tmpdp;end
if ~isempty(tmpdn),dirname(end+1,1)=tmpdn;end
tmp1=dir(userpath);
for i=3:size(tmp1,1)
    if tmp1(i).isdir
        [tmpdp,tmpdn]=HasDependencies([userpath filesep tmp1(i).name]);
        if ~isempty(tmpdp),dirpath(end+1,1)=tmpdp;end
        if ~isempty(tmpdn),dirname(end+1,1)=tmpdn;end
        tmp2=dir([userpath filesep tmp1(i).name]);
        for j=3:size(tmp2,1)
            if tmp2(j).isdir
                [tmpdp,tmpdn]=HasDependencies([userpath filesep tmp1(i).name filesep tmp2(j).name]);
                if ~isempty(tmpdp),dirpath(end+1,1)=tmpdp;end
                if ~isempty(tmpdn),dirname(end+1,1)=tmpdn;end
            end
        end
    end
end
clear rootpath mfiledir userpath i j tmp1 tmp2 tmpdp tmpdn;
if isempty(dirpath),error('No folders containing all dependencies were detected'),end

%Loop over all valid cruises
for i=1:size(dirpath,1)
    path=dirpath{i,1};
    cruise=dirname{i,1};
    % Create output directories:
    if ~exist([path filesep cruise '_MAT'],'dir'),mkdir([path filesep cruise '_MAT']);end
    if ~exist([path filesep cruise '_MFILES'],'dir'),mkdir([path filesep cruise '_MFILES']);end
    cd([path filesep cruise '_MFILES']);%Force all codes to run local, copy from master first
    % Check if output already exists:
    tmpswitch=overrideswitch;
    if exist([path filesep cruise '_MAT' filesep cruise '_meantab.mat'],'file') && exist([path filesep cruise '_MAT' filesep cruise '_HOT_DOGS.xlsx'],'file') && tmpswitch<0
        tmpswitch = GetSwitch(overrideswitch,'true',[cruise '_meantab.mat and ' cruise '_HOT_DOGS.xlsx']);
        if tmpswitch == 0,tmpswitch=-2;end %Bypass all later code if skip detected
        if tmpswitch == 1 %Archive all output
            if ~exist([path filesep cruise '_ARCHIVED_MAT'],'dir'),mkdir([path filesep cruise '_ARCHIVED_MAT']);end
            tmp=dir([path filesep cruise '_MAT' filesep cruise '_extab.mat']);
            if ~isempty(tmp) %If extab is missing, assume there is no data in folder, since it is the first file made
                tmp=datestr(tmp.date);tmp=tmp(1:11);%Get file creation date
                movefile([path filesep cruise '_MAT'],[path filesep cruise '_ARCHIVED_MAT' filesep 'ARCHIVED_FILES' filesep cruise '_MAT_' tmp]);% Copy entire folder
                mkdir([path filesep cruise '_MAT']);
            end
        end
            
    end
    if tmpswitch~=-2
        % skipbypass detects if any files were replaced. If so, rerun everything. If not, recreate anything missing.
        [~]=WhichCode(mcchk,mfilepath,[path filesep cruise '_MFILES'],'aln.m',overrideswitch);
        [~]=WhichCode(mcchk,mfilepath,[path filesep cruise '_MFILES'],'cfpNano.m',overrideswitch);
        [~]=WhichCode(mcchk,mfilepath,[path filesep cruise '_MFILES'],'cfpRetro.m',overrideswitch);
        [~]=WhichCode(mcchk,mfilepath,[path filesep cruise '_MFILES'],'fjpMicro.m',overrideswitch);
        [~]=WhichCode(mcchk,mfilepath,[path filesep cruise '_MFILES'],'fppMicro.m',overrideswitch);
        [~]=WhichCode(mcchk,mfilepath,[path filesep cruise '_MFILES'],'fca_readfcs.m',overrideswitch);%fppMicro dependency
        [~]=WhichCode(mcchk,mfilepath,[path filesep cruise '_MFILES'],'fpnMini.m',overrideswitch);
        [~]=WhichCode(mcchk,mfilepath,[path filesep cruise '_MFILES'],'ftnMini.m',overrideswitch);
        [~]=WhichCode(mcchk,mfilepath,[path filesep cruise '_MFILES'],'make_excel.m',overrideswitch);
        % All code has been selected, process output
        
        % Archive old output if requested
        if tmpswitch == 1 %Archive all output
            if ~exist([path filesep cruise '_ARCHIVED_MAT'],'dir'),mkdir([path filesep cruise '_ARCHIVED_MAT']);end
            tmp=dir([path filesep cruise '_MAT' filesep cruise '_extab.mat']);
            if ~isempty(tmp) %If extab is missing, assume there is no data in folder, since it is the first file made
                tmp=datestr(tmp.date);tmp=tmp(1:11);%Get file creation date
                movefile([path filesep cruise '_MAT'],[path filesep cruise '_ARCHIVED_MAT' filesep 'ARCHIVED_FILES' filesep cruise '_MAT_' tmp]);% Copy entire folder
                mkdir([path filesep cruise '_MAT']);
            end
            clear tmp;
        end
        
        % Load Excel File (.xlsx)
        try
            opts = detectImportOptions([path filesep cruise '.xlsx'],'Sheet','fcsinfo');
            opts.DataRange = 'A21';
            opts.VariableNamesRange = 'A20';
            opts.VariableNamingRule = 'preserve';
            % opts.('VariableNamingRule') = 'A2';
            extab = readtable([path filesep cruise '.xlsx'],opts); % Complains about using dash in var names. MATLAB is okay with that now
            extab(~strcmpi(extab{:,'project'},'HOT'),:) = []; % Remove non-HOT fcs files
            if ~isa(extab{4,'cast'},'double'),extab=convertvars(extab,'cast','string');extab=convertvars(extab,'cast','double');end%Since they import wrong occasionally, probably a space or something
            if ~isa(extab{4,'btl'},'double'),extab=convertvars(extab,'btl','string');extab=convertvars(extab,'btl','double');end
            save([path filesep cruise '_MAT' filesep cruise '_extab.mat'],'extab','-v7.3')
            clear opts;
            disp([char(datetime('now','Format','HH:mm')) ' - ' cruise '.xlsx was successfully loaded and saved']);
        catch
            error(['Excel file (' cruise '.xlsx) missing, fcsinfo sheet not found, or fcsinfo sheet failed to load']);
        end
        
        % Create contab and contable files from individual .xml configuration files, using fcpNano and fcpRetro
        if ~exist([path filesep cruise '_MAT' filesep 'CFP'],'dir'),mkdir([path filesep cruise '_MAT' filesep 'CFP']);end
        dirAllXmls = dir([path filesep cruise '_CONFIG' filesep '*.xml']);
        for idxfile = 1:length(dirAllXmls)
            try
                contable=cfpNano([dirAllXmls(idxfile).folder filesep dirAllXmls(idxfile).name],dirAllXmls(idxfile).name);
            catch
                contable=cfpRetro([dirAllXmls(idxfile).folder filesep dirAllXmls(idxfile).name],dirAllXmls(idxfile).name);
            end
            if ~exist('contab','var'),contab = contable;
            else,contab = vertcat(contab,contable);end
            save([path filesep cruise '_MAT' filesep 'CFP' filesep cruise '_contable_' dirAllXmls(idxfile).name ' .mat'],'contable','-v7.3');
        end
        save([path filesep cruise '_MAT' filesep cruise '_contab.mat'],'contab','-v7.3');
        clear dirAllXmls contable;
        disp([char(datetime('now','Format','HH:mm')) ' - ' cruise ' configurations have been successfully loaded and saved']);
        
        % Parse FlowJo workspace (.wsp) using fjpMicro and fppMicro
        if ~exist([path filesep cruise '_MAT' filesep 'FJP'],'dir'),mkdir([path filesep cruise '_MAT' filesep 'FJP']);end
        if ~exist([path filesep cruise '_MAT' filesep 'FPP'],'dir'),mkdir([path filesep cruise '_MAT' filesep 'FPP']);end
        %fjpMicro
        [fcstab,gatetab,poptab]=fjpMicro([path filesep cruise '.wsp']);
        save([path filesep cruise '_MAT' filesep 'FPP' filesep cruise '_fcstab.mat'],'fcstab','-v7.3');
        save([path filesep cruise '_MAT' filesep 'FPP' filesep cruise '_gatetab.mat'],'gatetab','-v7.3');%Is not affected by fppMicro
        if ~exist('contab','var'),contab=load([path filesep cruise '_MAT' filesep cruise '_contab.mat']);end
        if ~exist('extab','var'),contab=load([path filesep cruise '_MAT' filesep cruise '_extab.mat']);end
        %fppMicro
        [fullmat,fulltab,poptab,fcsdat,fcsmet,idxmat]=fppMicro(contab,extab,fcstab,gatetab,poptab,[path filesep cruise '_FCS'],[path filesep cruise '_MAT']);
        save([path filesep cruise '_MAT' filesep cruise '_fullmat.mat'],'fullmat','-v7.3');
        save([path filesep cruise '_MAT' filesep cruise '_fulltab.mat'],'fulltab','-v7.3');
        save([path filesep cruise '_MAT' filesep 'FPP' filesep cruise '_poptab.mat'],'poptab','-v7.3');%appended in fppMicro 
        save([path filesep cruise '_MAT' filesep 'FPP' filesep cruise '_fcsdat.mat'],'fcsdat','-v7.3');
        save([path filesep cruise '_MAT' filesep 'FPP' filesep cruise '_fcsmet.mat'],'fcsmet','-v7.3');
        save([path filesep cruise '_MAT' filesep 'FPP' filesep cruise '_idxmat.mat'],'idxmat','-v7.3');
        %Separate based on whether samples were on station
        [unids, idxuni, ~] = unique(fulltab{:,'sample_id'},'stable');
        fcstab(~ismember(fcstab{:,'sample_id'},unids),:) = [];
        fcstab{:,'tx'} =  fulltab{idxuni,'tx'};
        % Separate tx, I see no reason to retain this information and have thus removed it.
        %{
        unstab = fulltab(fulltab{:,'tx'} == 1,:);
        stntab = fulltab(fulltab{:,'tx'} == 2,:);
        % tabmatch = height(unstab) + height(stntab) == height(fulltab); %Sanity Check
        save([path filesep cruise '_MAT' filesep 'FPP' filesep cruise '_stntab.mat'],'stntab','-v7.3');
        save([path filesep cruise '_MAT' filesep 'FPP' filesep cruise '_unstab.mat'],'unstab','-v7.3');
        %}
        save([path filesep cruise '_MAT' filesep cruise '_fcstab_cropped.mat'],'fcstab','-v7.3');
        clear fcsdat fcsmet idxmat unids idxuni;
        disp([char(datetime('now','Format','HH:mm')) ' - ' cruise ' FlowJo workspace has been successfully loaded, processed, and saved']);
        
        % Plotting
        if ~exist([path filesep cruise '_MAT' filesep 'FIG'],'dir'),mkdir([path filesep cruise '_MAT' filesep 'FIG']);end
        if ~exist('fulltab','var'),contab=load([path filesep cruise '_MAT' filesep cruise '_fulltab.mat']);end
        if ~exist('poptab','var'),contab=load([path filesep cruise '_MAT' filesep 'FPP' filesep cruise '_poptab.mat']);end
        fpnMini(fcstab,fulltab,poptab,[path filesep cruise '_FCS'],[path filesep cruise '_MAT']);
        disp([char(datetime('now','Format','HH:mm')) ' - ' 'FCS figure output for ' cruise ' saved successfully'])
        
        % Average results
        [full_fcs_stats]=ftnMini(fulltab,extab,fcstab);
        save([path filesep cruise '_MAT' filesep cruise '_full_fcs.mat'],'full_fcs_stats','-v7.3');
        [excel_1,excel_2]=make_excel(full_fcs_stats);
        writetable(excel_1,[path filesep cruise '_MAT' filesep cruise '_HOT_DOGS.xlsx'],'sheet',['Full Summary - ' cruise],'WriteMode','overwritesheet');
        writetable(excel_2,[path filesep cruise '_MAT' filesep cruise '_HOT_DOGS.xlsx'],'sheet','HOT Summary For Lance','WriteMode','overwritesheet');
        disp([char(datetime('now','Format','HH:mm')) ' - ' cruise '_meantab.mat and ' cruise '_HOT_DOGS.xlsx saved successfully'])
    else
        disp([char(datetime('now','Format','HH:mm')) ' - ' cruise '_meantab.mat and ' cruise '_HOT_DOGS.xlsx exist, skipping based on user preferences']);
    end
    clear path cruise tmpswitch extab contab fcstab gatetab poptab fullmat fulltab full_fcs_stats excel_1 excel_2;
end
cd(mfilepath);%Move to original run location
clear mfilepath dirpath dirname;
disp([char(datetime('now','Format','HH:mm')) ' - '  'All folders have been processed, code complete.']);

%% Check to see folder has all dependencies
function [dirpath,dirname]=HasDependencies(path)
    dirpath={};
    dirname={};
    tmp1=dir([path filesep '*_CONFIG']);%Check for config
    tmp2=dir([path filesep '*_FCS']);%Check for fcs
    if ~isempty(tmp1) && ~isempty(tmp2)
        tmpdp=tmp1(1).folder;
        [~,tmpdn,~]=fileparts(tmpdp);
        tmp1=dir([path filesep '*.wsp']);%Check for .wsp file
        tmp2=dir([path filesep '*.xlsx']);%Check for .xlsx file
        if isempty(tmp1),warning(['.wsp file not found in ' tmpdn]);end
        if isempty(tmp2),warning(['.xlsx file not found in ' tmpdn]);end
        if ~isempty(tmp1) && ~isempty(tmp2)
            dirpath(end+1,1)={tmpdp};
            dirname(end+1,1)={tmpdn};
        end
        clear tmp1 tmp2 tmpdp tmpdn;
    end
end
%% Get switch state, including user prompting
function tmpswitch = GetSwitch(overrideswitch,filefullpath,filemessage)
    tmpswitch = overrideswitch;
    if tmpswitch<0 && (strcmp(filefullpath,'true') || exist(filefullpath,'file'))        
        while ~ismember(tmpswitch,[0,1,2])
            txt = input([filemessage ' already exist(s), would you like to:' char(13) '   1 - Skip this step (1 or SKIP)' char(13) '   2 - Archive and reprocess the file(s) (2 or ARCHIVE)' char(13) '   9 - Overwrite the existing file(s) (9 or OVERWRITE)' char(13) 'Please press enter after typing your selection.' char(13)],'s');
            if strcmp(txt(1),'1') || strcmpi(txt,'skip'),tmpswitch=0;
            elseif strcmp(txt(1),'2') || strcmpi(txt,'archive'),tmpswitch=1;
            elseif strcmp(txt(1),'9') || strcmpi(txt,'overwrite'),tmpswitch=2;
            else,warning('Invalid response detected, please enter a valid response.'),end
        end
    elseif strcmp(filefullpath,'code') %If codes are different, always ask
        while ~ismember(tmpswitch,[0,1])
            warning(['Differences were detected between the master and local copies of ' filemessage])
            txt = input(['Would you like to:' char(13) '   1 - Run the master copy, archiving the local copy (1 or MASTER)' char(13) '   9 - Run the local copy (9 or LOCAL)' char(13) 'Please press enter after typing your selection.' char(13)],'s');
            if strcmp(txt(1),'1') || strcmpi(txt,'master'),tmpswitch=1;
            elseif strcmp(txt(1),'9') || strcmpi(txt,'local'),tmpswitch=0;
            else,warning('Invalid response detected, please enter a valid response.'),end
        end
    else
        tmpswitch = 2;%Ignore archiving and just save
    end
end
%% Archive/Copy code
function skipbypass=WhichCode(mcchk,mfilepath,localpath,filename,overrideswitch)
    skipbypass=0;
    if mcchk && exist([localpath filesep filename],'file')
        % Compare existing code with master code
        % isdiff is the line number of first difference. 
        % For our purposes, isdiff>0 means there are changes.
        isdiff=0;
        mf=fopen([mfilepath filesep filename]);
        lf=fopen([localpath filesep filename]);
        mn='';ln='';k=0;
        while ~isnumeric(mn) && ~isnumeric(ln)
            k=k+1;
            mn=fgetl(mf);
            ln=fgetl(lf);
            if ~strcmp(mn,ln) && (~isnumeric(mn) || ~isnumeric(ln)) %If one goes numeric, the file end was reached.
                isdiff=k;
                break;
            elseif k>1e5 %Sanity check
                isdiff=k;
                break;
            end
        end
        fclose(mf);
        fclose(lf);
        if isdiff>0 %Something has changed, ask then archive if necessary.
            if overrideswitch<=0 %Only ask when not ordered to archive or overwrite (code is always archived)
                tmpswitch = GetSwitch(-20,'code',[filename ' (line ' int2str(isdiff) ')']);
            else,tmpswitch=1;end
            if tmpswitch==1
                if ~exist([localpath filesep 'ARCHIVED_FILES'],'dir'),mkdir([localpath filesep 'ARCHIVED_FILES']);end
                tmp=dir([localpath filesep filename]);tmp=datestr(tmp.date);tmp=tmp(1:11);%Get file creation date
                [~,tmp1,tmp2]=fileparts(filename);
                movefile([localpath filesep filename],[localpath filesep 'ARCHIVED_FILES' filesep tmp1 '_' tmp tmp2]);
                copyfile([mfilepath filesep filename],[localpath filesep filename]);
                clear([localpath filesep filename]);
                skipbypass=1;
            end
        end
    elseif mcchk && ~exist([localpath filesep filename],'file')
        copyfile([mfilepath filesep filename],[localpath filesep filename]);
        clear([localpath filesep filename]);
        skipbypass=1;
    else
        error([filename ' not found']);
    end
end