function [fullmat,fulltab,poptab,fcsdat,fcsmet,idxmat]=fppMicro(contab,extab,fcstab,gatetab,poptab,fcsdiris,savediris)
% Written by Eric Shimabukuro
%
% The primary purpose of this code is to eliminate inactive channels and 
% reorganize output into a standard format across all fcs files. 





% ----------------- Load FCS Files & apply gates -------------------

% ----------------- Init -------------------
popPointCells = repmat({[]},height(poptab),1);
fcsIndexCells = repmat({[]},height(poptab),1);
% ----------------- Loop thru fcs files -------------------
for idxfcs = 1:height(fcstab)
  % ----------------- Load FCS Data -------------------
  if ~ismember(char(fcstab{idxfcs,'fcsfile'}),extab{:,'fcsfile'})
    fprintf([newline() '  ' char(fcstab{idxfcs,'fcsfile'}) '  was skipped due to no extab listing!' newline() newline()]);
    continue
  end
  loadString = [fcsdiris filesep() char(fcstab{idxfcs,'fcsfile'})];
  [~, fcshdr, fcsAllData, ~] = fca_readfcs(loadString);
  uniPopNames = unique(poptab{:,'popname'},'stable');
  indexmat = zeros(height(fcsAllData),length(uniPopNames) + 1); % Init
  % ----------------- Link FCS to pops via sample_id -------------------
  sampleID = fcstab{idxfcs,'sample_id'};
  indexPopTab = poptab{:,'sample_id'} == sampleID;
  popMini = poptab(indexPopTab,:);
  popMiniCells = repmat({[]},height(popMini),1);
  fcsMiniCells = repmat({[]},height(popMini),1);
  % ----------------- Loop thru pops for FCS -------------------
  for idxpop = 1:height(popMini)
    % ----------------- Get X/Y points for gate polygon -------------------
    popnum = popMini{idxpop,'popnum'};
    indexPopNum = gatetab{:,'popnum'} == popnum;
    indexPopID = gatetab{:,'sample_id'} == sampleID;
    pointmat = gatetab{indexPopNum & indexPopID,{'x_point' 'y_point'}};
    % ----------------- Get points for active pop -------------------
    xvec = pointmat(:,1);
    yvec = pointmat(:,2);
    xdata = fcsAllData(:,strcmpi({fcshdr.par.name},char(popMini{idxpop,'xchan'})));
    ydata = fcsAllData(:,strcmpi({fcshdr.par.name},char(popMini{idxpop,'ychan'})));
    [indexInPoly, indexOnPoly] = inpolygon(xdata,ydata,xvec,yvec);
    indexPoly = indexInPoly | indexOnPoly;
    % ----------------- Get Parent if necessary -------------------
    if popMini{idxpop,'parent_nums'} ~= 0
      indexParent = indexmat(:,popMini{popMini{:,'gate_kind'} == popMini{idxpop,'parent_nums'} ,'popnum'}) == 1;
      indexPoly = indexParent & indexPoly;
    end
    popMiniCells{idxpop} = pointmat;
    fcsMiniCells{idxpop} = indexPoly;
    indexmat(indexPoly,popnum) = 1;
  end % END FOR: idxpop
  popPointCells(indexPopTab) = popMiniCells;
  fcsIndexCells(indexPopTab) = fcsMiniCells;
  % ----------------- Get active channels only -------------------
  [~,fcschans] = ismember({'FSC-488' 'SSC-488' 'RED-488 692/40' 'GRN-488 542/27' 'ORG-488 585/40'},{fcshdr.par.name}); % Modern Channel Names
  chanvec = fcschans;
  [~,fcschans] = ismember({'FSC' 'SSC' '692/40 R (488)' '542/27 G (488)' '585/40 O (488)'},{fcshdr.par.name}); % Old CHannel Names
  chanvec(chanvec == 0) = fcschans(chanvec == 0);
  fcschans = chanvec;
  % [~,fcschans] = ismember(contab{1,{'fsc_chn' 'ssc_chn' 'red_chn' 'grn_chn' 'org_chn'}},{fcshdr.par.name}); % Channel Names maybe in contab
  % ----------------- Get Misc Points; Trim Data -------------------
  indexmat(fcsAllData(:,fcschans(1)) > 10 & fcsAllData(:,fcschans(3)) > 10 & ~(sum(indexmat,2) > 0),end) = 1;
  indexAllPops = sum(indexmat,2) > 0; % Get Only rows with a pop in them
  indexMini = indexmat(indexAllPops,:);
  fcsdatMini = fcsAllData(indexAllPops,fcschans); % Trim AllData
  numrows = height(fcsdatMini); % For repmats
  % ----------------- Get and organize pops for output array -------------------
  [uniPopNames, idxuni, idxfull] = unique(poptab{:,'popname'});
  uniPopNums = poptab{idxuni,'popnum'};
  % Match to Pop name string, use that index to get the row in poptab where the pop first apeared,
  %   then get the matching popnum from that poptab row.
  popNumPRO = poptab{idxuni(cellfun( @(CELLSTR) ~isempty(regexp(CELLSTR, '(PRO)(?!\sL)'        ,'Once')),uniPopNames,'UniformOutput',true)),'popnum'};
  popNumPLG = poptab{idxuni(cellfun( @(CELLSTR) ~isempty(regexp(CELLSTR, '(PRO\sLG)'           ,'Once')),uniPopNames,'UniformOutput',true)),'popnum'};
  popNumSYN = poptab{idxuni(cellfun( @(CELLSTR) ~isempty(regexp(CELLSTR, '(SYN)'               ,'Once')),uniPopNames,'UniformOutput',true)),'popnum'};
  popNumELG = poptab{idxuni(cellfun( @(CELLSTR) ~isempty(regexp(CELLSTR, '(PEUKS\s)(?!SM)'     ,'Once')),uniPopNames,'UniformOutput',true)),'popnum'};
  if isempty(popNumELG)
    popNumELG = poptab{idxuni(cellfun( @(CELLSTR) ~isempty(regexp(CELLSTR, '(?<=[A-Z])(EUKS\sLG)','Once')),uniPopNames,'UniformOutput',true)),'popnum'};
  end
  popNumESM = poptab{idxuni(cellfun( @(CELLSTR) ~isempty(regexp(CELLSTR, '(?<=[A-Z])(EUKS\sSM)','Once')),uniPopNames,'UniformOutput',true)),'popnum'};
  popNumBDS = poptab{idxuni(cellfun( @(CELLSTR) ~isempty(regexp(CELLSTR, '(BEADS|BDS)'         ,'Once')),uniPopNames,'UniformOutput',true)),'popnum'};
  popNumHET = poptab{idxuni(cellfun( @(CELLSTR) ~isempty(regexp(CELLSTR, '(SYBR)'              ,'Once')),uniPopNames,'UniformOutput',true)),'popnum'};
  % ----------------- Shift Pop index Columns to make it consistent for all FCS -------------------
  clear indexMiniShift popNumCells popNumCols
  popNumCells = {popNumPRO popNumSYN popNumBDS popNumELG popNumESM popNumHET width(indexMini)}; % Temp Var
  popNumCols = cellfun(@(CELL) ~isempty(CELL),popNumCells) .* [1 2 4 5 6 7 8]; % Get active col nums
  indexMiniShift(:,popNumCols(popNumCols > 0 )) = indexMini(:,[popNumCells{:}]); % Init
  % ----------------- Collapse PRO and PRO LG into PRO -------------------
  indexMiniShift(indexMini(:,popNumPLG) == 1,1) = 1;
  % ----------------- Combine EUK LG and EUK SML for EUK -------------------
  indexMiniShift(:,3) = indexMini(:,popNumELG) | indexMini(:,popNumESM); % EUK
  sampleIDVector(1:height(indexMiniShift),1) = sampleID; % Save sampleID for matching to FCS file.
  indexMiniShift = [sampleIDVector indexMiniShift];
  matcols = {'idx_mat' 'pro' 'syn' 'euk' 'bds' 'elg' 'esm' 'het' 'msc'};
  % ----------------- Import in extab -------------------
  indexExtab = strcmpi(extab{:,'fcsfile'},fcstab{idxfcs,'fcsfile'});
  datemat = repmat(extab{indexExtab,{'hot' 'year' 'month' 'day' 'hhmm' }},numrows,1);
  volvec = repmat(extab{indexExtab,'vol'},numrows,1);
  depmat = repmat(extab{indexExtab,{'depth' 'press'}},numrows,1);
  txvec = repmat(extab{indexExtab,'tx'},numrows,1);
  % ----------------- Import fcshdr -------------------
  rundate = datetime(fcshdr.date,'InputFormat','dd-MMM-yyyy','Format','yyyy.MM.dd');
  runmat = repmat([year(rundate) month(rundate) day(rundate)],numrows,1);
  % -----------------  -------------------
  fcsmetMini = [sampleIDVector datemat volvec txvec depmat runmat];
  metcols = {'sample_id' 'hot'  'year' 'month' 'day' 'hhmm' 'vol' 'tx' 'dep' 'press' 'daterun_year' 'daterun_month' 'daterun_day' };
  % ----------------- Import in contab -------------------
  indexExToCon = strcmpi(contab{:,'configfile'},extab{indexExtab,'configfile'});
  indexConPrimary = strcmpi(contab{:,'fcsfile'},'primary');
  conrows = contab(indexExToCon & indexConPrimary,1:end-5);
  contabVars = {'fsc488' 'ssc488' 'red488' 'grn488'  'org488'};
  gainmat = repmat(conrows{1,contabVars},numrows,1);
  fcsdatMini = [sampleIDVector fcsdatMini log10(fcsdatMini)  gainmat ];
  datcols = {'id_fcsdat' 'dat_fsc' 'dat_ssc' 'dat_red' 'dat_grn' 'dat_org' 'log_fsc' 'log_ssc' 'log_red' 'log_grn' 'log_org' 'gain_fsc' 'gain_ssc' 'gain_red' 'gain_grn' 'gain_org'};
  % -----------------  -------------------

  % ----------------- Stack output for entire workspace - Changes on loop -------------------
  if ~exist('fcsmetFinal','var') || ~exist('fcsdatFinal','var') || ~exist('indexPopsFinal','var')
    fcsmetFinal = fcsmetMini;
    fcsdatFinal = fcsdatMini;
    indexPopsFinal = indexMiniShift;
  else
    fcsmetFinal    = vertcat(fcsmetFinal,fcsmetMini);
    fcsdatFinal    = vertcat(fcsdatFinal,fcsdatMini);
    indexPopsFinal = vertcat(indexPopsFinal,indexMiniShift);
  end
  % ----------------- Save Per fcs -------------------
  savestring = [savediris filesep() 'FJP' filesep() 'metmini_id_' num2str(sampleID) '.mat'];
  save(savestring,'fcsmetMini','-v7.3');
  % -----------------  -------------------
  savestring = [savediris filesep() 'FJP' filesep() 'datmini_id_' num2str(sampleID) '.mat'];
  save(savestring,'fcsdatMini','-v7.3');
  % -----------------  -------------------
  savestring = [savediris filesep() 'FJP' filesep() 'idxmini_id_' num2str(sampleID) '.mat'];
  save(savestring,'indexMiniShift','-v7.3');

  clear indexMiniShift fcsdatMini sampleIDVector fcsmetMini gainmat datemat volvec
end % END FOR: idxfcs
% ----------------- END FCS LOOP -------------------
% return
% ----------------- Store Gates with pops -------------------
poptab{:,'pointmat'} = popPointCells;
poptab{:,'fcsindex'} = fcsIndexCells;
% ----------------- Finalize -------------------
fcsmet = fcsmetFinal;
fcsmettab = array2table(fcsmet);
fcsmettab.Properties.VariableNames = metcols;
idxmat = indexPopsFinal;
idxmattab = array2table(idxmat);
idxmattab.Properties.VariableNames = matcols;
fcsdat = fcsdatFinal;
fcsdattab = array2table(fcsdat);
fcsdattab.Properties.VariableNames = datcols;
% ----------------- Coagulagte -------------------
fullmat = [fcsmet(:,:) idxmat(:,2:end) fcsdat(:,2:end)];
fulltab = array2table(fullmat);
fulltab.Properties.VariableNames = [metcols matcols(2:end) datcols(2:end)];
























% -----------------  -------------------
