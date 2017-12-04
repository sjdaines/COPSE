classdef copse_force_vandermeer < copse_force
    % Vandermeer CO2 degassing forcing, with estimate for OIB area
    properties
        oib_area_scaling = 2e6;     % km2 for deg_relative = 1
        estimate                    % estimate to use ('Davg','Dmin','Dmax')
        extrapolate = 1;            % 0 none, 1 extrapolate out-of-range time values to extrapval, 2 extrapolate to first/last data points
                                    % 3 G3 bug compatibility, DEGASS as extrapolate=1, oib_area as extrapolate=2
        extrapval   = 1;            % used when extrapolate = 1
    end
    properties(SetAccess=private) % read-only 
        %datafile = 'forcings/vandermeer_degassing.xlsx'
        datafile = 'forcings/D_vandermeer.xlsx'
        %
        % NB: D_vandermeer_Ben.xlsx includes an additional value at 250Ma
        % (extrapolation from 230Ma) [and also swaps the column order D(min) <-> D(max)]
        % The check output 'g3_outputs_avg.mat' agrees with D_vandermeer.xlsx
        % (hence generates a step in DEGASS from 1 -> 1.566034 at 230Ma)
        %
        % datafile = 'forcings/D_vandermeer_Ben.xlsx'
        % struct with raw data from spreadsheet columns Time(Ma) D(avg) D(min) D(max)
        %              or D_vandermeer_Ben              Time(Ma) D(avg) D(max) D(min)
        data;
    end
    
    methods
        % Constructor. This loads data when object is created
        function f = copse_force_vandermeer(estimate, extrapolate)
            f.estimate = estimate;
            f.extrapolate = extrapolate;
            f.load();
        end
        
        function load(obj)
            %%%% load vandermeer degassing
            fprintf('loading Vandermeer degassing data from "%s"\n',obj.datafile);      
            degassing_vandermeer = xlsread(obj.datafile);
            obj.data.timeMa = degassing_vandermeer(:,1);
            obj.data.Davg    = degassing_vandermeer(:,2);
            obj.data.Dmin    = degassing_vandermeer(:,3);
            obj.data.Dmax    = degassing_vandermeer(:,4);
            % NB: column order for D_vandermeer_Ben.xlsx
            % obj.data.Dmin    = degassing_vandermeer(:,4);
            % obj.data.Dmax    = degassing_vandermeer(:,3);
        end
        
        function D = force(obj, tforce_presentdayiszeroyr, D )
                                 
            % Convert requested time to offset used by the forcing file
            tMa = -tforce_presentdayiszeroyr/1e6;  % Mya
            if obj.extrapolate == 1
                D.DEGASS       = interp1([ 1e10; obj.data.timeMa(1)+1e-3; obj.data.timeMa; obj.data.timeMa(end)-1e-3; -1e10], ...
                                         [obj.extrapval; obj.extrapval; obj.data.(obj.estimate); obj.extrapval; obj.extrapval],...
                                         tMa) ; 
                D.oib_area     = obj.oib_area_scaling*D.DEGASS ;
            elseif obj.extrapolate == 2
                D.DEGASS       = interp1([ 1e10; obj.data.timeMa; -1e10], ...
                                         [ obj.data.(obj.estimate)(1); obj.data.(obj.estimate); obj.data.(obj.estimate)(end); ],...
                                         tMa) ; 
                D.oib_area     = obj.oib_area_scaling*D.DEGASS ;
            elseif obj.extrapolate == 3
                % G3 bug compatibility
                % DEGASS extrapolate to extrapval
                D.DEGASS       = interp1([ 1e10; obj.data.timeMa(1)+1e-3; obj.data.timeMa; obj.data.timeMa(end)-1e-3; -1e10], ...
                                         [obj.extrapval; obj.extrapval; obj.data.(obj.estimate); obj.extrapval; obj.extrapval],...
                                         tMa) ;
                % oib_area extrapolate to first/last data points
                D.oib_area     = obj.oib_area_scaling* ...
                                 interp1([ 1e10; obj.data.timeMa; -1e10], ...
                                         [ obj.data.(obj.estimate)(1); obj.data.(obj.estimate); obj.data.(obj.estimate)(end); ],...
                                         tMa) ;               
            else
                D.DEGASS       = interp1(obj.data.timeMa,obj.data.(obj.estimate),tMa) ;
                D.oib_area     = obj.oib_area_scaling*D.DEGASS ;
            end            
        end
        
    end
end


