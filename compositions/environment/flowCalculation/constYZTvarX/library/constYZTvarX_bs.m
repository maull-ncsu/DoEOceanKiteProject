clear all;clc;format compact

%% Set up environment
% Create
env = ENV.env;
env.addFlow({'water'},{'constXYZT'},'FlowDensities',1000);
env.addFlow({'waterWave'},{'planarWaves'});
env.waterWave.setNumWaves(3,'');
env.waterWave.build;
% 
% env.waterWave.wave1.waveNumber.setValue(1,'rad/m')
% env.waterWave.wave1.frequency.setValue(.2,'rad/s')
% env.waterWave.wave1.amplitude.setValue(.1,'m')
% env.waterWave.wave1.phase.setValue(0,'rad')
% 
% env.waterWave.wave2.waveNumber.setValue(1,'rad/m')
% env.waterWave.wave2.frequency.setValue(.4,'rad/s')
% env.waterWave.wave2.amplitude.setValue(.1,'m')
% env.waterWave.wave2.phase.setValue(0,'rad')
% 
% env.waterWave.wave3.waveNumber.setValue(1,'rad/m')
% env.waterWave.wave3.frequency.setValue(.6,'rad/s')
% env.waterWave.wave3.amplitude.setValue(.1,'m')
% env.waterWave.wave3.phase.setValue(0,'rad')

% env.waterWave.waveParamMat.setValue(env.waterWave.structAssem,'');
% FLOWCALCULATION = 'constXYZT_planarWave';
FLOWCALCULATION = 'constYZTvarX';
ENVIRONMENT     = 'environmentManta2rot';

saveBuildFile('env',mfilename,'variant',["FLOWCALCULATION","ENVIRONMENT"]);
