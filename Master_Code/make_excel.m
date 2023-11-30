function [excel_1,excel_2]=make_excel(full_fcs_stats)
% Main Sheet 
% [HOT ID][Station][Cast][Bottle][Rep][Depth][Duplicate]
% [Unstained Vol Measured][Unstained Vol Corrected][Stained Vol Measured][Stained Vol Corrected]
% [Pro Count][Pro Conc][Syn Count][Syn Conc][PEuk Count][PEuk Conc][Het Count][Het Conc]
% [Pro. Mean],[Pro. STD],[Pro. STD/Mean(%)],[Syn. Mean],[Syn. STD],[Syn. STD/Mean(%)],[PEuk Mean],[PEuk STD],[PEuk STD/Mean(%)],[Het. Mean],[Het. STD],[Het. STD/Mean(%)]
% [Mean Pro FSC][Mean Bead FSC][Pro FCS/Bead FCS*100][Mean Pro Red][Mean Bead Red][Pro Red/Bead Red*100]
% [PEUK LG][PEUK SML][PEUKS TOT][File Name Unstained][File Name Stained]
btlnum=unique(full_fcs_stats.sample_meta.bottlenum);
dupnum=max(full_fcs_stats.sample_meta.dup)+1;%Determine the number of duplicate measurements and scale matrix accordingly
excel_1=NaN(length(btlnum)*dupnum,42);
for i=1:length(btlnum)
    %Identify latest rep of each potential file type
    ind=[];inds=[];
    for j=1:dupnum
        ind1=find(full_fcs_stats.sample_meta.bottlenum==btlnum(i) & full_fcs_stats.sample_meta.dup==j-1 & full_fcs_stats.sample_meta.tx==1);
        if length(ind1>1),ind1=ind1(full_fcs_stats.sample_meta.runver(ind1)==max(full_fcs_stats.sample_meta.runver(ind1)));end %Force to use highest runver
        ind=[ind;ind1];
        inds1=find(full_fcs_stats.sample_meta.bottlenum==btlnum(i) & full_fcs_stats.sample_meta.dup==j-1 & full_fcs_stats.sample_meta.tx==2);
        if length(inds1>1),inds1=inds1(full_fcs_stats.sample_meta.runver(inds1)==max(full_fcs_stats.sample_meta.runver(inds1)));end
        inds=[inds;inds1];
        clear ind1 inds1;
    end
    if isempty(ind),ind=inds;warning(['Bottle# ' int2str(btlnum(i)) ' has no unstained measurements']);end %If no main data, fill metadata using inds
    exind=(i-1)*dupnum+1:(i-1)*dupnum+length(ind);
    exinds=(i-1)*dupnum+1:(i-1)*dupnum+length(inds);
    excel_1(exind,41)=ind;%Archive for easy file name insertion later 
    excel_1(exinds,42)=inds;%Archive for easy file name insertion later 
    excel_1(exind,1)=full_fcs_stats.sample_meta.cruise_num(ind,1);%Convert to the full name later
    excel_1(exind,2)=full_fcs_stats.sample_meta.station(ind,1);
    excel_1(exind,3)=full_fcs_stats.sample_meta.cast(ind,1);
    excel_1(exind,4)=btlnum(i);
    excel_1(exind,5)=full_fcs_stats.sample_meta.rep(ind,1);
    excel_1(exind,6)=full_fcs_stats.sample_meta.depth(ind,1);
    excel_1(exind,7)=full_fcs_stats.sample_meta.dup(ind,1);
    try,excel_1(exind,8)=full_fcs_stats.sample_vol_raw(ind,1);end
    excel_1(exind,9)=full_fcs_stats.sample_vol(ind,1);
    try,excel_1(exinds,10)=full_fcs_stats.sample_vol_raw(inds,1);end
    excel_1(exinds,11)=full_fcs_stats.sample_vol(inds,1);
    %Plankton
    excel_1(exind,[12,14,16])=full_fcs_stats.sample_counts(ind,1:3);
    excel_1(exind,[13,15,17])=full_fcs_stats.sample_conc(ind,1:3);
    excel_1(exinds,18)=full_fcs_stats.sample_counts(inds,7);%HET Counts and Concentrations off???
    excel_1(exinds,19)=full_fcs_stats.sample_conc(inds,7);
    %Standardize means by difference in volume, even if it does not really change the result
    excel_1(exind(1),[20,23,26])=sum(excel_1(exind,[12,14,16]))/sum(excel_1(exind,9))*1000;%convert to cells/mL
    excel_1(exind(1),[21,24,27])=std(excel_1(exind,[13,15,17]));
    excel_1(exind(1),29)=sum(excel_1(exinds,18))/sum(excel_1(exinds,11))*1000 - excel_1(exind(1),20);%convert to cells/mL, remove Pro.
    excel_1(exind(1),30)=std(excel_1(exinds,19));
    excel_1(exind(1),[22,25,28,31])=(excel_1(exind(1),[21,24,27,30])./excel_1(exind(1),[20,23,26,29]))*100;
    for j=1:size(ind)
        eval(['tmp=full_fcs_stats.sample_' int2str(full_fcs_stats.sample_id(ind(j))) '.pro;'])
        excel_1(exind(j),32)=tmp(1,1);
        excel_1(exind(j),35)=tmp(1,3);
        eval(['tmp=full_fcs_stats.sample_' int2str(full_fcs_stats.sample_id(ind(j))) '.bds;'])  
        excel_1(exind(j),33)=tmp(1,1);
        excel_1(exind(j),36)=tmp(1,3);
        excel_1(exind(j),34)=excel_1(exind(j),32)./tmp(1,1)*100;
        excel_1(exind(j),37)=excel_1(exind(j),35)./tmp(1,3)*100;
    end
    excel_1(exind,38:40)=full_fcs_stats.sample_counts(ind,[5,6,3]);
end
excel_1=array2table(excel_1);
headers=["HOT ID","Station","Cast","Bottle","Reprocessed Number","Depth","Duplicate",... % 7 var
         "Unstained Volume Measured (uL)","Unstained Volume Corrected (uL)","Stained Volume Measured (uL)","Stained Volume Corrected (uL)",... % 4 var
         "Pro. Count (# cells)","Pro. Conc. (cells/mL)","Syn. Count (# cells)","Syn. Conc. (cells/mL)","PEuk Count (# cells)","PEuk Conc. (cells/mL)","Het. Count (# cells)","Het. Conc. (cells/mL)",... % 8 var
         "Pro. Mean","Pro. STD","Pro. STD/Mean (%)","Syn. Mean","Syn. STD","Syn. STD/Mean (%)","PEuk Mean","PEuk STD","PEuk STD/Mean (%)","Het. Mean","Het. STD","Het. STD/Mean (%)",... %12 var
         "Pro. FSC Mean","Bead FSC Mean","Pro FCS/Bead FCS * 100","Pro. Red Mean","Bead Red Mean","Pro. Red/Bead Red * 100",... % 6 var
         "PEuk Large Count","PEuk Small Count","PEuk Total Count","File Name Unstained","File Name Stained"]; % 5 var = 42 var total
excel_1=renamevars(excel_1,1:42,headers);
excel_1=convertvars(excel_1,["HOT ID","File Name Unstained","File Name Stained"],'string');
for i=1:size(excel_1,1)
    if ~ismissing(excel_1{i,'HOT ID'}) % If duplicate is unbalanced across bottles
        id=[char(excel_1{i,'HOT ID'}) '-' int2str(excel_1{i,'Station'}) '-' int2str(excel_1{i,'Cast'}) '-' int2str(excel_1{i,'Bottle'})];
        if excel_1{i,'Duplicate'}==1,id=[id '-D'];
        elseif excel_1{i,'Duplicate'}>1,id=[id '-D' int2str(excel_1{i,'Duplicate'})];end
        excel_1{i,1}={id};
        excel_1(i,41)=full_fcs_stats.sample_meta.filenames{str2double(excel_1{i,41}),1};
        if ~isnan(str2double(excel_1{i,42})),excel_1(i,42)=full_fcs_stats.sample_meta.filenames{str2double(excel_1{i,42}),1};end
    end
end
ind=excel_1{:,'Duplicate'}==0;% Replace with string for legibility
excel_1=convertvars(excel_1,'Duplicate','string');
excel_1{ind,'Duplicate'}={''};excel_1{~ind,'Duplicate'}={'Duplicate'};

%For_Lance
casts=unique(full_fcs_stats.sample_meta.cast);
excel_2=NaN(length(casts),8);%Columns HOT STATION CAST BOTTLE PRO SYN PEUKS HET
depths=[5 25 45 75 100 125 150 175];
for i=1:length(casts)
    excel_2((i-1)*8+1:i*8,1)=unique(full_fcs_stats.sample_meta.cruise_num(full_fcs_stats.sample_meta.cast==casts(i)));
    excel_2((i-1)*8+1:i*8,2)=unique(full_fcs_stats.sample_meta.station(full_fcs_stats.sample_meta.cast==casts(i)));
    excel_2((i-1)*8+1:i*8,3)=casts(i);
    for j=1:length(depths)
        ind=find(excel_1{:,'Cast'}==casts(i) & excel_1{:,'Depth'}==depths(j),1,'First');
        if ~isempty(ind) %Check to see if depth is present
            try,excel_2((i-1)*8+j,4)=unique(full_fcs_stats.sample_meta.bottlenum(full_fcs_stats.sample_meta.cast==casts(i) & full_fcs_stats.sample_meta.depth==depths(j)));
            catch,excel_2((i-1)*8+j,4)=full_fcs_stats.sample_meta.bottlenum(find(full_fcs_stats.sample_meta.cast==casts(i) & full_fcs_stats.sample_meta.depth==depths(j),1,'First'));end %Override if multiple bottles are valid
            excel_2((i-1)*8+j,5:8)=excel_1{ind,[20,23,26,29]};
        end
    end
end
excel_2=array2table(excel_2);
excel_2=renamevars(excel_2,1:8,["HOT","STATION","CAST","BOTTLE","PRO","SYN","PEUKS","HET"]);
