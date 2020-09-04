function [Mfuse,thk,exitflag] = App_SFDT(D,L,Fz,MTParams,SFOTParams,SWDTParams,SFDTParams)

DecVar.L = L;  % shear stress calc
DecVar.D = D; %decision variable 

ForcesTotal = Fz; 
Forces.FzW = 0.9*ForcesTotal; 
Forces.FzH = 0.1*ForcesTotal; 


%% Input parameters 

Inp.HStab_c = SFDTParams.C_Hstab;          %HStab chord 

% Positions of tether attachment points 
Inp.x1 = SFDTParams.x_1; 
Inp.x2 = SFDTParams.x_2;               %from the tail 

Inp.xW = SFDTParams.x_W;              %position (%) of the wing 

Inp.fos = SFDTParams.FOS;              %factor of safety 
Inp.Syield = SFDTParams.S_yield;         %yield stress 

% Internal, external and dynamic pressures
Inp.IntP = SFDTParams.Int_P; 
Inp.ExtP = SFDTParams.Ext_P; 
Inp.DynP = SFDTParams.Dyn_P; 

% Densities  
Inp.rhow = SFOTParams.rho; 
Inp.rhoAl = SWDTParams.rhow; 

Inp.tarBuoy = MTParams.tar_buoy; 

%% 

% Reaction forces 
SolRHS = [1 1; (Inp.x1 - Inp.xW)*DecVar.L (1-Inp.x2-Inp.xW)*DecVar.L]; 
SolLHS = [Forces.FzW + Forces.FzH ; Forces.FzH*(1-Inp.xW-0.75*Inp.HStab_c)*DecVar.L]; 
Forces.Rx_vec = inv(SolRHS)*SolLHS; 

lb = [0.01]; 
ub = [SFDTParams.Fthkmax];
u0 = [0.02]; 

J = @(u)DLCalc_cost(DecVar,u);
C = @(u)DLCalc_constraint(u,Forces,DecVar,Inp);

options = optimoptions('fmincon','Display','iter','Algorithm','sqp','MaxFunctionEvaluations',1e7,'MaxIterations',1e7);
[uopt Jopt exitflag] = fmincon(J,u0,[],[],[],[],lb,ub,C,options);

Mfuse = Jopt*pi*Inp.rhoAl;
thk = uopt; 

% end 




%% functions 

function J = DLCalc_cost(DecVar,u)

r = 0.5*DecVar.D; 
l = DecVar.L; 

J = (u^2 + 2*u*r)*l; 
end 

function [c_ineq, c_eq] = DLCalc_constraint(u,Forces,DecVar,Inp)

r = 0.5*DecVar.D; 
l = DecVar.L; 

% Length from shear stress 
ineq1 = (Forces.FzW+Forces.FzH)/(u*l) - Inp.fos*Inp.Syield; 

% Radius for hoop stress due to shear  
Pdiff = Inp.ExtP + Inp.DynP - Inp.IntP; 
ineq2 = (Pdiff*r)/u - Inp.fos*Inp.Syield; 

% Buckling of fuselage  
BMmax = (Inp.x1*l*Forces.Rx_vec(1))-(Inp.xW*l*Forces.FzW)-((1-Inp.x2)*l*Forces.Rx_vec(2)); %max bending moment
SMod = pi*r^2*u; 
ineq3 = BMmax/SMod - Inp.fos*Inp.Syield;

% Neutral buoyancy 
eq1 = Inp.rhoAl*(u^2 + 2*r*u) - Inp.rhow*r^2 - Inp.tarBuoy; 

c_ineq = [ineq1; ineq2; ineq3];  
c_eq = [eq1]; 

end 

end 