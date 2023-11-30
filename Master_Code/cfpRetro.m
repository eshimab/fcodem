function contable=cfpRetro(loadstring,filenameis)
% Written by Eric Shimabukuro
% reads in .xml files and converts the configuration files into a matlab table
% This is an older version of cfpNano.





fid = fopen(loadstring);
% ----------------- Loop Init -------------------
tline = fgetl(fid);
idxline = 1;
linecells{idxline} = tline;
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
% ----------------- Replace weird tab chars with spaces -------------------
linecells = cellfun(@(CELLSTR) char(double(uint8(CELLSTR ~= 9)) .* double(uint8(CELLSTR)) + double(uint8(CELLSTR == 9)) .* 32),linecells,'UniformOutput',false);
% ----------------- Get Voltage Numbers -------------------
indexVoltageStart = cellfun(@(CELLSTR) ~isempty(regexp(CELLSTR,'(<voltage>)','match')),linecells);
  idxVoltageStart = linenums(indexVoltageStart);
indexVoltageEnd   = cellfun(@(CELLSTR) ~isempty(regexp(CELLSTR,'(</voltage>)','match')),linecells);
  idxVoltageEnd   = linenums(indexVoltageEnd);
idxVoltageChunk   = (idxVoltageStart:idxVoltageEnd)';
% ----------------- Get specific <name> or <index> strings -------------------
indexName = cellfun(@(CELLSTR) ~isempty(regexp(CELLSTR,'(?<=<name>)([a-zA-Z0-9]|_|"|=|\s|\/|\(|\))*(?=<\/name>)','match')),linecells);
  idxName = linenums(indexName);
  idxName(contains(linecells(idxName),'(671)')) = [];
  nameCells = cellfun(@(CELLSTR) char(regexp(CELLSTR,  '(?<=<name>)([a-zA-Z0-9]|_|"|=|\s|\/|\(|\))*(?=<\/name>)','match')),linecells(idxName),'UniformOutput',false); % Names of Channels
  configIDs = cellfun(@(CELLSTR) str2double(char(regexp(CELLSTR,'(?<=>)([0-9])(?=<\/)','match'))),linecells(idxName+2),'UniformOutput',false); % Channel <index> is 2 lines down
indexIndex = cellfun(@(CELLSTR) ~isempty(regexp(CELLSTR,'(?<=<index>)([0-9]*)(?=<\/index>)','match')),linecells);
  idxIndex = linenums(indexIndex);
  idxIndex = idxIndex(ismember(idxIndex,idxName - 1)); % Get <index> numbers that are assoc. with target channels
% ----------------- Get PMTs that are powered on -------------------
indexPowerStart = cellfun(@(CELLSTR) ~isempty(regexp(CELLSTR,'(<power>)','match')),linecells);
  idxPowerStart = linenums(indexPowerStart);
indexPowerEnd = cellfun(@(CELLSTR) ~isempty(regexp(CELLSTR,'(</power>)','match')),linecells);
  idxPowerEnd = linenums(indexPowerEnd);
idxPowerChunk = (idxPowerStart:idxPowerEnd)';
% ----------------- Get Items -------------------
indexItem = cellfun(@(CELLSTR) ~isempty(regexp(CELLSTR,'(?<=<item>)([0-9]*)(?=<\/item>)','match')),linecells);
  idxItem = linenums(indexItem);
% -----------------  -------------------
idxItemPower   = idxItem(ismember(idxItem,idxPowerChunk));  % Items within the <power> </power> chunk
indexPowerNums = cellfun(@(CELLSTR) str2double(char(regexp(CELLSTR,'(?<=<item>)([0-9]*)(?=<\/item>)','match'))),linecells(idxItemPower)) == 1;
% ----------------- Voltage (Gains) -------------------
idxItemVoltage = idxItem(ismember(idxItem,idxVoltageChunk));
voltCells = cellfun(@(CELLSTR) str2double(char(regexp(CELLSTR,'(?<=<item>)([0-9]*)(?=<\/item>)','match')))/20,linecells(idxItemVoltage(indexPowerNums)),'UniformOutput',false);
% ----------------- Get Trigger -------------------
indexTriggerStart = cellfun(@(CELLSTR) ~isempty(regexp(CELLSTR,'(?<=<trigger\s)([a-zA-Z0-9]|_|"|=|\s)*(?=>)','match')),linecells);
  idxTriggerStart = linenums(indexTriggerStart);
indexTriggerEnd = cellfun(@(CELLSTR) ~isempty(regexp(CELLSTR,'(</trigger>)','match')),linecells);
  idxTriggerEnd = linenums(indexTriggerEnd);
idxTriggerChunk = (idxTriggerStart:idxTriggerEnd)';
indexThresh = cellfun(@(CELLSTR) ~isempty(regexp(CELLSTR,'(?<=<threshold>)([0-9a-zA-Z\/\(\)]*)(?=<\/threshold>)','match')),linecells);
  idxThresh = linenums(indexThresh);
  triglvl  = cell2mat(regexp(linecells(idxThresh(1)),'[0-9]*'));
  trigchan = cell2mat(regexp(linecells(idxThresh(1)+10),'[0-9]'));
% ----------------- Make table -------------------
contable = cell2table([{filenameis} {'primary'} NaN() voltCells(1:5)' {triglvl} {trigchan} configIDs(1:5)' {NaN NaN} nameCells(1:5)' ]);
contable.Properties.VariableNames = { 'configfile' 'fcsfile' 'tube_num' 'fsc488' 'ssc488' 'red488' 'grn488' 'org488' 'trig_lvl' 'trig_idx' 'fsc_idx' 'ssc_idx' 'red_idx' 'grn_idx' 'org_idx' 'tube_startline' 'tube_endline' 'fsc_chn' 'ssc_chn' 'red_chn' 'grn_chn' 'org_chn'};

return
