classdef copse_force_CPlandrel < copse_force
    %CP land burial ratio doubles in permo-carboniferous (COPSE)
    
    properties
        %COPSE5_14
        k_begin_Carb_yr = -355000000; % increase period begins
        k_end_Carb_yr   = -290000000; % decrease period begins
        
        %The code then applies a ramp of +- 1 over 10My _starting_ from these times
        
        k_Carb_ramp_yr = 10e6;
    end
    
    methods
        
        function D = force(obj, tyr_after_present, D)
            % ' to convert to column vector to allow use of fast interpolation routine
            D.CPland_relative = copse_interp1([-1e10  obj.k_begin_Carb_yr obj.k_begin_Carb_yr+obj.k_Carb_ramp_yr  obj.k_end_Carb_yr   obj.k_end_Carb_yr+obj.k_Carb_ramp_yr    1E10 ]',...
                                              [1      1                   2                                       2                   1                                       1]',...
                tyr_after_present) ;        
        end
    end
    
end
