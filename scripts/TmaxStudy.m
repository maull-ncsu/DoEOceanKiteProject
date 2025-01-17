%%  Load Results 
Tmaxx = 38;
fpath2 = fullfile(fileparts(which('OCTProject.prj')),'vehicleDesign','Tether\');  load([fpath2 'tetherDataFS3.mat']);
load(['C:\Users\John Jr\Desktop\Manta Ray\Model 9_28\output\Tmax Study\',sprintf('Tmax_Study_AR8b8_Tmax-%d.mat',Tmaxx)]);
depth = [300 250 200];
eff = eval(sprintf('AR8b8.length600.tensionValues%d.efficencyPercent',114))/100;
%%  Squeeze Results 
Pavg = squeeze(Pavg);
Pnet = squeeze(Pnet);
AoA = squeeze(AoA);
CD = squeeze(CD);
CL = squeeze(CL);
elevation = squeeze(elevation);
ten = squeeze(ten);
Fdrag = squeeze(Fdrag);
Ffuse = squeeze(Ffuse);
Flift = squeeze(Flift);
Fthr = squeeze(Fthr);
Fturb = squeeze(Fturb);
%%  Reassign variables 
for i = 1:numel(flwSpd)
    for j = 1:numel(altitude)
        if ~isnan(max(Pavg(i,:,j)))
            idx1 = find(Pavg(i,:,j)==max(Pavg(i,:,j)));
            R.Pmax(i,j) = Pavg(i,idx1,j);
            R.Pnet(i,j) = Pnet(i,idx1,j);
            R.alpha(i,j) = AoA(i,idx1,j);
            R.CD(i,j) = CD(i,idx1,j);
            R.CL(i,j) = CL(i,idx1,j);
            R.EL(i,j) = elevation(i,idx1,j);
            R.ten(i,j) = ten(i,idx1,j);
            R.thrL(i,j) = thrLength(idx1);
            R.Fdrag(i,j) = Fdrag(i,idx1,j);
            R.Ffuse(i,j) = Ffuse(i,idx1,j);
            R.Flift(i,j) = Flift(i,idx1,j);
            R.Fthr(i,j) = Fthr(i,idx1,j);
            R.Fturb(i,j) = Fturb(i,idx1,j);
        else
            R.Pmax(i,j) = NaN;
            R.Pnet(i,j) = NaN;
            R.CD(i,j) = NaN;
            R.CL(i,j) = NaN;
            R.EL(i,j) = NaN;
            R.ten(i,j) = NaN;
            R.thrL(i,j) = NaN;
            R.Fdrag(i,j) = NaN;
            R.Ffuse(i,j) = NaN;
            R.Flift(i,j) = NaN;
            R.Fthr(i,j) = NaN;
            R.Fturb(i,j) = NaN;
        end
    end
end
R.Pmax1 = R.Pmax*eff;
%%  Plotting 
figure; 
for alt = 1:6
    subplot(3,2,1); hold on; grid on
    plot(flwSpd,R.Pmax(:,alt)*eff);  xlabel('$V_\mathrm{flow}$ [m/s]');  ylabel('Power [kW]');  xlim([.1 0.5]);
    subplot(3,2,6); hold on; grid on
    plot(flwSpd,R.alpha(:,alt));  xlabel('$V_\mathrm{flow}$ [m/s]');  ylabel('AoA [deg]');  xlim([.1 0.5]);
    subplot(3,2,3); hold on; grid on
    plot(flwSpd,R.ten(:,alt));  xlabel('$V_\mathrm{flow}$ [m/s]');  ylabel('Tension [kN]');  xlim([.1 0.5]);
    if alt == 6
        plot(flwSpd,Tmaxx*ones(1,numel(flwSpd)),'k--')
    end
    legend('Alt = 50 m','Alt = 100 m','Alt = 150 m','Alt = 200 m','Alt = 250 m','Alt = 300 m','Max Tension')
    subplot(3,2,2); hold on; grid on
    plot(flwSpd,R.thrL(:,alt));  xlabel('$V_\mathrm{flow}$ [m/s]');  ylabel('Tether [m]');  xlim([.1 0.5]);
    subplot(3,2,4); hold on; grid on
    plot(flwSpd,R.EL(:,alt));  xlabel('$V_\mathrm{flow}$ [m/s]');  ylabel('Elevation [deg]');  xlim([.1 0.5]);
end
%%  Determine opt tether tension limit based on average power
% maxT = 20:31;
% for i = 1:length(maxT)
%     fpath = fullfile(fileparts(which('OCTProject.prj')),'output','Tmax Study\');
%     load([fpath,sprintf('TmaxStudy_%dkN.mat',maxT(i))]);
%     for j = 1:length(altitude)
%         Ptemp = 1/(flwSpd(end)-flwSpd(1))*cumtrapz(flwSpd,R.Pmax1(:,j));  Pavg1(i,j) = Ptemp(end);
%     end
% end
%%  Determine opt tether tension limit based on flow resource 
% M1 = ENV.Manta(1);   M2 = ENV.Manta(2);   M3 = ENV.Manta(3);   M4 = ENV.Manta(4);
% M5 = ENV.Manta(5);   M6 = ENV.Manta(6);   M7 = ENV.Manta(7);   M8 = ENV.Manta(8);
% M9 = ENV.Manta(9);   M10 = ENV.Manta(10); M11 = ENV.Manta(11); M12 = ENV.Manta(12);
maxT = 20:38;   %Odepth = 500:-50:350;
tic
for i = 1:length(maxT)
    fpath = fullfile(fileparts(which('OCTProject.prj')),'output','Tmax Study\');
    load([fpath,sprintf('TmaxStudy_%dkN.mat',maxT(i))]);
    for j = 1:12
        [Pavg(i,j),vAvg(i,j),XYopt(:,i,j)] = eval(sprintf('M%d.powOptDepth(Odepth(1),flwSpd,R.Pmax1,altitude);',j));
        fprintf('i = %d;\tj = %d\n',i,j);
    end
end
toc
fpath = fullfile(fileparts(which('OCTProject.prj')),'output','Tmax Study\');
save([fpath,'Pout_20-38kN_500m.mat'],'maxT','Pavg','vAvg','XYopt');
%%  Plot 
fpath = fullfile(fileparts(which('OCTProject.prj')),'output','Tmax Study\');
D500 = load([fpath,'Pout_20-38kN_500m.mat']);
D450 = load([fpath,'Pout_20-38kN_450m.mat']);
D400 = load([fpath,'Pout_20-38kN_400m.mat']);
D350 = load([fpath,'Pout_20-38kN_350m.mat']);
% Pavg(Pavg==0) = NaN;
Title = {'January','February','March','April','May','June','July','August','September','October','November','December'};
figure;
for i = 1:12
    subplot(3,4,i); hold on; grid on;
    plot(D500.maxT,D500.Pavg(:,i),'r-');  
    plot(D450.maxT,D450.Pavg(:,i),'g-');  
    plot(D400.maxT,D400.Pavg(:,i),'b-');  
    plot(D350.maxT,D350.Pavg(:,i),'k-');  
    xlabel('$T_\mathrm{max}$ [kN]');  ylabel('Power [kW]');  title(Title{i});
    if i == 1
        legend('D = 500 m','D = 450 m','D = 400 m','D = 350 m','Orientation','horizontal')
    end
end
figure;
for i = 1:12
    subplot(3,4,i); hold on; grid on;
    plot(D500.maxT,D500.vAvg(:,i),'r-');  
    plot(D450.maxT,D450.vAvg(:,i),'g-');  
    plot(D400.maxT,D400.vAvg(:,i),'b-');  
    plot(D350.maxT,D350.vAvg(:,i),'k-');  
    xlabel('$T_\mathrm{max}$ [kN]');  ylabel('Power [kW]');  title(Title{i});
    if i == 1
        legend('D = 500 m','D = 450 m','D = 400 m','D = 350 m','location','northwest')
    end
end
%%  Save
fpath = fullfile(fileparts(which('OCTProject.prj')),'output','Tmax Study\');
save([fpath,sprintf('TmaxStudy_%dkN.mat',Tmaxx)],'flwSpd','altitude','thrLength','R','Tmaxx','depth','eff');
%%

%%  
maxT = 20:38;
figure;
for i = 1:3:numel(maxT)
    fpath = fullfile(fileparts(which('OCTProject.prj')),'output','Tmax Study\');
    load([fpath,sprintf('TmaxStudy_%dkN.mat',maxT(i))]);
    subplot(3,2,1); hold on; grid on;
    plot(flwSpd,R.Pmax(:,6));  xlabel('$V_\mathrm{flow}$ [m/s]');  ylabel('Power [kW]'); 
    subplot(3,2,6); hold on; grid on;
    plot(flwSpd,R.Fthr(:,6));  xlabel('$V_\mathrm{flow}$ [m/s]');  ylabel('Thr Drag [N]'); 
    subplot(3,2,2); hold on; grid on;
    plot(flwSpd,R.alpha(:,6));  xlabel('$V_\mathrm{flow}$ [m/s]');  ylabel('AoA [deg]'); 
    legend('Tmax = 20 kN','Tmax = 23 kN','Tmax = 26 kN','Tmax = 29 kN','Tmax = 32 kN','Tmax = 35 kN','Tmax = 38 kN')
    subplot(3,2,3); hold on; grid on;
    plot(flwSpd,R.Flift(:,6));  xlabel('$V_\mathrm{flow}$ [m/s]');  ylabel('Lift [N]'); 
    subplot(3,2,4); hold on; grid on;
    plot(flwSpd,R.Fdrag(:,6));  xlabel('$V_\mathrm{flow}$ [m/s]');  ylabel('Drag [N]'); 
end
%%
% T20 = load([fpath,sprintf('TmaxStudy_%dkN.mat',20)]);
% T38 = load([fpath,sprintf('TmaxStudy_%dkN.mat',38)]);
% Perr = (T38.R.Pmax1)


