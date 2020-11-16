clear;
clc;
% close all;

cd(fileparts(mfilename('fullpath')));

simParams = SIM.simParams;
simParams.setDuration(3*60,'s');
dynamicCalc = '';
flowSpeed = 10;
thrLength = 1000;
% rad - Mean elevation angle
initElevation = 20*pi/180;    
% rad - Path width/height
w = 40*pi/180;          
h = 8*pi/180;  
% Path basis parameters
[a,b] = boothParamConversion(w,h);      

%% Load components
% Spooling controller
SPOOLINGCONTROLLER = 'netZeroSpoolingController';
% Ground station controller
loadComponent('oneDoFGSCtrlBasic');
% Ground station
loadComponent('pathFollowingGndStn');
% Winches
loadComponent('ayazFullScaleOneThrWinch');
% Tether
loadComponent('ayazAirborneThr');
% Sensors
loadComponent('idealSensors');
% Sensor processing
loadComponent('idealSensorProcessing');
% Vehicle
loadComponent('ayazAirborneVhcl');

% High level controller
loadComponent('constBoothLem');
hiLvlCtrl.basisParams.setValue([a,b,initElevation,0*pi/180,thrLength],'[rad rad rad rad m]');
% loadComponent('gpkfPathOpt');

% hiLvlCtrl.maxStepChange        = (40/thrLength)*180/pi;
% hiLvlCtrl.minVal               = 5;
% hiLvlCtrl.maxVal               = 45;
% hiLvlCtrl.basisParams.Value = [a,b,initElevation,0*pi/180,thrLength]';
% hiLvlCtrl.initVals          = hiLvlCtrl.basisParams.Value(3)*180/pi;
% hiLvlCtrl.rateLimit         = 0.1;
% hiLvlCtrl.kfgpTimeStep      = 5/60;
% hiLvlCtrl.mpckfgpTimeStep   = 2;

% Environment
loadComponent('ayazAirborneFlow');
env.water.flowVec.setValue([flowSpeed;0;0],'m/s');

cIn = maneuverabilityAdvanced(vhcl);
cIn.meanElevationInRadians = initElevation;
cIn.pathWidth = w*180/pi;
cIn.pathHeight = h*180/pi;
cIn.tetherLength = thrLength;
minCur = cIn.calcMinCurvature;
pLength = cIn.pathLength;

figure(10);
pR = cIn.plotPathRadiusOfCurvature;


%% Ground Station IC's and dependant properties
gndStn.setPosVec([0 0 0],'m')
gndStn.initAngPos.setValue(0,'rad');
gndStn.initAngVel.setValue(0,'rad/s');

%% Set vehicle initial conditions
vhcl.setICsOnPath(...
    .05,... % Initial path position
    PATHGEOMETRY,... % Name of path function
    hiLvlCtrl.basisParams.Value,... % Geometry parameters
    gndStn.posVec.Value,... % Center point of path sphere
    (11/2)*norm(env.water.flowVec.Value))   % Initial speed

%% Tethers IC's and dependant properties
thr.tether1.initGndNodePos.setValue(gndStn.thrAttch1.posVec.Value(:)...
    +gndStn.posVec.Value(:),'m');
thr.tether1.initAirNodePos.setValue(vhcl.initPosVecGnd.Value(:)...
    +rotation_sequence(vhcl.initEulAng.Value)*vhcl.thrAttchPts_B.posVec.Value,'m');

thr.tether1.initGndNodeVel.setValue([0 0 0]','m/s');
thr.tether1.initAirNodeVel.setValue(vhcl.initVelVecBdy.Value(:),'m/s');

thr.tether1.vehicleMass.setValue(vhcl.mass.Value,'kg');

%% Winches IC's and dependant properties
wnch.setTetherInitLength(vhcl,gndStn.posVec.Value,env,thr,env.water.flowVec.Value);

%% Run Simulation
loadComponent('ayazPathFollowingAirborne');
fltCtrl.setFcnName(PATHGEOMETRY,'');
fltCtrl.setInitPathVar(vhcl.initPosVecGnd.Value,...
    hiLvlCtrl.basisParams.Value,...
    gndStn.posVec.Value);

fltCtrl.elevatorReelInDef.setValue(0,'deg');
fltCtrl.rudderGain.setValue(0,'');
fltCtrl.yawMoment.kp.setValue(0,'(N*m)/(rad)');

keyboard
simWithMonitor('OCTModel');

tscOld = signalcontainer(logsout);
statOld = computeSimLapStats(tscOld);
trackOld = statOld{2,3}/cIn.pathLength;

%%
loadComponent('guidanceLawPathFollowingAir');
fltCtrl.setFcnName(PATHGEOMETRY,'');
fltCtrl.setInitPathVar(vhcl.initPosVecGnd.Value,...
    hiLvlCtrl.basisParams.Value,...
    gndStn.posVec.Value);

fltCtrl.elevatorReelInDef.setValue(0,'deg');
fltCtrl.rudderGain.setValue(0,'');
fltCtrl.yawMoment.kp.setValue(0,'(N*m)/(rad)');
keyboard
simWithMonitor('OCTModel');

tscNew = signalcontainer(logsout);
statsNew = computeSimLapStats(tscNew);
trackNew = statsNew{2,3}/cIn.pathLength;

%%  Log Results
% dt = datestr(now,'mm-dd_HH-MM');
% % save file location
% 
% [status, msg, msgID] = mkdir(fullfile(fileparts(which('OCTProject.prj')),'outputs'));
% fpath = fullfile(fileparts(which('OCTProject.prj')),'outputs\');
% filename = sprintf(strcat('FS-%.1f_w-%.1f_h-%.1f_',dt,'.mat'),el*180/pi,w*180/pi,h*180/pi);
% save(strcat(fpath,filename),'tsc','vhcl','thr','fltCtrl','env','simParams')

%%
close all
fn = 1;
figure(fn)
pOSP = plot(tscOld.tanRollDes.Time,tscOld.tanRollDes.Data(:)*180/pi,'b-');
hold on
plot(tscOld.tanRoll.Time,tscOld.tanRoll.Data*180/pi,'b--');
pNSP = plot(tscNew.tanRollDes.Time,tscNew.tanRollDes.Data(:)*180/pi,'r-');
plot(tscNew.tanRoll.Time,tscNew.tanRoll.Data*180/pi,'r--');
ylabel('Tangent roll [deg]');
legend([pOSP,pNSP],{'Old SP','New SP'})



fn = fn+1;
figure(fn);
plot(tscOld.tanRoll.Time,squeeze(vecnorm(tscOld.velCMvec.Data)),'b-');
hold on;
plot(tscNew.tanRoll.Time,squeeze(vecnorm(tscNew.velCMvec.Data)),'r-');
ylabel('Speed [m/s]');

fn = fn+1;
figure(fn);
plot(tscOld.tanRoll.Time,tscOld.vhclVapp.Data(1,:).^3,'b-');
hold on;
plot(tscNew.tanRoll.Time,tscNew.vhclVapp.Data(1,:).^3,'r-');
ylabel('Apparent vel. in x cubed [$m^3/s^3$]');

fn = fn+1;
figure(fn);
plot(tscOld.tanRoll.Time,tscOld.turbPow.Data(:)./1e3,'b-');
hold on;
plot(tscNew.tanRoll.Time,tscNew.turbPow.Data(:)./1e3,'r-');
ylabel('Power [kW]');

fn = fn+1;
figure(fn);
plot(tscOld.vWindFuseGnd.Time,squeeze(tscOld.vWindFuseGnd.Data(1,1,:)),'b-');
hold on;
plot(tscNew.vWindFuseGnd.Time,squeeze(tscNew.vWindFuseGnd.Data(1,1,:)),'r-');
ylabel('Flow speed at kite [m/s]');

allAxes = findall(0,'type','axes');
allPlots = findall(0,'type','Line');
xlabel(allAxes,'Time [sec]');
grid(allAxes,'on');

for ii = 2:fn
    figure(ii);
    legend({'Old','New'});
end

set(allPlots,'linewidth',1);
set(allAxes,'FontSize',12);
xlim(allAxes,[0 tscNew.tanRoll.Time(end)]);
figNames = {'desTanRoll','speed','pSurrog'};

% for ii = 1:fn
%     figure(ii);
%     exportgraphics(gca,[figNames{ii},'.png'],'Resolution',600);
% end

%%
if strcmpi(FLIGHTCONTROLLER,'guidanceLawPathFollowing')
    desPlots = {'currentPathVar','forwardLookup','minDistFromPath',...
        'rollGain','targetAngle','tanRollDes'};
    figure(12);
    tData = tscNew.velocityVec.Time(:);
    sb = gobjects;

    for ii = 1:length(desPlots)
        sb(ii) = subplot(ceil(length(desPlots)/2),2,ii);
        if ismember(ii,[5,6])
            pData = tscNew.(desPlots{ii}).Data(:)*180/pi;
        elseif ii == 1
            pData = mod(tscNew.(desPlots{ii}).Data(:),1);
        else
            pData = tscNew.(desPlots{ii}).Data(:);
        end
        
        plot(tData,pData);
        ylabel(desPlots{ii});
        hold on;
        if ii == 1
            yticks(0:0.25:1)
        end
        
    end
    grid(sb(:),'minor');
    xlabel(sb(:),'Time [s]');
    linkaxes(sb(:),'x');
    lastTwoLaps = tscNew.lapNumS.Data(:)>max(tscNew.lapNumS.Data(:))-2;
    xlim(sb(:),[0 tData(end)]);
    
%      xlim(sb.Children(:),[min(tData(lastTwoLaps)) max(tData(lastTwoLaps))]);
%     exportgraphics(gcf,['newConRes','.png'],'Resolution',600);

end

%%
GG.saveGifs = true;
GG.timeStep = 1;
GG.gifTimeStep = 0.1;

vhcl.animateSim(tscOld,GG.timeStep,...
    'PathFunc',fltCtrl.fcnName.Value,'pause',false,'plotTarget',false,...
    'SaveGif',GG.saveGifs,'GifTimeStep',GG.gifTimeStep,'GifFile','AirOldGif.gif');

oldAx = gca;

try
vhcl.animateSim(tscNew,GG.timeStep,...
    'PathFunc',fltCtrl.fcnName.Value,'pause',false,'plotTarget',true,...
    'SaveGif',GG.saveGifs,'GifTimeStep',GG.gifTimeStep,'GifFile','AirNewGif.gif',...
    'XLim',oldAx.XLim,'YLim',oldAx.YLim,'ZLim',oldAx.ZLim);
catch
    vhcl.animateSim(tscNew,GG.timeStep,...
    'PathFunc',fltCtrl.fcnName.Value,'pause',true,'plotTarget',true,...
    'SaveGif',GG.saveGifs,'GifTimeStep',GG.gifTimeStep,'GifFile','AirNewGif.gif');
end

