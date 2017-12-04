classdef copse_force_CK_solar < copse_force
    %Time-dependent solar insolation (Caldeira & Kasting, 1992)
    properties
        solarpresentday = 1368;     % W m^-2 present-day insolation
    end
    
    methods
        function D = force(obj, tforceafterpresent, D)
            %
            % cf Gough (1981) Solar Physics has 1/(1+2/5(1-t/tsun)) = 1/(1+0.4*(tsun-t)/tsun)
            % tyr_after_present    - (negative) years after present day
            
            D.SOLAR=1./(1+ (-tforceafterpresent./4.55e9)*0.38 )*obj.solarpresentday;
            
        end
    end
end

