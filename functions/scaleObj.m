function obj = scaleObj(obj,lengthScaleFactor,densityScaleFactor)
% function that uses the listed units to automatically scale up/down
p = properties(obj);
scaleUnitList = {'m','s','kg','rad','deg'}; % units that impact how to scale things

scaleFactors  = {num2str(lengthScaleFactor),...
    num2str(sqrt(lengthScaleFactor)),...
    num2str(densityScaleFactor),...
    '1',...
    '1'};

for ii = 1:length(p)
    unit = obj.(p{ii}).Unit;
    if ~isempty(unit)
        for jj = 1:length(scaleUnitList)
            unit = strrep(unit, scaleUnitList{jj},scaleFactors{jj});
        end
        unit = strrep(unit,'/*','/');
        if strcmp(unit(1),'*')
            unit = unit(2:end);
        end
        if strcmp(unit(1),'/')
            unit = ['1' unit];
        end
        scaleFactor = eval(unit);
        obj.(p{ii}).Value = obj.(p{ii}).Value*scaleFactor;
    end
end
end
