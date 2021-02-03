clear
clc

HILVLCONTROLLER = 'gpkfAltitudeOpt';
PATHGEOMETRY = 'lemOfBooth';

loadComponent('ayazAirborneSynFlow');

% z grid
xMeasure            = env.water.zGridPoints.Value;
% spatial covarirance kernel
spatialCovFn        = env.water.spatialCovFn;
% temporal covariance kernel
temporalCovFn       = env.water.temporalCovFn;
% mean function
meanFn              = env.water.meanFn;
% spatial covariance amplitude
spatialCovAmp       = env.water.spatialCovAmp.Value;
% spatial length scale
spatialLengthScale  = env.water.spatialLengthScale.Value;
% temporal length scale
temporalLengthScale = env.water.temporalLengthScale.Value;
% noise variance
noiseVar            = env.water.noiseVariance.Value;

% fast state estimate time step in MINUTES
fastTimeStep  = 12/60;
% MPC KFGP time step in MINUTES
mpckfgpTimeStep = 3;
% mpc prediction horizon
predictionHorz  = 6;
% MPC constants
exploitationConstant = 1;
explorationConstant  = 0;


hiLvlCtrl.spatialCovFn         = spatialCovFn;
hiLvlCtrl.temporalCovFn        = temporalCovFn;
hiLvlCtrl.meanFn               = meanFn;
hiLvlCtrl.kfgpTimeStep         = fastTimeStep;
hiLvlCtrl.xMeasure             = xMeasure;
hiLvlCtrl.spatialCovAmp        = spatialCovAmp;
hiLvlCtrl.spatialLengthScale   = spatialLengthScale;
hiLvlCtrl.temporalCovAmp       = 1;
hiLvlCtrl.temporalLengthScale  = temporalLengthScale;
hiLvlCtrl.noiseVariance        = noiseVar;
hiLvlCtrl.meanFnProps          = env.water.meanFnProps.Value;

%% mpc controller properties
hiLvlCtrl.mpckfgpTimeStep      = mpckfgpTimeStep;
hiLvlCtrl.predictionHorz       = predictionHorz;
hiLvlCtrl.exploitationConstant = exploitationConstant;
hiLvlCtrl.explorationConstant  = explorationConstant;

%% extract values from power map
load('PowStudyAir_V6-22.mat');
[A,F] = meshgrid(altitude,flwSpd);
ppmax = R.Pmax(:);
zz    = A(:);
ff    = F(:);
locateNan = isnan(ppmax);
ppmax(locateNan) = [];
ff(locateNan) = [];
zz(locateNan) = [];

hiLvlCtrl.powerFunc = fit([ff, zz],ppmax,'poly23');
hiLvlCtrl.pMaxVals  = R.Pmax;
hiLvlCtrl.pMaxVals(isnan(R.Pmax))  = -100;
hiLvlCtrl.altVals   = A;
hiLvlCtrl.flowVals  = F;
hiLvlCtrl.powerGrid   = griddedInterpolant(hiLvlCtrl.flowVals,...
    hiLvlCtrl.altVals,hiLvlCtrl.pMaxVals);


%% plot
testZ = linspace(altitude(1),altitude(end),50);
testF = linspace(flwSpd(1),flwSpd(end)*1.5,30);
[ZZ,FF] = meshgrid(testZ,testF);PP = hiLvlCtrl.powerFunc(FF(:),ZZ(:));

scatter3(ff,zz,ppmax)
hold on
surf(F,A,R.Pmax)
scatter3(FF(:),ZZ(:),PP(:))

saveFile = saveBuildFile('hiLvlCtrl',mfilename,'variant','HILVLCONTROLLER');
save(saveFile,'PATHGEOMETRY','-append')
