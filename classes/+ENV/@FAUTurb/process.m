% code to recreate turbulence model as per the following paper
% 'Numerical modeling of turbulence and its effect on ocean current
% turbines' by parakram pyakurel

function process(obj,lowFreqFlowObj,varargin)
p = inputParser;
addParameter(p,'Verbose',false,@islogical)
parse(p,varargin{:});
if p.Results.Verbose
    fprintf('\nBeginning processing\n')
end

basePath = which('OCTProject.prj');
basePath = fileparts(basePath);
basePath = fullfile(basePath,'classes','+ENV','@FAUTurb');
% Check if the low freq flow object and the high freq flow object match
% what's already saved
tf1 = checkedAgainstSavedVersion(...
    fullfile(basePath,'processResults.mat'),...
    lowFreqFlowObj,'lowFreqFlowObj');
tf2 = checkedAgainstSavedVersion(...
    fullfile(basePath,'processResults.mat'),...
    obj,'highFreqFlowObj',...
    'Exceptions',{'frequencyDomainEqParams'});

% If both of these things matched the saved versions, then just load in the
% saved version and set the properties of the current version
if tf1 && tf2
    load(fullfile(basePath,'processResults.mat'),'highFreqFlowObj');
    obj.setFreqDomainParams(highFreqFlowObj);
    if p.Results.Verbose
        fprintf('Found matching object in saved file, complete.\n')
    end
    return;
end

timeVec = lowFreqFlowObj.flowVecTimeseries.Value.Time;
[xPts,yPts,zPts] = meshgrid(...
    lowFreqFlowObj.xGridPoints.Value,...
    lowFreqFlowObj.yGridPoints.Value,...
    lowFreqFlowObj.zGridPoints.Value);

[ix,iy,iz] = meshgrid(...
    1:numel(lowFreqFlowObj.xGridPoints.Value),...
    1:numel(lowFreqFlowObj.yGridPoints.Value),...
    1:numel(lowFreqFlowObj.zGridPoints.Value));

posData = [xPts(:) yPts(:) zPts(:)];
idx = [ix(:) iy(:) iz(:)];

nx = numel(lowFreqFlowObj.xGridPoints.Value);
ny = numel(lowFreqFlowObj.yGridPoints.Value);
nz = numel(lowFreqFlowObj.zGridPoints.Value);

TI = obj.intensity.Value;
P = obj.lateralStDevRatio.Value;
Q = obj.verticalStDevRatio.Value;
f_min = obj.minFreqHz.Value;
f_max = obj.maxFreqHz.Value;
N_mid_freq = obj.numMidFreqs.Value;
C = obj.spatialCorrFactor.Value;
%% delta_rij
n_elem = size(posData,1);
% delta_rij = zeros(n_elem);
% for i1 = 1:n_elem
%     for j = i1:n_elem
% delta_rij(i1,j) = norm(posData(i1,:) - posData(j,:));
%     end
% end
%
% delta_rij = delta_rij + delta_rij';
delta_rij = sqrt(sum((permute(posData,[1 3 2])-permute(posData,[3 1 2])).^2,3));
% Hm = nan([size(posData,1),size(posData,1),N_mid_freq,3,numel(timeVec)]);

%% discretize frequency into N parts
f_int = linspace(f_min,f_max,N_mid_freq+1);

% frequency vector containing discretized midpoint frequencies between f_min and f_max
ff = NaN(N_mid_freq,1);

for i1 = 1:N_mid_freq
    ff(i1) = (1/2)*(f_int(i1) + f_int(i1+1));
end
obj.setMidFreqs(ff,'Hz');

df = ff(2)-ff(1);


for iTime = 1:numel(timeVec)
    %% velocity in frequency domain calculations
    % Get flow velocity data in the correct order to match the position
    % data
    data = lowFreqFlowObj.flowVecTimeseries.Value.Data(:,:,:,:,iTime);
    vxData = data(:,:,:,1,1);
    vyData = data(:,:,:,2,1);
    vzData = data(:,:,:,3,1);
    
    vxData = data(sub2ind(size(vxData),ix(:),iy(:),iz(:)));
    vyData = data(sub2ind(size(vyData),ix(:),iy(:),iz(:)));
    vzData = data(sub2ind(size(vzData),ix(:),iy(:),iz(:)));
    
    data = [vxData vyData vzData];
    
    
    U_mean = NaN(n_elem,1);
    sigma_u = NaN(n_elem,1);
    sigma_v = NaN(n_elem,1);
    sigma_w = NaN(n_elem,1);
    
    sigma_m = NaN(n_elem,3);
    TI_m = NaN(n_elem,3);
    Am = NaN(n_elem,3);
    
    for i1 = 1:n_elem
        
        U_mean(i1) = norm(data(i1,:));
        
        sigma_u(i1) = (TI*U_mean(i1))/(sqrt(1 + P^2 + Q^2));
        sigma_v(i1) = P*sigma_u(i1);
        sigma_w(i1) = Q*sigma_u(i1);
        
        % standard deviations vector
        sigma_m(i1,:) = [sigma_u(i1) sigma_v(i1) sigma_w(i1)];
        
        % Turbulence intensity vector
        TI_m(i1,:) = sigma_m(i1,:)./norm(U_mean(i1));
        
        % continuous power spectral density
        % constant of proportionality
        Am(i1,:) = ( (2*norm(U_mean(i1))^2)/(3*((1/f_min^(2/3)) - (1/f_max^(2/3)))) ).*(TI_m(i1,:).^2);
        
    end
    
    
    
    %% coh calculation
    Cdel_U = NaN*delta_rij;
    
    for i1 = 1:n_elem
        Cdel_U(i1,:) = C*delta_rij(i1,:)/U_mean(i1);
    end
    
    coh_ij = NaN(n_elem,n_elem,N_mid_freq);
    
    for i1 = 1:N_mid_freq
        Cdelf_U = Cdel_U.*ff(i1);
        
        coh_ij(:,:,i1) = exp(-Cdelf_U);
    end
    
    %% discretized cross spectral density between nodes
    Su = NaN(size(coh_ij));
    Sv = NaN(size(coh_ij));
    Sw = NaN(size(coh_ij));
    
    for i1 = 1:N_mid_freq
        for j = 1:n_elem
            Su(j,:,i1) = (2*Am(j,1)*df*(ff(i1)^(-5/3))).*coh_ij(j,:,i1);
            Sv(j,:,i1) = (2*Am(j,2)*df*(ff(i1)^(-5/3))).*coh_ij(j,:,i1);
            Sw(j,:,i1) = (2*Am(j,3)*df*(ff(i1)^(-5/3))).*coh_ij(j,:,i1);
            
        end
    end
    
    % store in cell
    Sm = cell(3,1);
    Sm{1} = Su; Sm{2} = Sv; Sm{3} = Sw;
    
    %% velocity weighing factor
    Hu = zeros(size(Su));      % weighing factor for u direction
    Hv = zeros(size(Sv));       % weighing factor for v direction
    Hw = zeros(size(Sw));       % weighing factor for w direction
    
    for k = 1:N_mid_freq
        
        Hu(1,1,k) = Su(1,1,k)^(1/2);
        Hu(2,1,k) = Su(2,1,k)/Hu(1,1,k);
        Hu(2,2,k) = (Su(2,2,k) - Hu(2,1,k)^2)^(1/2);
        Hu(3,1,k) = Su(3,1,k)/Hu(1,1,k);
        
        Hv(1,1,k) = Sv(1,1,k)^(1/2);
        Hv(2,1,k) = Sv(2,1,k)/Hv(1,1,k);
        Hv(2,2,k) = (Sv(2,2,k) - Hv(2,1,k)^2)^(1/2);
        Hv(3,1,k) = Sv(3,1,k)/Hv(1,1,k);
        
        Hw(1,1,k) = Sw(1,1,k)^(1/2);
        Hw(2,1,k) = Sw(2,1,k)/Hw(1,1,k);
        Hw(2,2,k) = (Sw(2,2,k) - Hw(2,1,k)^2)^(1/2);
        Hw(3,1,k) = Sw(3,1,k)/Hw(1,1,k);
        
        for i1 = 3:n_elem
            for j = 1:n_elem
                
                if j == 1
                    Hu(i1,j,k) = Su(i1,j,k)/Hu(1,1,k);
                    Hv(i1,j,k) = Sv(i1,j,k)/Hv(1,1,k);
                    Hw(i1,j,k) = Sw(i1,j,k)/Hw(1,1,k);
                    
                elseif j>1 && j<i1
                    Hu(i1,j,k) = (Su(i1,j,k) - sum(Hu(i1,1:j-1,k).*Hu(j,1:j-1,k)))/Hu(j,j,k);
                    Hv(i1,j,k) = (Sv(i1,j,k) - sum(Hv(i1,1:j-1,k).*Hv(j,1:j-1,k)))/Hv(j,j,k);
                    Hw(i1,j,k) = (Sw(i1,j,k) - sum(Hw(i1,1:j-1,k).*Hw(j,1:j-1,k)))/Hw(j,j,k);
                    
                elseif j == i1
                    Hu(i1,j,k) = (Su(i1,j,k) - sum((Hu(j,1:j-1,k).^2)))^(1/2);
                    Hv(i1,j,k) = (Sv(i1,j,k) - sum((Hv(j,1:j-1,k).^2)))^(1/2);
                    Hw(i1,j,k) = (Sw(i1,j,k) - sum((Hw(j,1:j-1,k).^2)))^(1/2);
                    
                end
            end
        end
        %     k
    end
    
    % store in cell
    
    % store in cell
    Hm = cell(3,1);
    Hm{1} = Hu; Hm{2} = Hv; Hm{3} = Hw;
    
    %% amplitude of the fluctuating velocity component
    % random phase angle between 0 to 2*pi
    u_th_k = 2*pi*rand(n_elem,N_mid_freq);
    v_th_k = 2*pi*rand(n_elem,N_mid_freq);
    w_th_k = 2*pi*rand(n_elem,N_mid_freq);
    
    % amplitude of the fluctuating velocity component
    i = sqrt(-1);
    u_star_kj = NaN(n_elem,N_mid_freq);
    v_star_kj = NaN(n_elem,N_mid_freq);
    w_star_kj = NaN(n_elem,N_mid_freq);
    
    for k = 1:N_mid_freq
        
        for j = 1:n_elem
            % possible mistake in reference paper in this section
            % paper says use H(1:j,j,k) instead of what is used
            u_star_kj(j,k) = sum(Hu(j,1:j,k)*exp(i*u_th_k(1:j,k)));
            v_star_kj(j,k) = sum(Hv(j,1:j,k)*exp(i*v_th_k(1:j,k)));
            w_star_kj(j,k) = sum(Hw(j,1:j,k)*exp(i*w_th_k(1:j,k)));
            
        end
        
    end
    
    % resultant phase angle for each frequency component
    u_th_kR = NaN(size(u_star_kj));
    v_th_kR = NaN(size(v_star_kj));
    w_th_kR = NaN(size(w_star_kj));
    
    for k = 1:N_mid_freq
        for j = 1:n_elem
            u_th_kR(j,k) = wrapTo2Pi(angle(u_star_kj(j,k)));
            v_th_kR(j,k) = wrapTo2Pi(angle(v_star_kj(j,k)));
            w_th_kR(j,k) = wrapTo2Pi(angle(v_star_kj(j,k)));
            % u_th_kR(j,k) = atan2(imag(u_star_kj(j,k)),real(u_star_kj(j,k)));
            % v_th_kR(j,k) = atan2(imag(v_star_kj(j,k)),real(u_star_kj(j,k)));
            % w_th_kR(j,k) = atan2(imag(v_star_kj(j,k)),real(u_star_kj(j,k)));
            
        end
    end
    
    
    %% store values
    % storing all of the values that define u,v,w as function of
    % frequency
    
    u_star_kj   = reshape(u_star_kj,[numel(lowFreqFlowObj.xGridPoints.Value),numel(lowFreqFlowObj.yGridPoints.Value),numel(lowFreqFlowObj.zGridPoints.Value),N_mid_freq]);
    u_th_kR     = reshape(u_th_kR,[numel(lowFreqFlowObj.xGridPoints.Value),numel(lowFreqFlowObj.yGridPoints.Value),numel(lowFreqFlowObj.zGridPoints.Value),N_mid_freq]);
    v_star_kj   = reshape(v_star_kj,[numel(lowFreqFlowObj.xGridPoints.Value),numel(lowFreqFlowObj.yGridPoints.Value),numel(lowFreqFlowObj.zGridPoints.Value),N_mid_freq]);
    v_th_kR     = reshape(v_th_kR,[numel(lowFreqFlowObj.xGridPoints.Value),numel(lowFreqFlowObj.yGridPoints.Value),numel(lowFreqFlowObj.zGridPoints.Value),N_mid_freq]);
    w_star_kj   = reshape(w_star_kj,[numel(lowFreqFlowObj.xGridPoints.Value),numel(lowFreqFlowObj.yGridPoints.Value),numel(lowFreqFlowObj.zGridPoints.Value),N_mid_freq]);
    w_th_kR     = reshape(w_th_kR,[numel(lowFreqFlowObj.xGridPoints.Value),numel(lowFreqFlowObj.yGridPoints.Value),numel(lowFreqFlowObj.zGridPoints.Value),N_mid_freq]);
    
    
    uStarLUT(:,:,:,:,iTime) = u_star_kj;
    uThLUT(:,:,:,:,iTime) = u_th_kR;
    vStarLUT(:,:,:,:,iTime)  = v_star_kj;
    vThLUT(:,:,:,:,iTime)  = v_th_kR;
    wStarLUT(:,:,:,:,iTime)  = w_star_kj;
    wThLUT(:,:,:,:,iTime)  = w_th_kR;
    
    
    
    
    if p.Results.Verbose
        fprintf('Time step %d of %d\n',iTime,numel(timeVec))
    end
    
end
% Indices in Hm are (number of 3d grid elements,number of freq discritizations,the six components definining m as a funct of frequency,time)
% freqDPTimeseries = timeseries(freqDomainParams,lowFreqFlowObj.flowVecTimeseries.Value.Time);
% obj.setFreqDomainParams(freqDPTimeseries,'');

uStarLUTObj = Simulink.LookupTable;
uStarLUTObj.Table.Value = uStarLUT;
uStarLUTObj.Breakpoints(1).Value = lowFreqFlowObj.xGridPoints.Value;
uStarLUTObj.Breakpoints(2).Value = lowFreqFlowObj.yGridPoints.Value;
uStarLUTObj.Breakpoints(3).Value = lowFreqFlowObj.zGridPoints.Value;
uStarLUTObj.Breakpoints(4).Value = 1:N_mid_freq;
uStarLUTObj.Breakpoints(5).Value = timeVec;
uStarLUTObj.StructTypeInfo.Name = 'uStarLUTObj';
uThLUTObj = Simulink.LookupTable;
uThLUTObj.Table.Value = uThLUT;
uThLUTObj.Breakpoints(1).Value = lowFreqFlowObj.xGridPoints.Value;
uThLUTObj.Breakpoints(2).Value = lowFreqFlowObj.yGridPoints.Value;
uThLUTObj.Breakpoints(3).Value = lowFreqFlowObj.zGridPoints.Value;
uThLUTObj.Breakpoints(4).Value = 1:N_mid_freq;
uThLUTObj.Breakpoints(5).Value = timeVec;
uThLUTObj.StructTypeInfo.Name = 'uThLUTObj';
vStarLUTObj = Simulink.LookupTable;
vStarLUTObj.Table.Value = vStarLUT;
vStarLUTObj.Breakpoints(1).Value = lowFreqFlowObj.xGridPoints.Value;
vStarLUTObj.Breakpoints(2).Value = lowFreqFlowObj.yGridPoints.Value;
vStarLUTObj.Breakpoints(3).Value = lowFreqFlowObj.zGridPoints.Value;
vStarLUTObj.Breakpoints(4).Value = 1:N_mid_freq;
vStarLUTObj.Breakpoints(5).Value = timeVec;
vStarLUTObj.StructTypeInfo.Name = 'vStarLUTObj';
vThLUTObj = Simulink.LookupTable;
vThLUTObj.Table.Value = vThLUT;
vThLUTObj.Breakpoints(1).Value = lowFreqFlowObj.xGridPoints.Value;
vThLUTObj.Breakpoints(2).Value = lowFreqFlowObj.yGridPoints.Value;
vThLUTObj.Breakpoints(3).Value = lowFreqFlowObj.zGridPoints.Value;
vThLUTObj.Breakpoints(4).Value = 1:N_mid_freq;
vThLUTObj.Breakpoints(5).Value = timeVec;
vThLUTObj.StructTypeInfo.Name = 'vThLUTObj';
wStarLUTObj = Simulink.LookupTable;
wStarLUTObj.Table.Value = wStarLUT;
wStarLUTObj.Breakpoints(1).Value = lowFreqFlowObj.xGridPoints.Value;
wStarLUTObj.Breakpoints(2).Value = lowFreqFlowObj.yGridPoints.Value;
wStarLUTObj.Breakpoints(3).Value = lowFreqFlowObj.zGridPoints.Value;
wStarLUTObj.Breakpoints(4).Value = 1:N_mid_freq;
wStarLUTObj.Breakpoints(5).Value = timeVec;
wStarLUTObj.StructTypeInfo.Name = 'wStarLUTObj';
wThLUTObj = Simulink.LookupTable;
wThLUTObj.Table.Value = wThLUT;
wThLUTObj.Breakpoints(1).Value = lowFreqFlowObj.xGridPoints.Value;
wThLUTObj.Breakpoints(2).Value = lowFreqFlowObj.yGridPoints.Value;
wThLUTObj.Breakpoints(3).Value = lowFreqFlowObj.zGridPoints.Value;
wThLUTObj.Breakpoints(4).Value = 1:N_mid_freq;
wThLUTObj.Breakpoints(5).Value = timeVec;
wThLUTObj.StructTypeInfo.Name = 'wThLUTObj';

obj.setUStarLUT(uStarLUTObj,'m/s');
obj.setUThLUT(uThLUTObj,'rad');
obj.setVStarLUT(vStarLUTObj,'m/s');
obj.setVThLUT(vThLUTObj,'rad');
obj.setWStarLUT(wStarLUTObj,'m/s');
obj.setWThLUT(wThLUTObj,'rad');
highFreqFlowObj = obj;
% Save the results to processResults.m

save(fullfile(basePath,'processResults.mat'),'highFreqFlowObj','lowFreqFlowObj','-v7.3')
if p.Results.Verbose
    fprintf('Complete\n')
end
%
%
% %% amplitude of the fluctuating velocity component
% % random phase angle between 0 to 2*pi
% u_th_k = 2*pi*rand(n_elem,N_mid_freq);
% v_th_k = 2*pi*rand(n_elem,N_mid_freq);
% w_th_k = 2*pi*rand(n_elem,N_mid_freq);
%
% % amplitude of the fluctuating velocity component
% i = sqrt(-1);
% u_star_kj = NaN(n_elem,N_mid_freq);
% v_star_kj = NaN(n_elem,N_mid_freq);
% w_star_kj = NaN(n_elem,N_mid_freq);
%
% for k = 1:N_mid_freq
%
%     for j = 1:n_elem
% % possible mistake in reference paper in this section
% % paper says use H(1:j,j,k) instead of what is used
% u_star_kj(j,k) = sum(Hu(j,1:j,k)*exp(i*u_th_k(1:j,k)));
% v_star_kj(j,k) = sum(Hv(j,1:j,k)*exp(i*v_th_k(1:j,k)));
% w_star_kj(j,k) = sum(Hw(j,1:j,k)*exp(i*w_th_k(1:j,k)));
%
%     end
%
% end
%
% % resultant phase angle for each frequency component
% u_th_kR = NaN(size(u_star_kj));
% v_th_kR = NaN(size(v_star_kj));
% w_th_kR = NaN(size(w_star_kj));
%
% for k = 1:N_mid_freq
%     for j = 1:n_elem
% u_th_kR(j,k) = wrapTo2Pi(angle(u_star_kj(j,k)));
% v_th_kR(j,k) = wrapTo2Pi(angle(v_star_kj(j,k)));
% w_th_kR(j,k) = wrapTo2Pi(angle(v_star_kj(j,k)));
% % u_th_kR(j,k) = atan2(imag(u_star_kj(j,k)),real(u_star_kj(j,k)));
% % v_th_kR(j,k) = atan2(imag(v_star_kj(j,k)),real(u_star_kj(j,k)));
% % w_th_kR(j,k) = atan2(imag(v_star_kj(j,k)),real(u_star_kj(j,k)));
%
%     end
% end
%
%
% %% store values
% op.u_star_kj = u_star_kj;
% op.u_th_kR = u_th_kR;
% op.v_star_kj = v_star_kj;
% op.v_th_kR = v_th_kR;
% op.w_star_kj = w_star_kj;
% op.w_th_kR = w_th_kR;
% op.ff = ff;


end

