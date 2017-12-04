classdef paleo_parameterset
    % A parameter set contains 'configdata' read from 'configname' in yaml 'configfile'.
    %
    % The yaml configfile should contain configuration data at the top level, eg
    %
    % copse_reloaded:
    %       <configuration> 
    %
    % copse_bergman2004:
    %      <another configuration>
    %
    
    properties(SetAccess=private)
        configfile   = '';   % configfile read
        configname   = '';   % named configuration from that file
        
        configdata;                   % struct with data from configfile.(configname)
    end
    
    properties(Constant)
        reservedFields = {'class'};    % fields in config file to ignore;
    end
        
    methods
        function obj = paleo_parameterset(configfile, configname)
            % Read configuration data from yaml parameter file (which may have multiple configs within)
            
            % Read entire parameter file (which may contain multiple configurations)
            obj.configfile = configfile;
            filects = ReadYaml(configfile); 

            % Get the data for the specified configname
            obj.configname = configname;
            if  isfield(filects, obj.configname)
                obj.configdata = filects.(obj.configname);
            else
                error('no configname %s in configfile %s', obj.configname, obj.configfile);
            end
        end
        
        
        function target = configureobject(obj, target, configpath, targetname)
            % Set properties/fields on a single object 'target' from location 'configpath' in 'configdata'
            %
            % Input:
            % target    - object to be configured 
            % configpath - path within obj.configdata containing configuration for 'target'
            % targetname - [optional] name of target object. This makes the target object fields
            %              available when evaluating a parameter, to allow eg par1 = (2*pars.par2)        
            %
            % Returns:
            % target    - configured object
            
            LN = 'paleo_parameterset.configureobject'; L = paleo_log.getLogger(LN); 
            
            
            % Find the configuration data at location configpath
            % (configdata has been read from file, configpath is specified as an argument)
            targetconfig = paleo_parameterset.findElem(obj.configdata, configpath);
                           
            if isempty(targetconfig)
                error('no config for configfile %s configname %s configpath %s', obj.configfile, obj.configname, configarg);
            else
                % configure target ...
 
                rpars = fields(targetconfig);
  
                % apply config to target object properties, ignoring reserved fields
                for rp = 1:length(rpars)
                    if ~any(strcmp(rp, obj.reservedFields)) % ignore reserved fields
                        subval = paleo_parameterset.subValue(targetconfig.(rpars{rp}), targetname, target);
                        L.log(L.TRACE, LN, sprintf('<target>.%s=%s\n', rpars{rp}, subval)); 
                        target.(rpars{rp}) = subval;
                    end
                end
            end
        end
    end
    
    
    methods(Static)
        function subval = subValue(val, ctxtname, ctxtdata)
            % parameter substitution.
            %
            % Input:
            % val      - parameter value either as a string (which will be evaluated if an expression in round brackets),
            %            or a string without brackets or non-string (which will just be returned directly)
            % ctxtname - [optional] name of a struct or object (eg 'pars') to provide as context for evaluation.
            % ctxtdata - [optional] value of this struct or object
            %
            % Returns: 
            % subval   - parameter value, either as-supplied if non-string, or evaluated from a supplied string
                       
            if nargin < 2
                ctxtname = '';
            end
            
            if ischar(val)
                % evaluate string-valued parameter if of from '(expr)'
                
                % guard against inadvertent use of 'false' or 'true' which are parsed as strings, not logicals
                % use true and false (no quotes)
                if any(strcmp(val,{'false','true'}))
                    error('''false'' and ''true'' strings illegal in parameter value - remove quotes');
                end
                % TODO guard against strings that look like they might be supposed to be numeric expressions
                % or attempts to set numeric fields to strings?
                
                % If string is of form '(expr)', evaluate 
                if ~isempty(val) && strcmp(val(1),'(') && strcmp(val(end),')')
                    % evaluate contents of brackets so (2+2) = 4 etc
                    if ~isempty(ctxtname)
                        % provide optional context for evaluation
                        eval([ctxtname '= ctxtdata;']);
                    end
                    subval = eval(val);
                else
                    % no brackets - just return the raw string
                    subval = val;
                end
            else
                % return unmodified non-string value
                subval = val;
            end
        end
    
        
        function elem = findElem(data, path)
            % find element within structure-tree 'data' at location 'path'
            % eg
            % data.x.y = elem
            % path = 'x.y' 
            
            % split path on .              
            psplit = strsplit(path,'.');
            
            % navigate into data to find elem
            elem = data;
            if ~isempty(psplit{1}) % NB: strsplit('','.') returns {''} 
                for i=1:length(psplit)
                    if isfield(elem, psplit{i})
                        elem = elem.(psplit{i});
                    else
                        error('path %s not present',  path);                       
                    end
                end
            end           
        end
    end
end

