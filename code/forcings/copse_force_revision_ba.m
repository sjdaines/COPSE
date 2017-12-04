classdef copse_force_revision_ba < copse_force
    %%% BA forcing from finished G3 paper
    properties
        estimate                    % estimate to use ('BAavg','BAmin','BAmax')
        extrapolate = 2;            % 0 none, 1 extrapolate out-of-range time values to extrapval, 2 extrapolate to first/last data points
        extrapval   = 1;            % used when extrapolate = 1
    end
    properties(SetAccess=private) % read-only
        datafile;  % data file used
        % struct with raw data from spreadsheet columns Time(Ma) BA(avg) BA(min) BA(max)
        data;
    end
    
    methods
        % Constructor. This loads data when object is created
        function obj = copse_force_revision_ba(estimate, datasource)
            obj.estimate = estimate;
            obj.load(datasource);
        end
        
        function load(obj, datasource)
            %%%% load revision basalt area
            switch datasource
                case 'xls'
                    % xls file from COPSE tree
                    obj.datafile = 'forcings/bas_area_mills2014.xlsx';
                    fprintf('loading g3 revision data table from "%s" estimate "%s" \n', obj.datafile,obj.estimate);
                    barevised = xlsread(obj.datafile);
                    obj.data.timeMa = barevised(:,1);
                    obj.data.BAavg    = barevised(:,2);
                    % obj.data.BAmin    = barevised(:,3);
                    % obj.data.BAmax    = barevised(:,4);
                    % SD columns were swapped
                    obj.data.BAmin    = barevised(:,4);
                    obj.data.BAmax    = barevised(:,3);
                case 'g3supp'
                    % .mat file provided as supp info
                    obj.datafile = 'forcings/ggge20620-sup-0002-suppinfo2.mat';
                    fprintf('loading g3 revision data table from "%s" estimate "%s" \n', obj.datafile,obj.estimate);                    
                    barevised = load(obj.datafile);
                    obj.data.timeMa = -barevised.BA_force2(:, 1);
                    obj.data.BAavg    = barevised.BA_force2(:,2)./barevised.BA_force2(end,2);
                    obj.data.BAmin    = barevised.BA_force2(:,4)./barevised.BA_force2(end,4);
                    obj.data.BAmax    = barevised.BA_force2(:,3)./barevised.BA_force2(end,3);
                otherwise
                    error('unrecognized datasource %s', datasource);
            end
        end
        
        function D = force(obj, tforce_presentdayiszeroyr, D )
                                 
            % Convert requested time to offset used by the forcing file
            tMa = -tforce_presentdayiszeroyr/1e6;  % Mya
            if obj.extrapolate == 1
                D.BA       = interp1([ 1e10; obj.data.timeMa(1)+1e-3; obj.data.timeMa; obj.data.timeMa(end)-1e-3; -1e10], ...
                                         [obj.extrapval; obj.extrapval; obj.data.(obj.estimate); obj.extrapval; obj.extrapval],...
                                         tMa) ; 
            elseif obj.extrapolate == 2
                D.BA       = interp1([ 1e10; obj.data.timeMa; -1e10], ...
                                         [ obj.data.(obj.estimate)(1); obj.data.(obj.estimate); obj.data.(obj.estimate)(end); ],...
                                         tMa) ; 
            else
                D.BA       = interp1(obj.data.timeMa,obj.data.(obj.estimate),tMa) ;                   
            end
            
        end
        
    end
end


