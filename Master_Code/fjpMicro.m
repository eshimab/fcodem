function [fcstab,gatetab,poptab]=fjpMicro(wspfile)
% Written by Eric Shimabukuro



% ----------------- fjpMicro -------------------
%   Process FlowJo WSP Files into MATLAB tbles.
%   Outputs:
%     gatetab - {'sample_id' 'popnum' 'xline' 'yline' 'x_point' 'y_point'};
%       xvec anc yvec for inddividual gates,


fid = fopen(wspfile);
linecells = {''};
idxline = 0;
tline = '';
% ----------------- Parse XML -------------------
while ischar(tline)
  tline = fgetl(fid);
  idxline = idxline + 1;
  linecells{idxline} = tline;
end
fclose(fid);
% ----------------- Prep CellStrings -------------------
linecells = reshape(linecells,[],1);
linestring = linecells{1};
% linecells = linecells(2:end-1); %  last line
linecells = linecells(2:end-1); % Trim first and last lines
% linecells = linecells(1 : end-1); % Trimlast lines
% levelVector = cellfun(@(CELLSTR) min(strfind(CELLSTR,'<') - 1) ,linecells(2:end-1) ,'UniformOutput' ,true);
indexTagEnd = cellfun(@(CELLSTR) (strcmp(CELLSTR(2), '/' ) & ~strcmp(CELLSTR(end-1), '/' )), linecells, 'UniformOutput',true);
indexTagBegin = cellfun(@(CELLSTR) ( ~strcmp(CELLSTR(2), '/')  & ~strcmp(CELLSTR(end-1), '/' )), linecells, 'UniformOutput',true);
indexTagCont = cellfun(@(CELLSTR) (~strcmp(CELLSTR(2), '/' ) & strcmp(CELLSTR(end-1), '/' )), linecells, 'UniformOutput',true);
if sum([indexTagCont indexTagBegin indexTagEnd]) == ~length(linecells)
  printreport(['Failed to get tag counts correct. Returning'],'warnOn');
  return
end
% ----------------- Init -------------------
linenums = [1:length(linecells)]';
idxEmpty = zeros(size(linecells));
% ----------------- Workspace and flowjo Version -------------------
indexTargetString = cellfun(@(CELLSTR) contains(CELLSTR,'Workspace'), linecells, 'UniformOutput',true);
if sum(indexTargetString & indexTagBegin) ~= 0
  linestring = linecells{indexTargetString & indexTagBegin};
end
% ----------------- Workspace -------------------
workspaceVersionString = char(regexp(linestring,'(?<=\s*version=")([0-9]|\.)*(?=")','match'));
wsVerCells = strsplit(workspaceVersionString,'.');
wsverVec = [str2double(wsVerCells{1}) str2double(wsVerCells{2}) 0];
% ----------------- FlowJo -------------------
flowjoVersionString = char(regexp(linestring,'(?<=flowJoVersion=")([0-9]|\.)*(?=")','match'));
fjVerCells = strsplit(flowjoVersionString,'.');
fjverVec = [str2double(fjVerCells{1}) str2double(fjVerCells{2}) str2double(fjVerCells{3})];
% ----------------- FCS Filenames -------------------
indexSampleNode = cellfun(@(CELLSTR) ~isempty(regexp(CELLSTR,'(?<=<)(SampleNode)(?=\s)','match')),linecells);
fullUriCells = cellfun(@(CELLSTR) regexp(CELLSTR, '(?<=name=")([a-zA-Z0-9]|:|\/|_|-)*(.fcs)','match'),linecells(indexSampleNode));
uriCellSplits = cellfun(@(CELLSTR) strsplit(CELLSTR,'/'),fullUriCells,'UniformOutput',false);
uriCellStrings = cellfun(@(CELLVEC) CELLVEC{end},uriCellSplits,'UniformOutput',false);
indexSampleNodeEnd = cellfun(@(CELLSTR) ~isempty(regexp(CELLSTR,'(?<=</)(SampleNode)(?=>)','match')),linecells);
linenumsDataSet = [linenums(indexSampleNode) linenums(indexSampleNodeEnd)];
fcsCells = horzcat(num2cell(linenumsDataSet),uriCellStrings);
fcsVarCells = {'fcs_line_begin' 'fcs_line_end' 'fcsfile'};
% ----------------- FCS Sample ID -------------------
sampleIdCellStrings = cellfun(@(CELLSTR) str2double(regexp(CELLSTR, '(?<=sampleID=")([0-9]*)(?=")','match')),linecells(indexSampleNode),'UniformOutput',false);
fcsCells = horzcat(fcsCells, sampleIdCellStrings);
fcsVarCells = [fcsVarCells {'sample_id'} ];
% ----------------- Make FCS Table -------------------
fcstab = cell2table(fcsCells);
fcstab.Properties.VariableNames = fcsVarCells;
% ----------------- Populations -------------------
indexPopBegin = cellfun(@(CELLSTR) ~isempty(regexp(CELLSTR,'(?<=<)(Population)(?=\s)','match')),linecells);
popNameCells = cellfun(@(CELLSTR) char(regexp(CELLSTR,'(?<=name=")([a-zA-Z0-9]|\s|\(|\)|\.|&amp;)*(?=")','match')),linecells(indexPopBegin),'UniformOutput',false);
[uniPopNames, idxUni, idxPopNums] = unique(popNameCells,'stable');
indexPopEnd = cellfun(@(CELLSTR) ~isempty(regexp(CELLSTR,'(?<=</)(Population)','match')),linecells);
idxPopPairs = [ linenums(indexPopBegin)  linenums(indexPopEnd)];
popCells = horzcat(popNameCells,num2cell(idxPopNums),num2cell(linenums(indexPopBegin)), num2cell(linenums(indexPopEnd)));
tableVarCells = {'popname' 'popnum' 'popline_start' 'popline_end'};
% ----------------- Gate Names -------------------
indexGateBegin = cellfun(@(CELLSTR) ~isempty(regexp(CELLSTR,'(?<=<)(Gate)(?=\s)','match')),linecells);
indexGateEnd = cellfun(@(CELLSTR) ~isempty(regexp(CELLSTR,'(?<=</)(Gate)','match')),linecells);
idxGatePairs = [ linenums(indexGateBegin)  linenums(indexGateEnd)];
gateCells = [num2cell(linenums(indexPopBegin)) num2cell(linenums(indexPopEnd))];
tableVarCells = [tableVarCells {'gateline_start' 'gateline_end'}];
% ----------------- Gate IDs -------------------
indexGateIDsBegin = cellfun(@(CELLSTR) ~isempty(regexp(CELLSTR,'(?<=gating:id=")([a-zA-Z0-9]|\s|\(|\)|\.|&amp;)*(?=")','match')),linecells,'UniformOutput',true);
gateIdCellStrings = cellfun(@(CELLSTR) char(regexp(CELLSTR,'(?<=gating:id=")([a-zA-Z0-9]|\s|\(|\)|\.|&amp;)*(?=")','match')),linecells(indexGateBegin),'UniformOutput',false);
gateIdCellNums = cellfun(@(CELLSTR) str2double(CELLSTR(3:end)) ,gateIdCellStrings, 'UniformOutput',false);
indexGateIDsEnd =  cellfun(@(CELLSTR) ~isempty(regexp(CELLSTR,'(?<=gating:id=")([a-zA-Z0-9]|\s|\(|\)|\.|&amp;)*(?=")','match')),linecells,'UniformOutput',true);
idxGateIDPairs = [linenums(indexGateIDsBegin) linenums(indexGateIDsEnd)];
idCells = [gateIdCellStrings gateIdCellNums num2cell(idxGateIDPairs)];
tableVarCells = [tableVarCells {'gate_id_strings' 'gate_id_nums' 'gate_id_start' 'gate_id_end'}];
% ----------------- Gate Shape -------------------
%   Most of the time I use polygon, so this script is designed around just parsing those.
indexGatePoly  = cellfun(@(CELLSTR) ~isempty(regexp(CELLSTR,'(?<=<gating:)((p|P[a-zA-Z]*))([a-zA-Z])','match')),linecells);
indexGateRect  = cellfun(@(CELLSTR) ~isempty(regexp(CELLSTR,'(?<=<gating:)((r|R[a-zA-Z]*))([a-zA-Z])','match')),linecells);
indexGateEllip = cellfun(@(CELLSTR) ~isempty(regexp(CELLSTR,'(?<=<gating:)((e|E[a-zA-Z]*))([a-zA-Z])','match')),linecells);
indexGateKind = indexGatePoly | indexGateRect | indexGateEllip;
idxGateKindNums = linenums(indexGateKind);
gateKindCells  = cellfun(@(CELLSTR) char(regexp(CELLSTR,'(?<=<gating:)(([a-zA-Z]*))([a-zA-Z])','match')),linecells(indexGateKind),'UniformOutput',false);
gateNumVec = zeros(length(gateKindCells),1);
% -----------------  -------------------
for idxg = 1:length(gateKindCells)
  if contains(gateKindCells{idxg},'Poly','IgnoreCase',true)
    gateNumVec(idxg) = 1;
  elseif contains(gateKindCells{idxg},'Rect','IgnoreCase',true)
    gateNumVec(idxg) = 2;
  elseif contains(gateKindCells{idxg},'Ellip','IgnoreCase',true)
    gateNumVec(idxg) = 3;
  end % END IF: gate type
end % END FOR: idxg
gateKindCells = [gateKindCells num2cell(gateNumVec) num2cell(idxGateKindNums) ];
tableVarCells = [tableVarCells {'gate_kind' 'gate_kind_num' 'gate_kind_start'}];
% ----------------- Gate Parents -------------------
gateIdParentCells = cellfun(@(CELLSTR) char(regexp(CELLSTR,'(?<=gating:parent_id=")([a-zA-Z0-9])*(?=")','match')),linecells(indexGateBegin),'UniformOutput',false);
[gateIdParentCells{cellfun(@(CELLSTR) isempty(CELLSTR) , gateIdParentCells,'UniformOutput',true)}] = deal('0');
gateIdParentNums = cellfun(@(CELLSTR)  str2double(CELLSTR(isstrprop(CELLSTR,'digit'))), gateIdParentCells );
parentCells = [gateIdParentCells num2cell(gateIdParentNums)];
tableVarCells = [tableVarCells {'parent_cells' 'parent_nums' }];
% ----------------- Gate Axes -------------------
indexGatingDim = cellfun(@(CELLSTR) ~isempty(regexp(CELLSTR,'(?<=data-type:fcs-dimension\sdata-type:name=")([a-zA-Z0-9]|\_|-|\.|\\|\/|\s|\(|\))*(?=")','match')),linecells,'UniformOutput',true);
idxGatingDim = linenums(indexGatingDim);
idxAxisX = idxGatingDim(1:2:end);
idxAxisY = idxGatingDim(2:2:end);
idxAxisPairs = [idxAxisX idxAxisY];
axisCellsAll = cellfun(@(CELLSTR) char(regexp(CELLSTR,'(?<=data-type:fcs-dimension\sdata-type:name=")([a-zA-Z0-9]|\_|-|\.|\\|\/|\s|\(|\))*(?=")','match')),linecells,'UniformOutput',false);
axisCellsAll = cellfun(@(CELLSTR) strrep(CELLSTR,'_','/'), axisCellsAll ,'UniformOutput',false);
axisCells = [axisCellsAll(idxAxisPairs) num2cell(idxAxisPairs)];

% idxmain = [95 96 97 98];
% idxmini = [48 49 48 49];
% idxmain = [1 2 3 4];
% idxmini = [48 49 48 49];
% idxall = zeros(98,1);
% for idxrec = 1 : length(axisRectCornerMax)/4
%   idxall(idxmain) = idxmini;
%   idxmain = idxmain - 4;
%   idxmini = idxmini - 2;
% end
% idxall = idxall(2:end) - 1;
% idxall(2) = 2
% ----------------- Channel Numbers X
parnums(1:height(axisCells),2) = 0;
parnums(contains(axisCells(:,1),'fsc','IgnoreCase',true),1) = 1;
parnums(contains(axisCells(:,1),'ssc','IgnoreCase',true),1) = 2;
parnums(contains(axisCells(:,1),'red','IgnoreCase',true),1) = 3;
parnums(contains(axisCells(:,1),'grn','IgnoreCase',true),1) = 4;
parnums(contains(axisCells(:,1),'org','IgnoreCase',true),1) = 5;
% ----------------- Channel Numbers Y
parnums(contains(axisCells(:,2),'fsc','IgnoreCase',true),2) = 1;
parnums(contains(axisCells(:,2),'ssc','IgnoreCase',true),2) = 2;
parnums(contains(axisCells(:,2),'red','IgnoreCase',true),2) = 3;
parnums(contains(axisCells(:,2),'grn','IgnoreCase',true),2) = 4;
parnums(contains(axisCells(:,2),'org','IgnoreCase',true),2) = 5;
% ----------------- Axis Table
axisTable = cell2table([axisCells num2cell(parnums)]);
axisTable.Properties.VariableNames = {'xchan' 'ychan' 'xline' 'yline' 'xchnum' 'ychnum'};
% ----------------- Pop / Gate Table
poptab = cell2table([popCells gateCells gateKindCells idCells parentCells]);
poptab.Properties.VariableNames = tableVarCells;
poptab{:,'sample_id'} = zeros(height(poptab),1 );
poptab{:,'fcsfile'} = {''};
poptab = horzcat(poptab,axisTable);
% ----------------- Match FCS to Pops -------------------
for idxfcs = 1: height(fcstab)
  indexLineStart = poptab{:,'popline_start'} >= fcstab{idxfcs,'fcs_line_begin'};
  indexLineStop =  poptab{:,'popline_end'} < fcstab{idxfcs,'fcs_line_end'};
  poptab{indexLineStart & indexLineStop,'sample_id'} = fcstab{idxfcs,'sample_id'};
  poptab{indexLineStart & indexLineStop,'fcsfile'} = fcstab{idxfcs,'fcsfile'};
end % END FOR: idxfcs
poptab(poptab{:,'sample_id'} == 0,:) = [];
poptab = movevars(poptab,'sample_id','After','popnum');
% ----------------- Gate Points -------------------
indexAxisPoints = cellfun(@(CELLSTR) ~isempty(regexp(CELLSTR,'(?<=gating:coordinate\sdata-type:value=")([0-9]|.)*(?=")','match')),linecells,'UniformOutput',true);
axisPointCells = cellfun(@(CELLSTR) str2double(char(regexp(CELLSTR,'(?<=gating:coordinate\sdata-type:value=")([0-9]|.)*(?=")','match'))),linecells(indexAxisPoints),'UniformOutput',false);
% ----------------- Process Rectangle gates -------------------
% indexAxisRectCorner = cellfun(@(CELLSTR) ~isempty(regexp(CELLSTR,      '(?<=gating:dimension\sgating:min=")([0-9]|.)*(?=")','match')),linecells,'UniformOutput',true);
% idxAxisRectCorner = linenums(indexAxisRectCorner)
% axisRectCornerMin = cellfun(@(CELLSTR) str2double(char(regexp(CELLSTR,'(?<=gating:dimension\sgating:min=")([0-9]|\.)*(?=")','match'))),linecells(indexAxisRectCorner),'UniformOutput',false)
% axisRectCornerMax = cellfun(@(CELLSTR) str2double(char(regexp(CELLSTR,'(?<=gating:dimension\sgating:min="([0-9]|\.|\s|")*gating:max=")([0-9]|\.)*(?=")','match'))),linecells(indexAxisRectCorner),'UniformOutput',false)
% axisRectCornerX = [axisRectCornerMin(1:2:end) axisRectCornerMax(1:2:end)]
% axisRectCornerY = [axisRectCornerMin(2:2:end) axisRectCornerMax(2:2:end)]
% ----------------- Make mat to duplicate points -------------------
% idxmatCorner = repmat([1 2 1 2], numpairs ,1) + ((1:numpairs)' * 2 - 2); %
% idd = reshape(idxmatCorner',[],1)
% cc = [aa(:,1); aa(:,2)];
% cc = cc(reshape(idxmatCorner',[],1))
% ----------------- Gather Points -------------------
axisPointCells = [axisPointCells(1:2:end) axisPointCells(2:2:end)];
idxAxisPoints = linenums(indexAxisPoints);
idxAxisPoints = [idxAxisPoints(1:2:end) idxAxisPoints(2:2:end)];
axisPointPops = zeros(height(idxAxisPoints),1);
% ----------------- Match Points to Pops -------------------
for idxpop = 1:height(poptab)
  indexPopLimitsStart = idxAxisPoints(:,1) >= poptab{idxpop,'popline_start'};
  indexPopLimitsEnd = idxAxisPoints(:,2) < poptab{idxpop,'popline_end'};
  axisPointPops(indexPopLimitsStart & indexPopLimitsEnd,1) = poptab{idxpop,'sample_id'};
  axisPointPops(indexPopLimitsStart & indexPopLimitsEnd,2) = poptab{idxpop,'popnum'};
end % END FOR: idxpop
% ----------------- Make Point table -------------------
gatetab = cell2table([num2cell([axisPointPops idxAxisPoints]) axisPointCells]);
gatetab.Properties.VariableNames = {'sample_id' 'popnum' 'xline' 'yline' 'x_point' 'y_point'};
gatetab(gatetab{:,'sample_id'} == 0,:) = [];






















% -----------------  -------------------
