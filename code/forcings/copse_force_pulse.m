classdef copse_force_pulse < copse_force
    %Generic pulse injection forcing, for specified field
    %
    % Examples: 'O_SO2pert', 'carbwpert', 'O_Ppert', 'mpsbpert', 'F_EPSILON'
    
    properties
        dfield;
        size;
        duration;
        tstart;
    end
    
    methods
        % Constructor. This enforces input of parameters when object is created
        function f = copse_force_pulse(dfield, size, duration, tstart)
            f.dfield = dfield;
            f.size = size;
            f.duration = duration;
            f.tstart = tstart;
        end
        function D = force(obj, tmodel, D )
            D.(obj.dfield)           = D.(obj.dfield) + obj.size/obj.duration ...
                *copse_force_tophat(tmodel, obj.tstart , obj.tstart + obj.duration);            
        end
    end

end