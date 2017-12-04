classdef (Abstract) copse_force < handle
    % Interface implemented by copse forcing or perturbation
    % 
    % Implementations should define properties to hold their configuration
    % (eg duration, magnitude etc)
    %
    methods (Abstract)
        % A forcing is called with tforce (which may or may not be the same as tmodel),
        %    and is in years relative to present_day = 0;
        % A perturbation is called with tmodel
        D = force(tmodel_or_tforce, D);        
    end
    
end

