%%  Monk Moment Analysis 
loadComponent('Manta2RotXFlr_Thr075');                         %   Load new vehicle with 2 rotors
spd = 0.1:.05:.5;
vFlowGrad = zeros(3,6);  
pitch = -20:1:20;
for j = 1:length(spd)
    for i = 1:length(pitch)
        vFlow = [spd(j);0;0];
        vFlowGrad(1,:) = spd(j);
        eul = [0;pitch(i);0]*pi/180;
        sim('AddedMassTest')
        Madd(j,i) = MAddedBdy(2);
        fprintf('j = %d\ti = %d\n',j,i)
    end
end
Monk.spd = spd; Monk.pitch = pitch; Monk.Madd = Madd;
save('MonkMoments.mat','Monk')
%%
figure; subplot(2,1,1);
surf(pitch,spd,Madd);  xlabel('$\theta$ [deg]');  ylabel('$V_\mathrm{flow}$ [m/s]');  zlabel('Pitch Moment [Nm]');
subplot(2,1,2);  
contourf(pitch,spd,Madd,25);  xlabel('$\theta$ [deg]');  ylabel('$V_\mathrm{flow}$ [m/s]');