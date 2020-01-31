function tether000_init
% Function to initialize tether000 model
% I made this a function because I'm being paranoid about which workspace
% it's evaluating in.  I know it shouldn't be the base workspace, but I'm
% paranoid.

try
    % Get the number of nodes
    numNodes = evalin('base',get_param(gcb,'numNodes'));
catch
    dbstack
    error('Unable to evaluate number of nodes in block \n %s',gcb)
end

if numNodes < 2  || floor(numNodes)~=numNodes
    warning('Invalid number of nodes, N.  N must be an integer and >=2.\nKeeping active variant: %s',get_param(gcb,'LabelModeActiveChoice'))
    return
end

if numNodes > 2
    set_param(gcb,'OverrideUsingVariant','NNodeTether')
else
    set_param(gcb,'OverrideUsingVariant','twoNodeTether')
end
end