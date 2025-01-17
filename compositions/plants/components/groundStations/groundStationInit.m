% If user specifies too few nodes, or noninteger value
numNodes = evalin('base',get_param(gcb,'numNodes'));
if numNodes < 2  || floor(numNodes)~=numNodes
    warning('Invalid number of nodes, N.  N must be an integer and >=2.\nKeeping active variant: %s',get_param(gcb,'LabelModeActiveChoice'))
    return
end


createAnchThrPollPosBus(numNodes)