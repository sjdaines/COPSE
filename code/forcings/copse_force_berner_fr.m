classdef copse_force_berner_fr < copse_force
    % Uplift forcing GEOCARB III Berner(2001) Fig 2.
    %
    % From fit to Ronov (1993) sediment abundance data
    %
    properties       
        extrapolate = 1;            % extrapolate out-of-range time values to extrapval
    end
    properties(SetAccess=private)   % can be read, but not modified
        extrapval   = 1;   
        datafile = 'forcings/berner_fr.xlsx'        
        data;   % struct with raw data from spreadsheet columns Time(Ma) Erosion/uplift
    end
    
    methods
        % Constructor. This loads data when object is created
        function f = copse_force_berner_fr(extrapolate)
            f.extrapolate = extrapolate;
            f.load();
        end
        
        function load(obj)
            %%%% load data
            fprintf('loading Uplift/erosion data from "%s"\n',obj.datafile);      
            eru = xlsread(obj.datafile);
            obj.data.timeMa           = eru(:,1);            
            obj.data.ErosionUplift    = eru(:,2);
        end
        
        function D = force(obj, tforce_presentdayiszeroyr, D )                                 
            % Convert requested time to offset used by the forcing file
            tMya = -tforce_presentdayiszeroyr/1e6;  % Mya
            if    obj.extrapolate &&  (tMya > obj.data.timeMa(1)) 
                D.UPLIFT = obj.extrapval;
            elseif obj.extrapolate && (tMya < obj.data.timeMa(end))
                D.UPLIFT = obj.extrapval;
            else
                D.UPLIFT   = interp1(obj.data.timeMa,obj.data.ErosionUplift,tMya) ;  
            end
        end
        
    end
end


