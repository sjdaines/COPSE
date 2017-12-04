classdef copse_force_granite < copse_force
    % Forcing from file sandstone_shield_siliceous_area.xlsx
    properties
        estimate                    % estimate to use ('','','')
        extrapolate = 1;            % 0 none, 1 extrapolate out-of-range time values to extrapval, 2 extrapolate to first/last data points
    end
    properties(SetAccess=private)   % can be read, but not modified
        extrapval   = 1;   
        %datafile = 'forcings/sandstone_shield_siliceous_area.xlsx'        
        datafile = 'forcings/shield_area.xlsx'        
        data;   % struct with raw data from spreadsheet columns Time(Ma) 
    end
    
    methods
        % Constructor. This loads data when object is created
        function f = copse_force_granite(estimate)
            f.estimate = estimate;
            f.load();
        end
        
        function load(obj)
            %%%% load data
            fprintf('loading sandstone+shield+chert area forcing data from "%s"\n',obj.datafile);      
            gran = xlsread(obj.datafile);
            obj.data.timeMa   = gran(:,1);            
            obj.data.silarea = gran(:,2);
            obj.data.silnorm = gran(:,3);
        end
        
        function D = force(obj, tforce_presentdayiszeroyr, D )                                 
            % Convert requested time to offset used by the forcing file
            tdatafile = -tforce_presentdayiszeroyr/1e6;  % Mya
            if obj.extrapolate == 1
                D.GRAN   = interp1([ 1e10; obj.data.timeMa(1)+1e-3; obj.data.timeMa; obj.data.timeMa(end)-1e-3; -1e10], ...
                                         [obj.extrapval; obj.extrapval; obj.data.(obj.estimate); obj.extrapval; obj.extrapval],...
                                         tdatafile) ; 
            elseif obj.extrapolate == 2
                D.GRAN   = interp1([ 1e10; obj.data.timeMa; -1e10], ...
                                         [ obj.data.(obj.estimate)(1); obj.data.(obj.estimate); obj.data.(obj.estimate)(end); ],...
                                         tdatafile) ; 
            else
                D.GRAN   = interp1(obj.data.timeMa,obj.data.(obj.estimate),tdatafile) ;                   
            end
        end
        
    end
end


