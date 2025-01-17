%% Test script for James to control the kite model
clear;clc;close all;
Simulink.sdi.clear
%%  Select sim scenario
%   0 = fig8;   1.a = fig8-2rot;   2.a = fig8-winch;   3.a = Steady   4.a = LaR

%%  Set Test Parameters
saveSim = 0;              %   Flag to save results
runLin = 1;                %   Flag to run linearization
thrArray = 5;

flwSpdArray = 1;


for j = 1:length(thrArray)
    for k = 1:length(flwSpdArray)
        thrLength = thrArray(j);            %   Initial tether length/operating altitude/elevation angle
        flwSpd = flwSpdArray(k) ;                                              %   m/s - Flow speed
        %   kN - Max tether tension
        %         h = 2*asin(2/2/thrLength );  w = 2*asin(6/2/thrLength );                              %   rad - Path width/height
        %         [a,b] = boothParamConversion(w,h);
        
        
        %   Path basis parameters
        %%  Load components
        
     
        loadComponent('jamesMultiCycleExp');                 %   Path-following controller with AoA control
        % FLIGHTCONTROLLER = 'pathFollowingControllerExp';
        FLIGHTCONTROLLER = 'takeOffToLanding';
        loadComponent('oneDoFGSCtrlBasic');                         %   Ground station controller
        loadComponent('pathFollowingGndStn');
        loadComponent('oneDOFWnch');                                %   Winches
        loadComponent('poolTether');                               %   Manta Ray tether

        loadComponent('lasPosEst')                               %   Sensors
        loadComponent('lineAngleSensor');

        loadComponent('idealSensorProcessing')                      %   Sensor processing
        loadComponent('poolScaleKiteAbney');                %   AR = 8; 8m span
        SIXDOFDYNAMICS        = "sixDoFDynamicsCoupledFossen12int";
        %%  Environment Properties
        loadComponent('ConstXYZT');                                 %   Environment
        env.water.setflowVec([flwSpd 0 0],'m/s');               %   m/s - Flow speed vector
        ENVIRONMENT = 'env2turb';                   %   Two turbines
        FLOWCALCULATION = 'rampSaturatedXYZT';
        rampSlope = .05; %flow speed ramp rate
        %%  Set basis parameters for high level controller
        
        
        %         loadComponent('constBoothLem');        %   High level controller
        %
        %         hiLvlCtrl.basisParams.setValue([a,b,deg2rad(25),0*pi/180,thrLength-.1],'[rad rad rad rad m]') % Lemniscate of Booth
        
        loadComponent('constBoothLem');        %   High level controller
        PATHGEOMETRY = 'lemBoothNew';
%         a = 2*thrLength*sin(w/2);
%         b = 2*thrLength*sin(h/2);
        a = 6
        b = 2
        %                     h = 2*asin(b/2/thrLength );  w = 2*asin(a/2/thrLength );                              %   rad - Path width/height
        %         [a,b] = boothParamConversion(w,h);
        hiLvlCtrl.basisParams.setValue([a,b,deg2rad(25),0,thrLength],'[rad rad rad rad m]') % Lemniscate of Booth
        
        %%  Ground Station Properties
        
        gndStn.posVec.setValue([0 0 0],'m')
        elevArray = 70*pi/180;
        %%  Vehicle Properties
        % vhcl.setICsOnPath(.85,PATHGEOMETRY,hiLvlCtrl.basisParams.Value,gndStn.posVec.Value,6.5*flwSpd*norm([1;0;0]))

        vhcl.initPosVecGnd.setValue([cos(elevArray) 0 sin(elevArray)]*thrLength,'m')

        vhcl.initAngVelVec.setValue([0;0;0],'rad/s')
        vhcl.initVelVecBdy.setValue([0;0;0],'m/s')
        vhcl.initEulAng.setValue([0;0;0],'rad')
        
        %%%%
        % Initialize LAS
        %%%%
        pos = vhcl.initPosVecGnd.Value;
        x = pos(1);
        y = pos(2);
        z = pos(3);
        az1 = atan2(y,x);
        el1 = atan2(z,sqrt(x.^2 + y.^2));
        las.setThrInitAng([el1 az1],'rad');
        las.setInitAngVel([-0 0],'rad/s');
        %%  Tethers Properties
        load([fileparts(which('OCTProject.prj')),'\vehicleDesign\Tether\tetherDataNew.mat']);
        thr.tether1.initGndNodePos.setValue(gndStn.thrAttch1.posVec.Value(:)+gndStn.posVec.Value(:),'m');
        thr.tether1.initAirNodePos.setValue(vhcl.initPosVecGnd.Value(:)...
            +rotation_sequence(vhcl.initEulAng.Value)*vhcl.thrAttchPts_B.posVec.Value,'m');
        thr.tether1.initGndNodeVel.setValue([0 0 0]','m/s');
        thr.tether1.initAirNodeVel.setValue(vhcl.initVelVecBdy.Value(:),'m/s');
        thr.tether1.vehicleMass.setValue(vhcl.mass.Value,'kg');
        thr.tether1.setDiameter(.0076,'m');
        thr.setNumNodes(4,'');
        thrDrag =   1.8;
        thr.tether1.setDragCoeff(thrDrag,'');
        
        %% LAS
        pos = vhcl.initPosVecGnd.Value;
        x = pos(1);
        y = pos(2);
        z = pos(3);
        az1 = atan2(y,x);
        el1 = atan2(z,sqrt(x.^2 + y.^2));
        las.setThrInitAng([el1 az1],'rad');
        las.setInitAngVel([-0 0],'rad/s');
        %%  Winches Properties
        wnch.setTetherInitLength(vhcl,gndStn.posVec.Value,env,thr,env.water.flowVec.Value);
        wnch.winch1.LaRspeed.setValue(1,'m/s');
        %%  Controller User Def. Parameters and dependant properties
        fltCtrl.setFcnName(PATHGEOMETRY,'');
        fltCtrl.setInitPathVar(vhcl.initPosVecGnd.Value,hiLvlCtrl.basisParams.Value,gndStn.posVec.Value);
        %         fltCtrl.setPerpErrorVal(.25,'rad')
        thr.tether1.dragEnable.setValue(1,'')
        
        fltCtrl.initPathVar.setValue(0,'')
        
        %% Start Control
        flowSpeedOpenLoop = .03;
        
        %% degredations
        vhcl.stbdWing.setGainCL(vhcl.stbdWing.gainCL.Value/8,'1/deg');
        vhcl.portWing.setGainCL(vhcl.portWing.gainCL.Value/8,'1/deg');
        vhcl.stbdWing.setGainCD(vhcl.stbdWing.gainCD.Value/8,'1/deg');
        vhcl.portWing.setGainCD(vhcl.portWing.gainCD.Value/8,'1/deg');
        vhcl.vStab.setGainCL(vhcl.vStab.gainCL.Value/2,'1/deg');
        vhcl.vStab.setGainCD(vhcl.vStab.gainCD.Value/2,'1/deg');
        
        thr.tether1.youngsMod.setValue(10e9,'Pa');
        %%  Set up critical system parameters and run simulation

        simParams = SIM.simParams;  simParams.setDuration(500,'s');  dynamicCalc = '';
         simWithMonitor('OCTModel')
        tsc = signalcontainer(logsout);
        
    end
end

% and(r > maxR, or(and(pathVar>.3,pathVar<.4),and(pathVar>.8,pathVar<.9)))
% Save for later
%% Calculate mean velocity
tsc1 = resample(tsc,.01);
currentState = tsc1.currentState.Data;
vels=tsc1.velocityVec.Data(:,:,:);%[(1-tsc.velocityVec.Data(1,1,:)); tsc.velocityVec.Data(2:3,1,:)];
velmags = sqrt(sum((vels).^2,1));
velmags3 = squeeze(velmags(currentState ==3));
plot(velmags3(2000:end))
meanVel = mean(velmags3(2000:end))
% %% Animate Sim
%
vhcl.animateSim(tsc,.3,...
    'PlotTracer',false,'FontSize',18,'starttime',150,'endtime',400,'SaveGif',1==1,'GifTimeStep',.01)





