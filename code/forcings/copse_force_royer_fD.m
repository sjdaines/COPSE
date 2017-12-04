classdef copse_force_royer_fD < copse_force
    % Paleogeographic effect on weathering/erosion Godderis
    %
    %
    properties       
        extrapolate = 1;            % extrapolate out-of-range time values to extrapval
        extrapval   = 1;
    end
    properties(SetAccess=private)   % can be read, but not modified

        datafile = 'forcings/royer_fDfAw.xlsx'        
        %datafile = 'forcings/royer_fDfA.xlsx'        
        %datafile = 'forcings/royer_fD.xlsx'        
        data;   % struct with raw data from spreadsheet columns Time(Ma) Paleogeog
    end
    
    methods
        % Constructor. This loads data when object is created
        function f = copse_force_royer_fD(extrapolate)
            f.extrapolate = extrapolate;
            f.load();
        end
        
        function load(obj)
            %%%% load data
            fprintf('loading Paleogeog data from "%s"\n',obj.datafile);      
            eru = xlsread(obj.datafile);
            obj.data.timeMa           = eru(:,1);            
            obj.data.Paleogeog         = eru(:,2);
        end
        
        function D = force(obj, tforce_presentdayiszeroyr, D )                                 
            % Convert requested time to offset used by the forcing file
            tMya = -tforce_presentdayiszeroyr/1e6;  % Mya
            if    obj.extrapolate &&  (tMya > obj.data.timeMa(1)) 
                D.PG = obj.extrapval;
            elseif obj.extrapolate && (tMya < obj.data.timeMa(end))
                D.PG = obj.extrapval;
            else
                D.PG   = interp1(obj.data.timeMa,obj.data.Paleogeog,tMya) ;  
            end
        end
        
    end
end


