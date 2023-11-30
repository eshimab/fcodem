function fpnMini(fcstab,fulltab,poptab,fcsdiris,savediris)
% Written by Eric Shimabukuro

% Designed to make figures of fcs file variables





% ----------------- fpnMini -------------------
%   Make some plots
close all;
% pause off
% funcilCloseFig = @(FIG) FIG;
set(groot,'defaultFigureColor',[1 1 1])
fig= figure('visible','off');
fig.Position = [50,50,750,750];


for idxfcs = 1:height(fcstab)
  fcsid = fcstab{idxfcs,'sample_id'};
  [~, fcshdr, fcsdata, ~ ] = fca_readfcs([fcsdiris filesep() char(fcstab{idxfcs,'fcsfile'})]);
  indexfcs = poptab{:,'sample_id'} == fcsid;
  popmini = poptab(indexfcs,:);
  [mininums, idxminum, idxpm] = unique(popmini{:,'popnum'},'stable'); 
  % -----------------  -------------------
  for idxpop = 1 : height(popmini)
    subplot(3,ceil(height(popmini)/3),idxpop);
    hold on
    indexX = strcmp({fcshdr.par.name},popmini{idxpop,'xchan'});
    indexY = strcmp({fcshdr.par.name},popmini{idxpop,'ychan'});
    polyGateX = popmini{idxpop,'pointmat'}{:}(:,1);
    polyGateY = popmini{idxpop,'pointmat'}{:}(:,2);
    % ----------------- Check to see if this is a subgate -------------------
    if popmini{idxpop,'parent_nums'} ~= 0
      % ----------------- it is a subgate -------------------
      parentIndexCells = popmini{popmini{:,'gate_kind'} == popmini{idxpop,'parent_nums'} ,'fcsindex'};
      indexParentFcs = parentIndexCells{:};
      xvecbase = fcsdata(indexParentFcs,indexX);
      yvecbase = fcsdata(indexParentFcs,indexY);
    else
      % ----------------- it is not -------------------
      xvecbase = fcsdata(:,indexX);
      yvecbase = fcsdata(:,indexY);
    end % END IF: popmini
    % ----------------- Plot Pop -------------------
    scatter(xvecbase,yvecbase,'DisplayName',char(popmini{idxpop,'popname'}));
    ax = gca;
    [ax.XScale, ax.YScale] = deal('log');
    [ax.XLim,   ax.YLim] = deal([1 10000]);
    xlabel(fcshdr.par(indexX).name, 'FontSize',10);
    ylabel(fcshdr.par(indexY).name, 'FontSize',10);
    hold on
    % ----------------- Plot Gate -------------------
    patch(polyGateX,polyGateY,[1 1 1],'FaceAlpha',0.5);
    title(char(popmini{idxpop,'popname'}),'Interpreter','none','FontSize',12);
  end % END FOR: idxpop

  % ----------------- Figure Finalization -------------------
  axline = fig.Children; % Axes vector
  ttls = [axline.Title];
  [ttls.Units] = deal('normalized');
  % [ttls.Position] = deal([0.5 0.95 0]);
  % ----------------- Label with fcs file -------------------
  sgtitle(fcstab{idxfcs,'fcsfile'},'Interpreter','none');

  % ----------------- Save -------------------
  savestring = [savediris filesep() 'FIG' filesep() 'figout_sample_id_' num2str(fcsid) '.png'];
  saveas(fig,savestring);
  clf(fig)
  
  % ----------------- Composite Fig -------------------
  idxxax = 1; % FSC
  if numel(axline) > 3
    idxyax = 3; % red
    popcells = {'pro' 'syn' 'euk' 'bds'  'esm' 'elg' 'msc'};
  else
    idxyax = 4; % grn
    popcells = {'het'};
  end
  fcsid = fcstab{idxfcs,'sample_id'};
  indexID = fulltab{:,'sample_id'} == fcsid;
  idxmat = table2array(fulltab(fulltab{:,'sample_id'} == fcsid ,popcells));
  datmat = table2array(fulltab(fulltab{:,'sample_id'} == fcsid ,{'dat_fsc' 'dat_ssc' 'dat_red' 'dat_grn' 'dat_org'}));
  datcells = {'dat_fsc' 'dat_ssc' 'dat_red' 'dat_grn' 'dat_org'};
  fscmat = idxmat(: , [1:1:width(idxmat)]) .* datmat(:,idxxax);
  redmat = idxmat(: , [1:1:width(idxmat)]) .* datmat(:,idxyax);
  % ----------------- Plot -------------------
  ax = gca();
  scatter(ax,fscmat,redmat);
  ax.NextPlot = 'add';
  % ----------------- Axes -------------------
  xlabel(datcells{idxxax});
  ylabel(datcells{idxyax});
  [ax.XLim, ax.YLim] = deal([1 10000]);
  [ax.XScale, ax.YScale] = deal('log');
  popdisplay = fliplr(popcells); % For deal()
  [ax.Children.DisplayName] = deal(popdisplay{:});
  axline = [fig.Children];
  ax.FontSize = 12;
  % ----------------- Title and legend -------------------
  title(fcstab{idxfcs,'fcsfile'},'Interpreter','none');
  leggo = legend(ax);
  leggo.Location = 'northwest';
  savestring = [savediris filesep() 'FIG' filesep() 'solo_figout_sample_id' num2str(fcsid) '.png'];
  saveas(fig,savestring);
  clf(fig)
end % END FOR: idxfcs
close(fig);
return


% % ----------------- Pad Margine -------------------
% % posmat(:,3:4) = [posmat(:,3) .* 85/100 posmat(:,4) .* 85/100]; % Shrink axes by 3%
% % ----------------- Horiz Crunch -------------------
% [unirow, idxunirow, idxposrow] = unique(posmat(:,1))
% xcorners = min(unirow) + posmat(1,3) .* (0:numcols-1)'
% posmat(:,1) = xcorners(idxposrow);
% % ----------------- Vertical Crunch -------------------
% [unicol, idxunicol, idxposcol] = unique(posmat(:,2));
% ycorners = min(unicol) + posmat(1,4) .* (0:numrows-1)';
% posmat(:,2) = ycorners(idxposcol);
% % ----------------- Horiz Shift -------------------
% posmat(:,1) = 0.97 - (posmat(end,1) + posmat(end,3)) + posmat(:,1)
% % ----------------- Vertical Shift -------------------
% posmat(:,2) = 0.97 - (posmat(end,2) + posmat(end,4)) - posmat(:,2);




% popNumPRO = popmini{cellfun( @(CELLSTR) ~isempty(regexp(CELLSTR, '(PRO)(?!\sL)'        ,'Once'))   ,popmini{:,'popname'},'UniformOutput',true),:}
% popNumSYN = popmini{cellfun( @(CELLSTR) ~isempty(regexp(CELLSTR, '(SYN)'               ,'Once'))   ,popmini{:,'popname'},'UniformOutput',true),:}
% popNumELG = popmini{cellfun( @(CELLSTR) ~isempty(regexp(CELLSTR, '(?<=[A-Z])(EUKS\sLG)','Once'))   ,popmini{:,'popname'},'UniformOutput',true),:}
% popNumESM = popmini{cellfun( @(CELLSTR) ~isempty(regexp(CELLSTR, '(?<=[A-Z])(EUKS\sSM)','Once'))   ,popmini{:,'popname'},'UniformOutput',true),:}
% popNumBDS = popmini{cellfun( @(CELLSTR) ~isempty(regexp(CELLSTR, '(BEADS)'               ,'Once')) ,popmini{:,'popname'},'UniformOutput',true),:}
% popNumHET = popmini{cellfun( @(CELLSTR) ~isempty(regexp(CELLSTR, '(SYBR)'              ,'Once'))   ,popmini{:,'popname'},'UniformOutput',true),:}



% ----------------- Load -------------------
% figdirs = dir('/Users/eshim/hotfcm/QC/matfigs');
% cd('/Users/eshim/hotfcm/QC/matfigs');
% indexFigs = cellfun(@(CELLSTR) (length(CELLSTR) > 8 && strcmpi(CELLSTR(end-2:end),'fig'))  ,{figdirs.name}','UniformOutput',true);
% figline = cellfun( @(CELLSTR) openfig(CELLSTR),{figdirs(indexFigs).name}','UniformOutput',false); % openfig here.
% pngnames = cellfun(@(CELLSTR) [CELLSTR(1:end-3) 'png'], {figdirs(indexFigs).name}','UniformOutput',false);
% pdfnames = cellfun(@(CELLSTR) [CELLSTR(1:end-3) 'pdf'], {figdirs(indexFigs).name}','UniformOutput',false);
% for idxfig = 1:length(figline)
%     exportgraphics(figline{idxfig}, ['/Users/eshim/hotfcm/QC/images/allfigs.pdf'], 'Append', true);
%     exportgraphics(figline{idxfig}, ['/Users/eshim/hotfcm/QC/images/' pngnames{idxfig}])
% end










% -----------------  -------------------
