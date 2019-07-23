clear;
clc
format compact
close all

scaleFactor = 1/1;
duration_s  = 500*sqrt(scaleFactor);

%% Set up simulation
VEHICLE         = 'vehicle000';
WINCH           = 'winch000';
TETHERS         = 'tether000';
GROUNDSTATION   = 'groundStation000';
ENVIRONMENT     = 'constantUniformFlow';
CONTROLLER      = 'threeTetherThreeSurfaceCtrl';
VARIANTSUBSYSTEM = 'NNodeTether';


%% Create busses
createConstantUniformFlowEnvironmentBus
createPlantBus;
createThreeTetherThreeSurfaceCtrlBus;


%% Set up environment
% Create
env = ENV.env;
env.addFlow({'water'},'FlowDensities',1000);
% Set Values
env.water.velVec.setValue([1 0 0],'m/s');
% Scale up/down
env.scale(scaleFactor);

%% Vehicle
% Create
vhcl = OCT.vehicle;
vhcl.numTethers.setValue(3,'');
vhcl.numTurbines.setValue(2,'');
vhcl.build('partDsgn1_lookupTables.mat');

% Set Values
BF = 1.25;
vhcl.Ixx.setValue(6303.1,'kg*m^2');
vhcl.Iyy.setValue(2080.7,'kg*m^2');
vhcl.Izz.setValue(8320.4,'kg*m^2');
vhcl.Ixy.setValue(0,'kg*m^2');
vhcl.Ixz.setValue(0.0,'kg*m^2');
vhcl.Iyz.setValue(0,'kg*m^2');
vhcl.volume.setValue(945352023e-9,'m^3');
vhcl.mass.setValue(vhcl.volume.Value*1000/BF,'kg');

vhcl.centOfBuoy.setValue([ 0 0 0]','m');
vhcl.thrAttch1.posVec.setValue([-0.25   -5.0000         0]','m');
vhcl.thrAttch2.posVec.setValue([ 5.75         0         0]','m');
vhcl.thrAttch3.posVec.setValue([-0.25    5.0000         0]','m');

vhcl.setICs('InitPos',[0 0 50],'InitEulAng',[0 3 0]*pi/180,'InitVel',[1 0 0]);

vhcl.turbine1.diameter.setValue(0,'m');
vhcl.turbine1.axisUnitVec.setValue([1 0 0]','');
vhcl.turbine1.attachPtVec.setValue([-1.25 -5 0]','m');
vhcl.turbine1.powerCoeff.setValue(0.5,'');
vhcl.turbine1.dragCoeff.setValue(0.8,'');

vhcl.turbine2.diameter.setValue(0,'m');
vhcl.turbine2.axisUnitVec.setValue([1 0 0]','');
vhcl.turbine2.attachPtVec.setValue([-1.25  5 0]','m');
vhcl.turbine2.powerCoeff.setValue(0.5,'');
vhcl.turbine2.dragCoeff.setValue(0.8,'');

% Scale up/down
vhcl.scale(scaleFactor);

%% Ground Station
% Create
gndStn = OCT.station;
gndStn.numTethers.setValue(3,'');
gndStn.build;

% Set values
gndStn.inertia.setValue(1,'kg*m^2');
gndStn.posVec.setValue([0 0 0],'m');
gndStn.dampCoeff.setValue(1,'(N*m)/(rad/s)');
gndStn.initAngPos.setValue(0,'rad');
gndStn.initAngVel.setValue(0,'rad/s');
gndStn.thrAttch1.posVec.setValue([-0.25   -5.0000         0],'m');
gndStn.thrAttch2.posVec.setValue([ 5.75         0         0],'m');
gndStn.thrAttch3.posVec.setValue([-0.25    5.0000         0],'m');
gndStn.freeSpnEnbl.setValue(false,'');


% Scale up/down
gndStn.scale(scaleFactor);

%% Tethers
% Create
thr = OCT.tethers;
thr.setNumTethers(3,'');
thr.setNumNodes(2,'');
thr.build;

% Set parameter values
thrDia = 0.005;


thr.tether1.initGndNodePos.setValue(gndStn.thrAttch1.posVec.Value(:),'m');
thr.tether1.initAirNodePos.setValue(vhcl.initPosVecGnd.Value(:)+rotation_sequence(vhcl.initEulAngBdy.Value)*vhcl.thrAttch1.posVec.Value(:),'m');
thr.tether1.initGndNodeVel.setValue([0 0 0]','m/s');
thr.tether1.initAirNodeVel.setValue(vhcl.initVelVecGnd.Value(:),'m/s');
thr.tether1.vehicleMass.setValue(vhcl.mass.Value,'kg');
thr.tether1.youngsMod.setValue(4e9,'Pa');
thr.tether1.dampingRatio.setValue(0.05,'');
thr.tether1.dragCoeff.setValue(0.5,'');
thr.tether1.density.setValue(1300,'kg/m^3');
thr.tether1.setDragEnable(true,'');
thr.tether1.setSpringDamperEnable(true,'');
thr.tether1.setNetBuoyEnable(false,'');
thr.tether1.setDiameter(thrDia,'m');

thr.tether2.initGndNodePos.setValue(gndStn.thrAttch1.posVec.Value(:),'m');
thr.tether2.initAirNodePos.setValue(vhcl.initPosVecGnd.Value(:)+rotation_sequence(vhcl.initEulAngBdy.Value)*vhcl.thrAttch2.posVec.Value(:),'m');
thr.tether2.initGndNodeVel.setValue([0 0 0]','m/s');
thr.tether2.initAirNodeVel.setValue(vhcl.initVelVecGnd.Value(:),'m/s');
thr.tether2.vehicleMass.setValue(vhcl.mass.Value,'kg');
thr.tether2.youngsMod.setValue(4e9,'Pa');
thr.tether2.dampingRatio.setValue(0.05,'');
thr.tether2.dragCoeff.setValue(0.5,'');
thr.tether2.density.setValue(1300,'kg/m^3');
thr.tether2.setDragEnable(true,'');
thr.tether2.setSpringDamperEnable(true,'');
thr.tether2.setNetBuoyEnable(false,'');
thr.tether2.setDiameter(thrDia*sqrt(2),'m');

thr.tether3.initGndNodePos.setValue(gndStn.thrAttch1.posVec.Value(:),'m');
thr.tether3.initAirNodePos.setValue(vhcl.initPosVecGnd.Value(:)+rotation_sequence(vhcl.initEulAngBdy.Value)*vhcl.thrAttch3.posVec.Value(:),'m');
thr.tether3.initGndNodeVel.setValue([0 0 0]','m/s');
thr.tether3.initAirNodeVel.setValue(vhcl.initVelVecGnd.Value(:),'m/s');
thr.tether3.vehicleMass.setValue(vhcl.mass.Value,'kg');
thr.tether3.youngsMod.setValue(4e9,'Pa');
thr.tether3.dampingRatio.setValue(0.05,'');
thr.tether3.dragCoeff.setValue(0.5,'');
thr.tether3.density.setValue(1300,'kg/m^3');
thr.tether3.setDragEnable(true,'');
thr.tether3.setSpringDamperEnable(true,'');
thr.tether3.setNetBuoyEnable(false,'');
thr.tether3.setDiameter(thrDia,'m');

% thr.designTetherDiameter(vhcl,env);

% Scale up/down
thr.scale(scaleFactor);


%% Winches
% Create
wnch = OCT.winches;
wnch.numWinches.setValue(3,'');
wnch.build;
% Set values
wnch.winch1.maxSpeed.setValue(1,'m/s');
wnch.winch1.timeConst.setValue(1,'s');
wnch.winch1.maxAccel.setValue(inf,'m/s^2');

wnch.winch2.maxSpeed.setValue(1,'m/s');
wnch.winch2.timeConst.setValue(1,'s');
wnch.winch2.maxAccel.setValue(inf,'m/s^2');

wnch.winch3.maxSpeed.setValue(1,'m/s');
wnch.winch3.timeConst.setValue(1,'s');
wnch.winch3.maxAccel.setValue(inf,'m/s^2');

wnch = wnch.setTetherInitLength(vhcl,env,thr);

% Scale up/down
wnch.scale(scaleFactor);


%% Set up controller
% Create
ctrl = CTR.controller;
% add filtered PID controllers
% FPID controllers are initialized to zero gains, 1s time const
ctrl.add('FPIDNames',{'tetherAlti','tetherPitch','tetherRoll','elevators','ailerons','rudder'},...
    'FPIDErrorUnits',{'m','rad','rad','deg','deg','deg'},...
    'FPIDOutputUnits',{'m/s','m/s','m/s','deg','deg','deg'});

% add control allocation matrix (implemented as a simple gain)
ctrl.add('GainNames',{'ctrlSurfAllocationMat','thrAllocationMat'},...
    'GainUnits',{'',''});

% add output saturation
ctrl.add('SaturationNames',{'outputSat'});

% add setpoints
ctrl.add('SetpointNames',{'altiSP','pitchSP','rollSP','yawSP'},...
    'SetpointUnits',{'m','deg','deg','deg'});

% tether controllers
ctrl.tetherAlti.kp.setValue(0,'(m/s)/(m)');
ctrl.tetherAlti.ki.setValue(0,'(m/s)/(m*s)');
ctrl.tetherAlti.kd.setValue(0,'(m/s)/(m/s)');
ctrl.tetherAlti.tau.setValue(0.5,'s');

ctrl.tetherPitch.kp.setValue(1,'(m/s)/(rad)');
ctrl.tetherPitch.ki.setValue(0,'(m/s)/(rad*s)');
ctrl.tetherPitch.kd.setValue(2,'(m/s)/(rad/s)');
ctrl.tetherPitch.tau.setValue(0.1,'s');

ctrl.tetherRoll.kp.setValue(0,'(m/s)/(rad)');
ctrl.tetherRoll.ki.setValue(0,'(m/s)/(rad*s)');
ctrl.tetherRoll.kd.setValue(0,'(m/s)/(rad/s)');
ctrl.tetherRoll.tau.setValue(0.01,'s');

ctrl.thrAllocationMat.setValue([1 .5 -.5; 1 -.5 0; 1 .5 .5],'');

% Set the values of the controller parameters
ctrl.ailerons.kp.setValue(0,'(deg)/(deg)');
ctrl.ailerons.ki.setValue(0,'(deg)/(deg*s)');
ctrl.ailerons.kd.setValue(0,'(deg)/(deg/s)');
ctrl.ailerons.tau.setValue(0.5,'s');

ctrl.elevators.kp.setValue(0,'(deg)/(deg)'); % do we really want to represent unitless values like this?
ctrl.elevators.ki.setValue(0,'(deg)/(deg*s)');
ctrl.elevators.kd.setValue(0,'(deg)/(deg/s)'); % Likewise, do we want (deg*s)/(deg) or just s?
ctrl.elevators.tau.setValue(0.01,'s');

ctrl.rudder.kp.setValue(0,'(deg)/(deg)');
ctrl.rudder.ki.setValue(0,'(deg)/(deg*s)');
ctrl.rudder.kd.setValue(0,'(deg)/(deg/s)');
ctrl.rudder.tau.setValue(0.5,'s');

ctrl.ctrlSurfAllocationMat.setValue([-1 0 0; 1 0 0; 0 -1 0; 0 0 1],'');


ctrl.outputSat.upperLimit.setValue(30,'');
ctrl.outputSat.lowerLimit.setValue(-30,'');

% Calculate setpoints
timeVec = 0:0.1:duration_s;
ctrl.altiSP.Value = timeseries(100*ones(size(timeVec)),timeVec);
ctrl.altiSP.Value.DataInfo.Units = 'm';

ctrl.pitchSP.Value = timeseries(5*ones(size(timeVec)),timeVec);
ctrl.pitchSP.Value.DataInfo.Units = 'deg';

ctrl.rollSP.Value = timeseries(25*sign(sin(2*pi*timeVec/(120))),timeVec);
ctrl.rollSP.Value.Data(timeVec<120) = 0;
ctrl.rollSP.Value.DataInfo.Units = 'deg';

ctrl.yawSP.Value = timeseries(0*ones(size(timeVec)),timeVec);
ctrl.yawSP.Value.DataInfo.Units = 'deg';

% Scale up/down
ctrl = ctrl.scale(scaleFactor);

%% Run the simulation
try
    simWithMonitor('OCTModel',2)
catch
    simWithMonitor('OCTModel',2)
end
% Run stop callback to plot everything

plotAyaz

