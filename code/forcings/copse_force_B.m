classdef copse_force_B < copse_force
    % Forcing, calcerous plankton evolution
    methods
        
        function D = force(obj, tyr_after_present, D)
            % tyr_after_present    - (negative) years after present day
            
            % ' to convert to column vector to allow use of fast interpolation routine
            D.Bforcing = copse_interp1([-1e10    -500e6      -300e6      -150e6      -140e6      -110e6      -90e6       -50e6   	-10e6	0   1E10]',...
                [0.75     0.75        0.75        0.75        0.83776596	0.90990691	0.96110372	0.98902926	1       1   1]',...
                tyr_after_present);
        end
    end
    
end


