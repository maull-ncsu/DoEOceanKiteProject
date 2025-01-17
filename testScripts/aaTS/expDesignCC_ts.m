%% Test script for John to control the kite model
clear;clc;%close all;
Simulink.sdi.clear
%%  Select sim scenario
%   0 = fig8;   1.a = fig8-2rot;   2.a = fig8-winch;   3.a = Steady   4.a = LaR

%%  Set Test Parameters
saveSim = 0;              %   Flag to save results
runLin = 1;                %   Flag to run linearization
thrArray = 3;%[200:400:600];%:25:600];
altitudeArray = 1.5;%[100:200:300];%150:25:300];
flwSpdArray = -1;%[0.1:0.1:.5]; 
distFreq = 0;
distAmp = 0;
pertVec = [0 1 0];
h = 5*pi/180;  w = 40*pi/180;                              %   rad - Path width/height
for j = 1:length(h)
    for k = 1:length(w)
thrLength = 15;  altitude = 7.5;  elev = atan2(altitude,thrLength);               %   Initial tether length/operating altitude/elevation angle 
flwSpd = flwSpdArray ;                                              %   m/s - Flow speed
Tmax = 38;                                                  %   kN - Max tether tension 

[a,b] = boothParamConversion(w(k),h(j));                          %   Path basis parameters
%%  Load components
fpath = fullfile(fileparts(which('OCTProject.prj')),...
    'vehicleDesign\Tether\Tension\');
maxT = load([fpath,sprintf('TmaxStudy_%dkN.mat',Tmax)]);
el = -asin(altitude/thrLength);
loadComponent('pathFollowCtrlExp');                 %   Path-following controller with AoA control
FLIGHTCONTROLLER = 'pathFollowingControllerExp';
loadComponent('oneDoFGSCtrlBasic');                         %   Ground station controller
loadComponent('MantaGndStn');                               %   Ground station
loadComponent('winchManta');                                %   Winches
loadComponent('MantaTether');                           %   Manta Ray tether
loadComponent('idealSensors')                               %   Sensors
loadComponent('idealSensorProcessing')                      %   Sensor processing
loadComponent('Manta2RotXFoil_AR8_b8_exp2');                             %   AR = 8; 8m span
SIXDOFDYNAMICS        = "sixDoFDynamicsCoupledFossen12Int";
%%  Environment Properties
loadComponent('ConstXYZT');                                 %   Environment
env.water.setflowVec([flwSpd 0 0],'m/s');               %   m/s - Flow speed vector
    ENVIRONMENT = 'environmentManta2RotBandLin';                   %   Two turbines
%%  Set basis parameters for high level controller

loadComponent('constBoothLem');        %   High level controller
% PATHGEOMETRY = 'lemOfBoothInv'
% hiLvlCtrl.elevationLookup.setValue(maxT.R.EL,'deg');
% 
% hiLvlCtrl.ELctrl.setValue(1,'');
% hiLvlCtrl.ELslew.setValue(0.25,'deg/s');
% hiLvlCtrl.ThrCtrl.setValue(1,'');

hiLvlCtrl.basisParams.setValue([a,b,-el,180*pi/180,thrLength-.1],'[rad rad rad rad m]') % Lemniscate of Booth
%%  Ground Station Properties

gndStn.posVec.setValue([0 0 3],'m')
%%  Vehicle Properties
vhcl.setICsOnPath(.85,PATHGEOMETRY,hiLvlCtrl.basisParams.Value,gndStn.posVec.Value,6.5*abs(flwSpd)*norm([1;0;0]))

%%  Tethers Properties
load([fileparts(which('OCTProject.prj')),'\vehicleDesign\Tether\tetherDataNew.mat']);
thr.tether1.initGndNodePos.setValue(gndStn.thrAttch1.posVec.Value(:)+gndStn.posVec.Value(:),'m');
thr.tether1.initAirNodePos.setValue(vhcl.initPosVecGnd.Value(:)...
    +rotation_sequence(vhcl.initEulAng.Value)*vhcl.thrAttchPts_B.posVec.Value,'m');
thr.tether1.initGndNodeVel.setValue([0 0 0]','m/s');
thr.tether1.initAirNodeVel.setValue(vhcl.initVelVecBdy.Value(:),'m/s');
thr.tether1.vehicleMass.setValue(vhcl.mass.Value,'kg');
thr.tether1.youngsMod.setValue(eval(sprintf('AR8b8.length600.tensionValues%d.youngsMod',Tmax)),'Pa');
thr.tether1.density.setValue(eval(sprintf('AR8b8.length600.tensionValues%d.density',Tmax)),'kg/m^3');
thr.tether1.setDiameter(.0076,'m');
thr.setNumNodes(5,'');
thr.tether1.setDragCoeff(1.8,'');
%%  Winches Properties
wnch.setTetherInitLength(vhcl,gndStn.posVec.Value,env,thr,env.water.flowVec.Value);
wnch.winch1.LaRspeed.setValue(1,'m/s');
%%  Controller User Def. Parameters and dependant properties
fltCtrl.setFcnName(PATHGEOMETRY,'');
fltCtrl.setInitPathVar(vhcl.initPosVecGnd.Value,hiLvlCtrl.basisParams.Value,gndStn.posVec.Value);
fltCtrl.setPerpErrorVal(.25,'rad')
fltCtrl.rudderGain.setValue(0,'')
fltCtrl.rollMoment.kp.setValue(50,'(N*m)/(rad)')
fltCtrl.rollMoment.ki.setValue(0,'(N*m)/(rad*s)');
fltCtrl.rollMoment.kd.setValue(25,'(N*m)/(rad/s)')
fltCtrl.tanRoll.kp.setValue(.45,'(rad)/(rad)')
thr.tether1.dragEnable.setValue(1,'')
vhcl.hStab.setIncidence(-2,'deg');
vhcl.setBuoyFactor(.98,'')
vhcl.setRBridle_LE([0.029;0;-0.1],'m')
vhcl.setRCentOfBuoy_LE([.080;0;0.003],'m')
vhcl.setRCM_LE([0.091,0,0],'m')
%%  Set up critical system parameters and run simulation
    simParams = SIM.simParams;  simParams.setDuration(50    ,'s');  dynamicCalc = '';
%     open_system('OCTModel')
%     set_param('OCTModel','SimulationMode','accelerator');
    simWithMonitor('OCTModel')
    tsc{j,k} = signalcontainer(logsout);
    %%
%     vhcl.animateSim(tsc{j,k},1,'PathFunc',fltCtrl.fcnName.Value,...
%      'PlotTracer',true,'FontSize',18)
    lap = max(tsc{j,k}.lapNumS.Data)-1;
    tsc{j,k}.plotFlightResults(vhcl,env,'plot1Lap',1==1,'plotS',1==1,'lapNum',lap,'dragChar',1==0);
    end
end
% 
% %     Pow = tsc.rotPowerSummary(vhcl,env);
%     [Idx1,Idx2] = tsc.getLapIdxs(max(tsc.lapNumS.Data)-2);  ran = [Idx1:Idx2]';
%     AoA = mean(squeeze(tsc.vhclAngleOfAttack.Data(:,:,ran)));
%     airNode = squeeze(sqrt(sum(tsc.airTenVecs.Data.^2,1)));
%     gndNode = squeeze(sqrt(sum(tsc.gndNodeTenVecs.Data.^2,1)))*1e-3;
%     ten = max([max(airNode(ran)) max(gndNode(ran))]);
%     fprintf('Average AoA = %.3f;\t Max Tension = %.1f N\n\n',AoA,ten);
%     path = squeeze(tsc.closestPathVariable.Data(ran));
%     figure; 
%     subplot(3,1,1); grid on; hold on;
%     plot(path,squeeze(tsc.MFluidBdy.Data(1,1,ran)))
%     plot(path,squeeze(tsc.MThrNetBdy.Data(1,1,ran)))
%       subplot(3,1,2); grid on; hold on;
%     plot(path,squeeze(tsc.MFluidBdy.Data(2,1,ran)))
%     plot(path,squeeze(tsc.MThrNetBdy.Data(2,1,ran)))
%     subplot(3,1,3); grid on; hold on;
%     plot(path,squeeze(tsc.MFluidBdy.Data(3,1,ran)))
%     plot(path,squeeze(tsc.MThrNetBdy.Data(3,1,ran)))
% 
%     xlabel('Path Position (s)')
%     ylabel('Z Moment [Nm]')
%     legend('Fluid','Tether')
%     
%     
%     figure; 
%     subplot(3,1,1); grid on; hold on; sgtitle('Ctrl Deflection [deg]')
%     plot(path,squeeze(tsc.ctrlSurfDeflCmd.Data(ran,1)))
%     plot(path,squeeze(tsc.ctrlSurfDeflCmd.Data(ran,2)))
%     ylabel('Aileron'); legend('Port','Starboard')
%       subplot(3,1,2); grid on; hold on;
%     plot(path,squeeze(tsc.ctrlSurfDeflCmd.Data(ran,3)))
%     ylabel('Elevator')
%     subplot(3,1,3); grid on; hold on;
%     plot(path,squeeze(tsc.ctrlSurfDeflCmd.Data(ran,4)))
% 
%     xlabel('Path Position (s)')
%     ylabel('Rudder')
%     
%         figure; 
%     grid on; hold on;
%     plot(path,squeeze(tsc.tanRoll.Data(ran)))
%     plot(path,squeeze(tsc.tanRollDes.Data(ran)),'k')
%     legend('Tan Roll','Tan Roll SP')
%    
%         figure; 
%     subplot(3,1,1); grid on; hold on; ylabel('X-Moment [Nm]');
%     plot(path,squeeze(tsc.MNetBdy.Data(1,1,ran)))
%     plot(path,squeeze(tsc.MFluidBdy.Data(1,1,ran)))
%     plot(path,squeeze(tsc.desiredMoment.Data(ran,1)))
%     
%     subplot(3,1,2); grid on; hold on; ylabel('Y-Moment [Nm]');
%     plot(path,squeeze(tsc.MNetBdy.Data(2,1,ran)))
%     plot(path,squeeze(tsc.MFluidBdy.Data(2,1,ran)))
%     plot(path,squeeze(tsc.desiredMoment.Data(ran,2)))
%     
%     subplot(3,1,3); grid on; hold on; ylabel('Z-Moment [Nm]');
%     plot(path,squeeze(tsc.MNetBdy.Data(3,1,ran)))
%     plot(path,squeeze(tsc.MFluidBdy.Data(3,1,ran)))
%     plot(path,squeeze(tsc.desiredMoment.Data(ran,3)))
% 
%     xlabel('Path Position (s)')
% 
%     legend('Net','Fluid','Desired')
%     
% dt = datestr(now,'mm-dd_HH-MM');
% %%
% 
% % simParams = SIM.simParams;  simParams.setDuration(10000,'s');  dynamicCalc = '';
% % simWithMonitor('OCTModel');
% % tsc = signalcontainer(logsout);   
% % lap = max(tsc.lapNumS.Data)-1;
% % tsc.plotFlightError(vhcl,env,'plot1Lap',1==1,'plotS',1==1,'lapNum',lap,'dragChar',1==0)
    filename = sprintf('forDeba.mat');
    fpath = fullfile(fileparts(which('OCTProject.prj')),'output','Manta\');
% if saveSim == 1
%     if max(tsc.lapNumS.Data) > 1
%     save(strcat(fpath,filename),'vhcl','thr','fltCtrl','env','linsys','simParams','LIBRARY','gndStn','tsc','tsc1','tsc2','tsc3')
%     end
% end
%     end
% end
%%  Plot Results
    lap = max(tsc{1,1}.lapNumS.Data)-1;
    if max(tsc.lapNumS.Data) < 2
        tsc.plotFlightResults(vhcl,env,'plot1Lap',1==0,'plotS',1==1,'lapNum',lap,'dragChar',1==0);
    else
        tsc{1,1}.plotFlightResults(vhcl,env,'plot1Lap',1==1,'plotS',1==1,'lapNum',lap,'dragChar',1==0);
        tsc{1,1}.plotFlightError(vhcl,env,'plot1Lap',1==1,'plotS',1==1,'lapNum',lap,'dragChar',1==0);
    end

%%  Animate Simulation
% if simScenario <= 2
    vhcl.animateSim(tsc1{1,1},2,'TracerDuration',20,...
        'GifTimeStep',0,'PlotTracer',true,'FontSize',12,'Pause',1==0,...
        'GifFile','expCross.gif','timestep',0.1,'View',[0,0]);
% else
%     vhcl.animateSim(tsc,.25,'Pause',1==0,'PathFunc',fltCtrl.fcnName.Value,...
%         'GifTimeStep',.01,'PlotTracer',true,'FontSize',12,'ZoomIn',1==0,...
%         'PathPosition',true,'SaveGif',1==3,'GifFile','awwSnap.gif',...
%         'TracerDuration',200)%,'starttime',350);

% end
%%  Compare to old results
% Res = load('C:\Users\John Jr\Desktop\Manta Ray\Model 9_28\Results\Manta 2.0\Rotor\Turb1.0_V-0.300_EL-30.0_D-0.70_AoA-13.98_10-22_12-29.mat');
% Res.tsc.rotPowerSummary(Res.vhcl,Res.env);
% [Idx1,Idx2] = Res.tsc.getLapIdxs(max(Res.tsc.lapNumS.Data)-1);  ran = Idx1:Idx2;
% AoA = mean(squeeze(Res.tsc.vhclAngleOfAttack.Data(:,:,ran)));
% airNode = squeeze(sqrt(sum(Res.tsc.airTenVecs.Data.^2,1)))*1e-3;
% gndNode = squeeze(sqrt(sum(Res.tsc.gndNodeTenVecs.Data.^2,1)))*1e-3;
% ten = max([max(airNode(ran)) max(gndNode(ran))]);
% fprintf('Average AoA = %.3f;\t Max Tension = %.1f kN\n',AoA,ten);
        
%     figure; 
%     subplot(3,1,1); grid on; hold on; ylabel('Roll [deg]');
%     plot(tsc.eulerAngles.Time,180/pi*squeeze(tsc.eulerAngles.Data(1,1,:)))
%            xlabel('Time [s]')
%     subplot(3,1,2); grid on; hold on; ylabel('Pitch [deg]');
%     plot(tsc.eulerAngles.Time,180/pi*squeeze(tsc.eulerAngles.Data(2,1,:)))
%           xlabel('Time [s]')  
%     subplot(3,1,3); grid on; hold on; ylabel('Yaw [deg]');
%     plot(tsc.eulerAngles.Time,180/pi*squeeze(tsc.eulerAngles.Data(3,1,:)))
%         xlabel('Time [s]')
%     figure; 
%     subplot(3,1,1); grid on; hold on; ylabel('Roll Rate [deg/s]');
%     plot(tsc.eulerAngles.Time,180/pi*squeeze(tsc.angularVel.Data(1,1,:)))
%           xlabel('Time [s]') 
%     subplot(3,1,2); grid on; hold on; ylabel('Pitch Rate [deg/s]');
%     plot(tsc.eulerAngles.Time,180/pi*squeeze(tsc.angularVel.Data(2,1,:)))
%          xlabel('Time [s]')   
%     subplot(3,1,3); grid on; hold on; ylabel('Yaw Rate [deg/s]');
%     plot(tsc.eulerAngles.Time,180/pi*squeeze(tsc.angularVel.Data(3,1,:)))
%     xlabel('Time [s]')

