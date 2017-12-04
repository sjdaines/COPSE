classdef (Abstract) paleo_postprocessor < handle
    % Interface for a post-processing function
        
    methods (Abstract)      
        
       [ diag, budgets ] = calcall(obj, T, S, diag, budgets )
       
    end
    
end

