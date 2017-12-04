classdef copse_force_haq_D < copse_force
    % New sea level inversion CO2 degassing forcing, with estimate for OIB area
    properties
        oib_area_scaling = 2e6;     % km2 for deg_relative = 1
        extrapolate = 1;            % 0 none, 1 extrapolate out-of-range time values to extrapval, 2 extrapolate to first/last data points
        extrapval   = 1;            % used when extrapolate = 1
    end
    properties(SetAccess=private) % read-only 
        %datafile = 'forcings/vandermeer_degassing.xlsx'
        %datafile = 'forcings/D_vandermeer.xlsx'
        %datafile = 'forcings/CR_force_D_temp.xlsx'
        %datafile = 'forcings/royer_D.xlsx'
        %datafile = 'forcings/D_haq_inversion.xlsx'
        datafile = 'forcings/D_haq_inversion_2017.xlsx'
        %datafile = 'forcings/D_max.xlsx'
        % struct with raw data from spreadsheet columns Time(Ma) D(avg) D(min) D(max)
        data;
    end
    
    methods
        % Constructor. This loads data when object is created
        function f = copse_force_haq_D()
            f.load();
        end
        
        function load(obj)
            %%%% load degassing
            fprintf('loading degassing data from "%s"\n',obj.datafile);      
            degassing = xlsread(obj.datafile);
            obj.data.timeMa = degassing(:,1);
            obj.data.D    = degassing(:,2);
        end
        
        function D = force(obj, tforce_presentdayiszeroyr, D )
                                 
            % Convert requested time to offset used by the forcing file
            tMa = -tforce_presentdayiszeroyr/1e6;  % Mya
            if obj.extrapolate == 1
                D.DEGASS       = interp1([ 1e10; obj.data.timeMa(1)+1e-3; obj.data.timeMa; obj.data.timeMa(end)-1e-3; -1e10], ...
                                         [obj.extrapval; obj.extrapval; obj.data.D; obj.extrapval; obj.extrapval],...
                                         tMa) ; 
            elseif obj.extrapolate == 2
                D.DEGASS       = interp1([ 1e10; obj.data.timeMa; -1e10], ...
                                         [ obj.data.D(1); obj.data.D; obj.data.D(end); ],...
                                         tMa) ; 
            else
                D.DEGASS       = interp1(obj.data.timeMa,obj.data.D, tMa) ;                   
            end
            D.oib_area     = obj.oib_area_scaling*D.DEGASS ;
        end
        
        function oib_area = present_day_OIB_area(obj)
            % return present-day oib_area for use in model initialisation
            D = obj.force(paleo_const.time_present_yr, struct());
            oib_area = D.oib_area;
        end
    end
end


