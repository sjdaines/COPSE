classdef copse_force_co2pulse < copse_force
    % pulse C injection forcing
    %
    % cf Payne etal (2010) PNAS scenario
    % 2.4e18 molC, 10ky, -10 d13C
    % gives ~ 3 per mil delta 13C (as they have), ~1.2 mmol/kg Ca++ max, -0.15 per mil d44C (~ half their value).
    
    properties
        size;
        duration;
        tstart;
        d13C;
    end
    
    methods
        % Constructor. This enforces input of parameters when object is created
        function f = copse_force_co2pulse(size, duration, tstart,d13C)
            f.size = size;
            f.duration = duration;
            f.tstart = tstart;
            f.d13C = d13C;
        end
        function D = force(obj, tmodel, D)
            prate = obj.size/obj.duration ...
                *copse_force_tophat(tmodel, obj.tstart , obj.tstart + obj.duration);
            D.co2pert           = D.co2pert + prate;
            if obj.d13C ~= 0
                D.co2pertmoldelta       = D.co2pertmoldelta + prate*obj.d13C;
            end
        end
    end
    
end


