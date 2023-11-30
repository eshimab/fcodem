function contable=cfpNano(loadstring,filenameis)
% Written by Eric Shimabukuro
% reads in .xml files and converts the configuration files into a matlab table






fid = fopen(loadstring);
% ----------------- Loop Init -------------------
idxline = 0;
tline = '';
linecells = {''};
% ----------------- Get all lines into Cellstrings -------------------
while ischar(tline)
  tline = fgetl(fid);
  idxline = idxline + 1;
  linecells{idxline} = tline;
end
fclose(fid);
% ----------------- Prep CellStrings -------------------
linecells = reshape(linecells,[],1); % Make Column
linecells = linecells(2:end-1); % Trim first and last lines
linenums = (1:length(linecells))';
% ----------------- Getting  FCS Files -------------------
indexFcsFile = cellfun(@(CELLSTR) ~isempty(regexp(CELLSTR,'(?<=<FCSFile>.*)(([a-zA-Z0-9]|\_|-)*\.fcs)(?=<\/FCSFile>)','match')),linecells);
  idxFcsFileNums = linenums(indexFcsFile);
  % fcsFileCells = cellfun(@(CELLSTR) char(regexp(CELLSTR,'(?<=<FCSFile>.*)(([a-zA-Z0-9]|\_|-)*\.fcs)(?=<\/FCSFile>)','match')),linecells(indexFcsFile),'UniformOutput',false); % Get FCS name strings
  idxvec = idxFcsFileNums; %
% ----------------- Getting Tubes  -------------------
indexTubesStart = cellfun(@(CELLSTR) ~isempty(regexp(CELLSTR,'(?<=<)(Tube)(?=\s)','match')),linecells);
  idxTubesStart = linenums(indexTubesStart);
indexTubesEnd = cellfun(@(CELLSTR) ~isempty(regexp(CELLSTR,'(?<=</)(Tube)(?=>)','match')),linecells);
  idxTubesEnd = linenums(indexTubesEnd);
  idxvec = [idxvec ; idxTubesStart; idxTubesEnd]; %
% ----------------- Compensation ------------------
indexCompensationStart = cellfun(@(CELLSTR) ~isempty(regexp(CELLSTR,'(?<=<)(Compensation)(?=\s)','match')),linecells);
  idxCompensationStart = linenums(indexCompensationStart);
indexCompensationEnd = cellfun(@(CELLSTR) ~isempty(regexp(CELLSTR,'(?<=</)(Compensation)(?=>)','match')),linecells);
  idxCompensationEnd = linenums(indexCompensationEnd);
compensationCells = reshape(arrayfun(@(VEC1,VEC2) [VEC1:VEC2], idxCompensationStart, idxCompensationEnd, 'UniformOutput', false),1,[]);
idxCompensationRange = [compensationCells{:}];
% ----------------- Get Active Channels -------------------
indexNamesFSC = cellfun(@(CELLSTR) ~isempty(regexp(CELLSTR,'(?<=<Name>)(FSC-488)(?=<\/Name>)','match')),linecells);
indexNamesSSC = cellfun(@(CELLSTR) ~isempty(regexp(CELLSTR,'(?<=<Name>)(SSC-488)(?=<\/Name>)','match')),linecells);
indexNamesRED = cellfun(@(CELLSTR) ~isempty(regexp(CELLSTR,'(?<=<Name>)(RED-488\s692\/40)(?=<\/Name>)','match')),linecells);
indexNamesGRN = cellfun(@(CELLSTR) ~isempty(regexp(CELLSTR,'(?<=<Name>)(GRN-488\s542\/27)(?=<\/Name>)','match')),linecells);
indexNamesORG = cellfun(@(CELLSTR) ~isempty(regexp(CELLSTR,'(?<=<Name>)(ORG-488\s585\/40)(?=<\/Name>)','match')),linecells);
indexChannelNames = (indexNamesFSC | indexNamesSSC | indexNamesRED | indexNamesGRN | indexNamesORG );
idxChannelNames = linenums(indexChannelNames);
idxChannelNames = idxChannelNames(~ismember(idxChannelNames,idxCompensationRange)); % Ignore entries in compensation sections
idxvec = [idxvec;idxChannelNames];
% ----------------- Detector Index -------------------
indexDetectors = cellfun(@(CELLSTR) ~isempty(regexp(CELLSTR,'(?<=<DetectorIndex>)([a-zA-Z0-9])*(?=<\/DetectorIndex>)','match')),linecells);
idxDetectors = linenums(indexDetectors);
idxDetectorMini = idxDetectors(ismember(idxDetectors,idxChannelNames + 4) | idxDetectors < idxTubesStart(1));
  idxvec = [idxvec; idxDetectorMini];
% ----------------- Trigger Threshold -------------------
indexTriggerThreshhold = cellfun(@(CELLSTR) ~isempty(regexp(CELLSTR,'(?<=<)(TriggerThreshold)(?=)','match')),linecells);
idxTriggerThreshhold = linenums(indexTriggerThreshhold);
  trigThreshCells = cellfun(@(CELLSTR) str2double(char(regexp(CELLSTR,'(?<=<TriggerThreshold>)([0-9]|.|)*(?=</)','match'))),linecells(indexTriggerThreshhold),'UniformOutput',false);
  idxvec = [idxvec; idxTriggerThreshhold];
% ----------------- Trigger Detector -------------------
indexTriggerChannel = cellfun(@(CELLSTR) ~isempty(regexp(CELLSTR,'(?<=<)(TriggerDetector)(?=)','match')),linecells);
idxTriggerChannel = linenums(indexTriggerChannel);
  trigChanCells = cellfun(@(CELLSTR) str2double(char(regexp(CELLSTR,'(?<=<TriggerDetector>)([0-9]|.|)*(?=</)','match'))),linecells(indexTriggerChannel),'UniformOutput',false);
  idxvec = [idxvec; idxTriggerChannel];
% ----------------- Elimintate Params without PmtVoltage -------------------
indexPmtVoltage = cellfun(@(CELLSTR) ~isempty(regexp(CELLSTR,'(?<=<PmtVoltage>)([0-9]|.)+([0-9]|.)(?=<)','match')),linecells);
idxPmtVoltage = linenums(indexPmtVoltage);
  idxvec = [idxvec;idxPmtVoltage];
% ----------------- Strip idxvec -------------------
idxvec = sort(unique(idxvec,'stable'),'ascend');
idxvecmini = idxvec;
% ----------------- Link Sections to Tubes ------------------- % This is where the magic happens
indexTubeMatch = idxvecmini >= idxTubesStart' & idxvecmini <= idxTubesEnd';
  % indexTubeMatch cols represent the tubes, and rows are the idxnums within that range
% ----------------- Init -------------------
conmat = NaN(width(indexTubeMatch) + 1,12);
concells = repmat({[]},width(indexTubeMatch) + 1,2);
% -----------------  -------------------
for idxfcs = 1:width(indexTubeMatch) + 1
  % ----------------- Init -------------------
  if idxfcs == 1
    % ----------------- First set has no tube (Tube = 0) -------------------
    idxvectiny = idxvecmini(idxvecmini < idxTubesStart(1)); % lines before first tube
    tinycells = linecells(idxvectiny);
    tinynums = (1:length(tinycells));
    funcilMakeMicroCells = @(idx) tinycells(tinynums(idx) + 1 : tinynums(idx) + 2); % Different from the tube sections
  else
    idxvectiny = idxvecmini(indexTubeMatch(:,idxfcs - 1));
    tinycells = linecells(idxvectiny);
    tinynums = (1:length(tinycells));
    funcilMakeMicroCells = @(idx) tinycells(tinynums(idx) + 1);
  end % END IF idxfcs
  % ----------------- Tube Meta -------------------
  conmat(idxfcs,13) = min(idxvectiny);
  conmat(idxfcs,14) = max(idxvectiny);
  % ----------------- Get Main Channels ------------------
  indexFSC = cellfun(@(CELLSTR) ~isempty(regexp(CELLSTR,'(?<=<Name>)(FSC-488)(?=<\/Name>)','match')),tinycells);
  indexSSC = cellfun(@(CELLSTR) ~isempty(regexp(CELLSTR,'(?<=<Name>)(SSC-488)(?=<\/Name>)','match')),tinycells);
  indexRED = cellfun(@(CELLSTR) ~isempty(regexp(CELLSTR,'(?<=<Name>)(RED-488\s692\/40)(?=<\/Name>)','match')),tinycells);
  indexGRN = cellfun(@(CELLSTR) ~isempty(regexp(CELLSTR,'(?<=<Name>)(GRN-488\s542\/27)(?=<\/Name>)','match')),tinycells);
  indexORG = cellfun(@(CELLSTR) ~isempty(regexp(CELLSTR,'(?<=<Name>)(ORG-488\s585\/40)(?=<\/Name>)','match')),tinycells);
  indexCHAN = [indexFSC indexSSC indexRED indexGRN  indexORG];
  % ----------------- Loop thru chans for Voltage (gain) and DetectorIndex -------------------
  for idxch = 1:5
    % ----------------- Get Fluor Channel Gains and Index -------------------
    microcells = funcilMakeMicroCells(indexCHAN(:,idxch));
    conmat(idxfcs,idxch) = str2double(char(regexp(microcells{2},'(?<=<PmtVoltage>)([0-9]|\.)*(?=</PmtVoltage>)','match')));
    conmat(idxfcs,idxch + 7) = str2double(char(regexp(microcells{1},'(?<=<DetectorIndex>)([0-9]|\.)*(?=</DetectorIndex>)','match')));
  end
  % ----------------- Other Props -------------------
  % ----------------- THRESH -------------------
  indexTHRESH = cellfun(@(CELLSTR) ~isempty(regexp(CELLSTR,'(?<=<TriggerThreshold>)([0-9]|\.)*(?=<\/TriggerThreshold>)','match')),tinycells);
  conmat(idxfcs,6) = cellfun(@(CELLSTR) str2double(char(regexp(CELLSTR,'(?<=<TriggerThreshold>)([0-9]|\.)*(?=<\/TriggerThreshold>)','match'))),tinycells(indexTHRESH));
  % ----------------- TRIG -------------------
  indexTRIG = cellfun(@(CELLSTR) ~isempty(regexp(CELLSTR,'(?<=<TriggerDetector>)([0-9])*(?=<\/TriggerDetector>)','match')),tinycells);
  conmat(idxfcs,7) = cellfun(@(CELLSTR) str2double(char(regexp(CELLSTR,'(?<=<TriggerDetector>)([0-9])*(?=<\/TriggerDetector>)','match'))),tinycells(indexTRIG));
  % ----------------- FCSFIle -------------------
  indexFILE = cellfun(@(CELLSTR) ~isempty(regexp(CELLSTR,'(?<=<FCSFile>.*)(([a-zA-Z0-9]|\_|-)*\.fcs)(?=<\/FCSFile>)','match')),tinycells);
  if sum(indexFILE) == 0
    concells(idxfcs,1) = {'primary'};
  else
    concells(idxfcs,1) = cellfun(@(CELLSTR) char(regexp(CELLSTR,'(?<=<FCSFile>.*)(([a-zA-Z0-9]|\_|-)*\.fcs)(?=<\/FCSFile>)','match')),tinycells(indexFILE),'UniformOutput',false);
  end
  concells{idxfcs,2} = idxfcs - 1;
end % ----------------- END FOR: idxfcs -------------------
% ----------------- Make Final Table -------------------
concells = [repmat({filenameis},height(concells),1) concells];
contable = cell2table([concells num2cell(conmat)]);
contable.Properties.VariableNames = { 'configfile' 'fcsfile' 'tube_num' 'fsc488' 'ssc488' 'red488' 'grn488' 'org488' 'trig_lvl' 'trig_idx' 'fsc_idx' 'ssc_idx' 'red_idx' 'grn_idx' 'org_idx' 'tube_startline' 'tube_endline'};
% ----------------- Save Output -------------------
% savestring = [filediris filesep() 'matfiles' filesep() strrep([ 'cfp_' filenameis],'.xml','.mat') ];
% save(savestring,'contable','-v7.3')
% fprintf([newline()' Saving contable output for '  filenameis' newline() newline() '  ' ]);
% --------------------------- END: OF CONFIG PARSE -----------------------------
% Return to cfpMacro
return

% ----------------- Error Check -------------------
% indexTagEnd = cellfun(@(CELLSTR) (strcmp(CELLSTR(2), '/' ) & ~strcmp(CELLSTR(end-1), '/' )), linecells, 'UniformOutput',true);
% indexTagBegin = cellfun(@(CELLSTR) ( ~strcmp(CELLSTR(2), '/')  & ~strcmp(CELLSTR(end-1), '/' )), linecells, 'UniformOutput',true);
% indexTagCont = cellfun(@(CELLSTR) (~strcmp(CELLSTR(2), '/' ) & strcmp(CELLSTR(end-1), '/' )), linecells, 'UniformOutput',true);
% if sum([indexTagCont indexTagBegin indexTagEnd]) == ~length(linecells)
  % return
% end
% ----------------- Build Main Setting Structure -------------------
% indexSettingsStart = cellfun(@(CELLSTR) ~isempty(regexp(CELLSTR,'(?<=<)(Settings)(?=\s)','match')),linecells);
% ----------------- Getting DataSource  -------------------
% indexDataSourceStart = cellfun(@(CELLSTR) ~isempty(regexp(CELLSTR,'(?<=<)(DataSource)(?=\s)','match')),linecells);
% ----------------- EventSource ------------------
% indexEventSourceStart = cellfun(@(CELLSTR) ~isempty(regexp(CELLSTR,'(?<=<)(EventSource)(?=>)','match')),linecells);
% ----------------- Channel Index -------------------
% indexChannelIndex = cellfun(@(CELLSTR) ~isempty(regexp(CELLSTR,'(?<=<)(ChannelIndex>)(?=)','match')),linecells);
% idxChanIndexMini = idxChannelIndex(ismember(idxChannelIndex,idxChannelNames + 10));
% ----------------- Configuration ------------------
% indexConfigurationStart = cellfun(@(CELLSTR) ~isempty(regexp(CELLSTR,'(?<=<)(Configuration)(?=\s)','match')),linecells);
% ----------------- Model (helps debugging) ------------------
% indexModel = cellfun(@(CELLSTR) ~isempty(regexp(CELLSTR,'(?<=<Model>)([a-zA-Z0-9]|\(|\)|\s)*(?=</Model>)','match')),linecells);
% ----------------- Secondary fcs file -------------------
% indexFcsNames = cellfun(@(CELLSTR) ~isempty(regexp(CELLSTR,'(?<=<Name>.*)(([a-zA-Z0-9]|\_|-)*\.fcs)(?=<\/Name>)','match')),linecells);
% ----------------- Find ParameterType == Measured -------------------
% indexParameterType = cellfun(@(CELLSTR) ~isempty(regexp(CELLSTR,'(?<=<ParameterType>)(Measured)(?=<)','match')),linecells);
% ----------------- Get Parameter Start and end tags -------------------
% indexParameterStart = cellfun(@(CELLSTR) ~isempty(regexp(CELLSTR,'(?<=<)(Parameter)(?=>)','match')),linecells);
% Only get <Parameter> if next line is <ParameterType>Measured</>
% idxParamMiniStart = idxParameterStart(ismember(idxParameterStart,idxParamTypeMini - 1));
% ----------------- Get Channel Start and end tags -------------------
% indexChannelStart = cellfun(@(CELLSTR) ~isempty(regexp(CELLSTR,'(?<=<)(Channel)(?=>)','match')),linecells);
  % idxChannelStart = linenums(indexChannelStart); % Only get <Channel> if next line is one of our channels
% idxChanMiniStart = idxChannelStart(ismember(idxChannelStart,idxChannelNames - 1));
% ----------------- Pmt Amp Type -------------------
% indexPmtAmpType = cellfun(@(CELLSTR) ~isempty(regexp(CELLSTR,'(?<=<PmtAmpType>)(Log)(?=<\/PmtAmpType>)','match')),linecells);
% idxPmtAmpType = linenums(indexPmtAmpType);
  % linecells(indexPmtAmpType);
  % idxvec = [idxvec ; idxPmtAmpType]; %
  % idxvec = sort(unique(idxvec,'stable'),'ascend');
% ----------------- Name -------------------
  % indexNamesAll = cellfun(@(CELLSTR) ~isempty(regexp(CELLSTR,'(?<=<Name>)([a-zA-Z0-9]|-|\/|\s|\(|\)|\_)+(?=<\/Name>)','match')),linecells);
  % ----------------- Uni Names -------------------
  % allNameCells = cellfun(@(CELLSTR) char(regexp(CELLSTR,'(?<=<Name>)([a-zA-Z0-9]|-|\/|\s|\(|\)|\_)+(?=<\/Name>)','match')),linecells(indexNamesAll),'UniformOutput',false);
  % [uniNames, idxUniNames, idxAllNames] = unique(allNameCells,'stable');
  % idxAllNameNums = linenums(indexNamesAll);
  % Find <Name>PMT 11</Name>
  % indexNamesPmtEmpty = cellfun(@(CELLSTR) ~isempty(regexp(CELLSTR,'(?<=<Name>)(PMT\s[0-9]+)(?=<\/Name>)','match')),linecells);
  % linecells(indexNamesPmtEmpty); %
  % Find <Name>All Events</Name>
  % indexNamesAllEvents = cellfun(@(CELLSTR) ~isempty(regexp(CELLSTR,'(?<=<Name>)(All\sEvents)(?=<\/Name>)','match')),linecells);
  % linecells(indexNamesAllEvents); %
% ----------------- Pmt Power -------------------
% indexPmtPower = cellfun(@(CELLSTR) ~isempty(regexp(CELLSTR,'(?<=<PmtPower>)(true)(?=<\/PmtPower>)','match')),linecells);
% idxPmtPowerNums = linenums(indexPmtPower);
  % pmtPowerVec = cellfun(@(CELLSTR) strcmpi(char(regexp(CELLSTR,'(?<=<PmtPower>)([a-zA-Z0-9])*(?=<\/PmtPower>)','match')),'true'),linecells(indexPmtPower),'UniformOutput',true);
  % idxvec = [idxvec; idxPmtPowerNums];
  % idxvec = sort(unique(idxvec,'stable'),'ascend');



% -----------------  -------------------
