classdef copse_force_examples < copse_force
    % Example perturbations
    %
    %
    
    methods
        
        function D = force(obj, tmodel, D)
            % Override background forcings with perturbations
            D.UPLIFT            = 1+copse_force_tophat(tmodel ,300e6, 310e6);
            %D.UPLIFT            = 1+copse_force_tophat(tmodel ,300e6, 500e6);
            D.DEGASS            = 1+copse_force_tophat(tmodel ,350e6, 360e6);
            %D.DEGASS            = 1+copse_force_tophat(tmodel ,300e6, 500e6);
            
            %%% D.RHO additional  enhancement to carbonate/silicate weathering
            D.RHO               = 1+copse_force_tophat(tmodel , 400e6, 410e6);
            %D.RHO               = 1+copse_force_tophat(tmodel , 300e6, 500e6);
            %%% F_EPSILON enhances nutrient weathering only
            D.F_EPSILON           = 1+copse_force_tophat(tmodel , 450e6, 500e6);
            %D.F_EPSILON           = 1+copse_force_tophat(tmodel , 300e6, 500e6);
            
        end
    end
    
end



