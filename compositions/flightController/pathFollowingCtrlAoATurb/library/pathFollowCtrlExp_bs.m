FLIGHTCONTROLLER = 'pathFollowingControllerExp';
SPOOLINGCONTROLLER = 'netZeroSpoolingController';

fltCtrl = CTR.periodicExp;

fltCtrl.maxBank.upperLimit.setValue(.8,'');
fltCtrl.maxBank.lowerLimit.setValue(-.8,'');
fltCtrl.setPerpErrorVal(.125,'rad');
fltCtrl.setSearchSize(.5,'');
fltCtrl.setMinR(8,'m')
fltCtrl.setMaxR(16,'m')
fltCtrl.setElevatorConst(0,'deg')
fltCtrl.setStartControl(1,'s')
fltCtrl.firstSpoolLap.setValue(1000,'');
fltCtrl.winchSpeedIn.setValue(.1,'m/s');
fltCtrl.optAltitude.setValue(200,'m');

% Control surface parameters
fltCtrl.tanRoll.kp.setValue(0.33,'(rad)/(rad)');
fltCtrl.tanRoll.ki.setValue(0,'(rad)/(rad*s)');
fltCtrl.tanRoll.kd.setValue(0,'(rad)/(rad/s)');
fltCtrl.tanRoll.tau.setValue(1e-3,'s');

fltCtrl.rollMoment.kp.setValue(45,'(N*m)/(rad)')
fltCtrl.rollMoment.ki.setValue(10,'(N*m)/(rad*s)');
fltCtrl.rollMoment.kd.setValue(8,'(N*m)/(rad/s)');
fltCtrl.rollMoment.tau.setValue(0.01,'s');

fltCtrl.yawMoment.kp.setValue(2.3458e-1,'(N*m)/(rad)');
fltCtrl.yawMoment.ki.setValue(0.0,'(N*m)/(rad*s)')
fltCtrl.yawMoment.kd.setValue(0.0,'(N*m)/(rad/s)')
fltCtrl.yawMoment.tau.setValue(.01,'s')

fltCtrl.controlSigMax.upperLimit.setValue(30,'')
fltCtrl.controlSigMax.lowerLimit.setValue(-30,'')
fltCtrl.elevCtrlMax.upperLimit.setValue(8,'')
fltCtrl.elevCtrlMax.lowerLimit.setValue(-30,'')

fltCtrl.rudderGain.setValue(0,'')
fltCtrl.RPMConst.setValue(3.7,'');
fltCtrl.RPMmax.setValue(8,'');

% Control surface parameters
fltCtrl.rollCtrl.kp.setValue(1,'(deg)/(deg)');
fltCtrl.rollCtrl.ki.setValue(0,'(deg)/(deg*s)');
fltCtrl.rollCtrl.kd.setValue(0.5,'(deg)/(deg/s)');
fltCtrl.rollCtrl.tau.setValue(0.02,'s');

fltCtrl.yawCtrl.kp.setValue(0,'(deg)/(deg)');
fltCtrl.yawCtrl.ki.setValue(0,'(deg)/(deg*s)');
fltCtrl.yawCtrl.kd.setValue(0,'(deg)/(deg/s)');
fltCtrl.yawCtrl.tau.setValue(0.001,'s');

fltCtrl.controlSigMax.upperLimit.setValue(30,'')
fltCtrl.controlSigMax.lowerLimit.setValue(-30,'')
fltCtrl.elevCtrlMax.upperLimit.setValue(8,'')
fltCtrl.elevCtrlMax.lowerLimit.setValue(-30,'')

fltCtrl.rollAmp.setValue(30,'deg');
fltCtrl.yawAmp.setValue(180,'deg');
fltCtrl.period.setValue(10,'s');
fltCtrl.rollPhase.setValue(pi,'rad');
fltCtrl.yawPhase.setValue(2/10*pi,'rad');

fltCtrl.ccElevator.setValue(0,'deg');
fltCtrl.trimElevator.setValue(0,'deg');
fltCtrl.startCtrl.setValue(3,'s');

fltCtrl.startControl.setValue(0,'s');
%% Save
saveFile = saveBuildFile('fltCtrl',mfilename,'variant','FLIGHTCONTROLLER');
save(saveFile,'SPOOLINGCONTROLLER','-append')