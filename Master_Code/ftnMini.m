function [full_fcs_stats]=ftnMini(fulltab,extab,fcstab)

% ----------------- ftnMini -------------------
% create output summarizing fulltab into statistics that can be read by
% make_excel or observed in more detail seperately.

  % Look at individual .fcs stats
  full_fcs_stats.colvar_pop={'pro' 'syn' 'euk' 'bds' 'elg' 'esm' 'het' 'msc'};
  full_fcs_stats.colvar_par={'dat_fsc' 'dat_ssc' 'dat_red' 'dat_grn' 'dat_org'};
  full_fcs_stats.par_var_labels={'mean_fsc' 'mean_ssc' 'mean_red' 'mean_green' 'mean_orange';...
                                 'std_fsc' 'std_ssc' 'std_red' 'std_green' 'std_orange';...
                                 'mean_log10_fsc' 'mean_log10_ssc' 'mean_log10_red' 'mean_log10_green' 'mean_log10_orange';...
                                 'std_log10_fsc' 'std_log10_ssc' 'std_log10_red' 'std_log10_green' 'std_log10_orange'};
  full_fcs_stats.total.counts=sum(fulltab{:,full_fcs_stats.colvar_pop});
  full_fcs_stats.total.par=[mean(fulltab{:,full_fcs_stats.colvar_par});...
                          std(fulltab{:,full_fcs_stats.colvar_par});...
                          mean(log10(fulltab{:,full_fcs_stats.colvar_par}));...
                          std(log10(fulltab{:,full_fcs_stats.colvar_par}))];
  for i=1:length(full_fcs_stats.colvar_pop)
      var=[mean(fulltab{fulltab{:,full_fcs_stats.colvar_pop{i}} == 1,full_fcs_stats.colvar_par});...
           std(fulltab{fulltab{:,full_fcs_stats.colvar_pop{i}} == 1,full_fcs_stats.colvar_par});...
           mean(log10(fulltab{fulltab{:,full_fcs_stats.colvar_pop{i}} == 1,full_fcs_stats.colvar_par}));...
           std(log10(fulltab{fulltab{:,full_fcs_stats.colvar_pop{i}} == 1,full_fcs_stats.colvar_par}))];
      eval(['full_fcs_stats.total.' full_fcs_stats.colvar_pop{i} '=var;']);
      clear var;
  end
  sample_id=unique(fulltab{:,'sample_id'});
  full_fcs_stats.sample_id=sample_id;
  for i=1:length(sample_id)%Loop over all fcs
      %Calculate count number:
      full_fcs_stats.sample_meta.filenames(i,1)={fcstab{fcstab{:,'sample_id'}==sample_id(i),'fcsfile'}};
      extab_row=0;
      while extab_row<size(extab,1)
          extab_row=extab_row+1;
          if strcmp(full_fcs_stats.sample_meta.filenames{i,1},extab{extab_row,'fcsfile'}),break,end
      end
      if ~strcmp(full_fcs_stats.sample_meta.filenames{i,1},extab{extab_row,'fcsfile'}),error('Identical file names in extab and fcstab not found'),end
      full_fcs_stats.sample_meta.cruise_text{i,1}=extab{extab_row,'project'};
      full_fcs_stats.sample_meta.cruise_num(i,1)=extab{extab_row,'hot'};
      full_fcs_stats.sample_meta.station(i,1)=extab{extab_row,'stn'};
      full_fcs_stats.sample_meta.cast(i,1)=extab{extab_row,'cast'};
      full_fcs_stats.sample_meta.bottlenum(i,1)=extab{extab_row,'btl'};
      full_fcs_stats.sample_meta.dup(i,1)=extab{extab_row,'dup'};
      full_fcs_stats.sample_meta.rep(i,1)=extab{extab_row,'rep'};
      full_fcs_stats.sample_meta.runver(i,1)=extab{extab_row,'runver'};
      full_fcs_stats.sample_meta.tx(i,1)=extab{extab_row,'tx'};
      full_fcs_stats.sample_meta.time(i,1:4)=[extab{extab_row,'year'} extab{extab_row,'month'} extab{extab_row,'day'} extab{extab_row,'hhmm'}];
      full_fcs_stats.sample_meta.depth(i,1)=unique(fulltab{fulltab{:,'sample_id'} == sample_id(i),'dep'});
      if full_fcs_stats.sample_meta.depth(i,1)~=extab{extab_row,'depth'},error('extab and fulltab depths do not match'),end
      full_fcs_stats.sample_counts(i,:)=sum(fulltab{fulltab{:,'sample_id'} == sample_id(i),full_fcs_stats.colvar_pop});
      try,full_fcs_stats.sample_vol_raw(i,1)=extab{extab_row,'vol_raw'};end
      full_fcs_stats.sample_vol(i,1)=extab{extab_row,'vol'};
      full_fcs_stats.sample_conc(i,:)=full_fcs_stats.sample_counts(i,:)./full_fcs_stats.sample_vol(i,1)*1000;%convert to cells/mL
      for j=1:length(full_fcs_stats.colvar_pop)
          var=[mean(fulltab{fulltab{:,'sample_id'} == sample_id(i) & fulltab{:,full_fcs_stats.colvar_pop{j}} == 1,full_fcs_stats.colvar_par});...
               std(fulltab{fulltab{:,'sample_id'} == sample_id(i) & fulltab{:,full_fcs_stats.colvar_pop{j}} == 1,full_fcs_stats.colvar_par});...
               mean(log10(fulltab{fulltab{:,'sample_id'} == sample_id(i) & fulltab{:,full_fcs_stats.colvar_pop{j}} == 1,full_fcs_stats.colvar_par}));...
               std(log10(fulltab{fulltab{:,'sample_id'} == sample_id(i) & fulltab{:,full_fcs_stats.colvar_pop{j}} == 1,full_fcs_stats.colvar_par}))];
          eval(['full_fcs_stats.sample_' int2str(sample_id(i)) '.' full_fcs_stats.colvar_pop{j} '=var;']);
          clear var;
      end
  end
