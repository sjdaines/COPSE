classdef copse_load_phanlip < handle
    % Load LIPs excel file and constructs copse_force_LIP forcings for use in model
    
    properties(SetAccess=private)     %can be read but not modified
        rev;       % data version
        datafile;  % spreadsheet with LIP data
        PhanLIPs;  % structure for input data    
    end
    
    methods
        % Constructor. This loads data when object is created
        function obj = copse_load_phanlip(rev)
            obj.rev = rev;
            switch obj.rev
                case 'mills2014g3'
                    obj.datafile = 'forcings/ggge20620-sup-0001-suppinfo1.xlsx';
                case 'copseRL'
                    obj.datafile = 'forcings/CR_force_LIP_table.xlsx';
                case {'copseRL_jw', 'copseRL_jw_revisedAreas'};
                    obj.datafile = 'forcings/CR_force_LIP_table_jw.xlsx';
                otherwise
                    error('undefined rev %s',rev)
            end
            
            obj.loadall();
        end
        
         function LIPs = create_LIPs(obj, co2releasefield, default_lambda, LIPtrange, smoothempl, areafac, decayoffset,  default_co2releasetime) 
            % Create a cell array of copse_force_LIP forcings, parameterised based on the spreadsheet data (and arguments).
            %
            % Args:
            %   co2releasefield (str):          spreadsheet field for CO2 release (see struct fields in load() ) 
            %   default_lambda (float):         (1/yr) default lambda for exponential area decay, for lips with unspecified present-day area
            %   LIPtrange (optional):           range of emplacement times to include, [tmin tmax] in yr, relative to present-day = 0
            %   smoothempl (bool, optional):    true to apply sigmoidal function to emplacement
            %   areafac (float, optional):      multiplier for lip area
            %   decayoffset (float, optional):  (yr) wait before erosion begins.               
            %   default_co2releasetime (float, optional): (yr) timescale for CO2 release, for lips where this is not specified
            %
            % Returns:
            %   LIPs (cell array of copse_force_LIP) : LIP forcings (one per row in input spreadsheet)
                
            if nargin < 4
                LIPtrange = [-Inf, Inf];  % include all lips
            end  
            if nargin < 5
                smoothempl = false;
            end            
            if nargin < 6
                areafac = 1;
            end
            if nargin < 7
                decayoffset = 0;
            end            
            if nargin < 8
                default_co2releasetime = 2e5;
            end
            
            % Initialise empty list of LIPs
            LIPs={};
                   
            % Iterate through rows in the spreadsheet                     
   
            for i=1:length(obj.PhanLIPs.Allages)           
                liptime = - obj.PhanLIPs.Allages(i)*1e6;  % emplacement time (or NaN) in yr, relative to present-day = 0
                if ~isnan(liptime) && (liptime >= LIPtrange(1)) && (liptime <= LIPtrange(2))
                    switch co2releasefield
                        case 'NoCO2'
                            lipCO2 = 0;
                        otherwise
                            lipCO2 =  NaNtodefault(obj.PhanLIPs.(co2releasefield)(i), 0.0);
                    end
                    co2releasetime = NaNtodefault(1e6*obj.PhanLIPs.DegassDuration(i), default_co2releasetime);
                    
                    peak_area = areafac*NaNtodefault(obj.PhanLIPs.CFBareas(i), 0.0);
                    
                    % calculate decay rate from present-day area, if available
                    present_area = obj.PhanLIPs.PresentDayArea(i);
                    if isnan(present_area)
                        % no present_area - use default lambda
                        lambda = default_lambda;
                    else
                        % calculate decay rate to give present day area
                        % present_area = peak_area*exp((liptime + decayoffset)*lambda)
                        lambda = log(present_area/peak_area)/(liptime + decayoffset);
                    end
                    
                    LIPs{end+1} = copse_force_LIP( ...
                        liptime, ...
                        obj.PhanLIPs.Names{i}, ...
                        obj.PhanLIPs.Types{i}, ...
                        peak_area, ...
                        smoothempl, ...
                        lipCO2, ...
                        decayoffset, ...
                        lambda, ...
                        co2releasetime);
                       
                    
                end
            end 
            
        end

        function [flips, default_lambda, lipsAll] = create_LIP_forcing(obj, Tstart, Tend, co2releasefield, present_CFB_area, varargin)
            % Create a LIP forcing function from data table, adjusting decay rates to match present_CFB_area
            %
            % Args:
            %   Tstart (float):  start of time range where forcing required
            %   Tend (float):    end of time range where forcing required
            %   co2releasefield: 'NoCO2', 'CO2min', 'CO2max'
            %   present_CFB_area (float):  (km2) target area, decay constant lambda (for those lips with unknown present day area) is adjusted to meet this
            %   varargin:        passed through to createLIPs: LIPtrange, smoothempl, areafac, decayoffset,  co2releasetime
            %
            % Returns:
            %   flips:          composite forcing (basalt area and CO2), pre-calculated interpolation to grid for range Tstart:Tend
            %   default_lambda: decay rate (for lips where present day area not available), to create present_CFB_area
            %   lipsAll (cell array): individual LIP forcings
 
            % solve for decay constant that provides present_CFB_area
            default_lambda = obj.match_present_CFB_area(present_CFB_area, co2releasefield, varargin{:});

            % create forcing
            % cell array of individual LIP forcings
            lipsAll = obj.create_LIPs(co2releasefield, default_lambda, varargin{:}); 
            % Create composite forcing, pre-calculated interpolation to tgrid.
            % NB: forcing will only be interpolated and available for range Tstart - Tend
            tgrid = Tstart:1e4:Tend;
            flips= copse_force_composite(lipsAll,tgrid,{'CFB_area','LIP_CO2','LIP_CO2moldelta'},[0 0 0]);
            flips.fastinterp=1;
            
            % check: evaluate present-day CFB area      
            D.CFB_area = 0;
            D.LIP_CO2 = 0;
            D.LIP_CO2moldelta = 0;
            D = flips.force(paleo_const.time_present_yr, D);
            
            frac_area_err = abs(D.CFB_area - present_CFB_area)/present_CFB_area;
            if frac_area_err > 1e-8
                error('LIP present_day_area failed, frac_area_err %g', frac_area_err);
            end
        end
        
        function default_lambda = match_present_CFB_area(obj, present_CFB_area, co2releasefield, varargin)
            % solve for decay rate that produces specified present_CFB_area (km2)
            % varargin is passed through to createLIPs: smoothempl, areafac, decayoffset,  co2releasetime
                     
            % anonymous function for root finder 
            areaDiff = @(lamb) obj.get_present_CFB_area(co2releasefield, lamb, varargin{:}) - present_CFB_area;
            
            options = optimset('Display','iter');
            
            default_lambda = fzero(areaDiff, [0.25e-8 4e-8],options);
                    
        end
                
        function present_day_CFB_area = get_present_CFB_area(obj, co2releasefield, default_lambda, varargin)
            % find present-day CFB area
            % varargin is passed through to createLIPs: smoothempl, areafac, decayoffset,  co2releasetime
                    
            lipsAll = obj.create_LIPs(co2releasefield, default_lambda, varargin{:});    
          
            flips= copse_force_composite(lipsAll);
       
            D.CFB_area = 0;
            D.LIP_CO2 = 0;
            D.LIP_CO2moldelta = 0;
            D = flips.force(paleo_const.time_present_yr, D);
            
            present_day_CFB_area = D.CFB_area;
        end
        
        function loadall(obj)
            % Load data from spreadsheet
            
            fprintf('loading all LIPs data from "%s"\n',obj.datafile);          

            % xlsread is very slow when columns are specified, so read the whole file then select columns
            [xlsnum, xlstxt, xlsraw] = xlsread(obj.datafile);
            
            % store the columns we want in a struct
            obj.PhanLIPs.Allages            = xlsnum(:,icolfromChar('A'));   % Mya
            num_lip_rows = length(obj.PhanLIPs.Allages);
            num_header_rows = 2;
            % check - Matlab prunes non-numeric rows from xlsnum, leaves all rows in xlsraw
            if xlsraw{num_header_rows + 1, icolfromChar('A')} ~= obj.PhanLIPs.Allages(1)
                error('unexpected spreadsheet format');
            end
            obj.PhanLIPs.Names              = strtrim(xlsraw(num_header_rows+1:num_header_rows+num_lip_rows, icolfromChar('B')));
            obj.PhanLIPs.Types              = strtrim(xlsraw(num_header_rows+1:num_header_rows+num_lip_rows, icolfromChar('C')));
            
            switch (obj.datafile)
                case {'forcings/ggge20620-sup-0001-suppinfo1.xlsx',  'forcings/CR_force_LIP_table.xlsx'}
                    obj.PhanLIPs.CFBareas           = xlsnum(:,icolfromChar('D'));   % km2
                    obj.PhanLIPs.Allvolume          = xlsnum(:,icolfromChar('E'));   % km3
                    obj.PhanLIPs.CO2min             = xlsnum(:,icolfromChar('F'));   % mol
                    obj.PhanLIPs.CO2max             = xlsnum(:,icolfromChar('G'));   % mol
                    obj.PhanLIPs.DegassDuration     = xlsnum(:,icolfromChar('H'));   % Myr
                    obj.PhanLIPs.PresentDayArea     = xlsnum(:,icolfromChar('I'));   % km2
                case 'forcings/CR_force_LIP_table_jw.xlsx'
                    switch(obj.rev)
                        case 'copseRL_jw'
                            obj.PhanLIPs.CFBareas           = xlsnum(:,icolfromChar('D'));   % km2
                        case 'copseRL_jw_revisedAreas'
                            obj.PhanLIPs.CFBareas           = xlsnum(:,icolfromChar('E'));   % km2
                        otherwise
                            error('unrecognized rev %s', obj.rev);
                    end
                    obj.PhanLIPs.Allvolume          = xlsnum(:,icolfromChar('F'));   % km3
                    obj.PhanLIPs.CO2min             = xlsnum(:,icolfromChar('G'));   % mol
                    obj.PhanLIPs.CO2max             = xlsnum(:,icolfromChar('H'));   % mol
                    obj.PhanLIPs.DegassDuration     = xlsnum(:,icolfromChar('I'));   % Myr
                    obj.PhanLIPs.PresentDayArea     = xlsnum(:,icolfromChar('J'));   % km2
                otherwise
                    error('unrecognized datafile %s', obj.datafile);
            end
                      
        end       
    end
end

function colidx = icolfromChar(colLet)
% Convert an upper-case column letter to numeric column index

    if length(colLet) ~=1
        error('column not single character %s',colLet)
    end
    colidx = unicode2native(colLet) - unicode2native('A') + 1;
    if (colidx < 1) || (colidx > 26)
        error('column out of range character %s',colLet);
    end
end

function y=NaNtodefault(x, default_value)
% Replace NaN with default_value
    if isnan(x)
        y=default_value;
    else
        y=x;
    end
end




