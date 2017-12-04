function [ force, idxforce ] = copse_find_force( model, forceclassname, allowempty )
% Find a forcing in list
%   looks for forcing of class 'forceclassname' in cell array model.force
  
if nargin < 3
    allowempty = false;
end

idxforce = find(strcmp(cellfun(@class, model.force,'UniformOutput',false), forceclassname));

if isempty(idxforce)
    if ~allowempty
        error('no %s forcing found in list', forceclassname);
    end
    force = [];
elseif length(idxforce) == 1
    force = model.force{idxforce};
else
    error('multiple forcings matching %s found in list', forceclassname);
end

end

