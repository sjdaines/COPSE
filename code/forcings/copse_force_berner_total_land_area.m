classdef copse_force_berner_total_land_area < copse_force
    % Carbonate land area from GEOCARB
    %

    properties       
        extrapolate = 1;            % extrapolate out-of-range time values to extrapval
    end
    properties(SetAccess=private)   % can be read, but not modified
        extrapval   = 1;   
        datafile = 'forcings/berner_land_area.xlsx'        
        data;   % struct with raw data from spreadsheet columns Time(Ma) CARB AREA
    end
    
    methods
        % Constructor. This loads data when object is created
        function f = copse_force_berner_total_land_area(extrapolate)
            f.extrapolate = extrapolate;
            f.load();
        end
        
        function load(obj)
            %%%% load data
            fprintf('loading total land area from "%s"\n',obj.datafile);      
            eru = xlsread(obj.datafile);
            obj.data.tforwardsage           = eru(:,1);            
            obj.data.total_land_area    = eru(:,2);
        end
        
        function D = force(obj, tforce_presentdayiszeroyr, D )                                 
            % Convert requested time to offset used by the forcing file
            tforwardsage = tforce_presentdayiszeroyr + 4.5e9;  % Mya
            if    obj.extrapolate &&  (tforwardsage < obj.data.tforwardsage(1)) 
                D.TOTAL_AREA = obj.extrapval;
            elseif obj.extrapolate && (tforwardsage > obj.data.tforwardsage(end))
                D.TOTAL_AREA = obj.extrapval;
            else
                D.TOTAL_AREA   = interp1(obj.data.tforwardsage,obj.data.total_land_area,tforwardsage) ;  
            end
        end
        
    end
end


