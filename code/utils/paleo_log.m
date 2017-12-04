classdef paleo_log < handle
    % PALEO log class
    % 
    % Simple logger based on ideas from log4j 
    % Modified version of 'log4m' which is available at 
    %     http://uk.mathworks.com/matlabcentral/fileexchange/37701-log4m-a-powerful-and-simple-logger-for-matlab/content/log4m.m
    
    properties (Constant)
        ALL = 0;
        TRACE = 1;
        DEBUG = 2;
        INFO = 3;
        WARN = 4;
        ERROR = 5;
        FATAL = 6;
        OFF = 7;
    end
    
    properties(SetAccess = protected)   
        logger;      % our name
        commandWindowLevel = paleo_log.INFO;
        fullpath;      
        fileLevel = paleo_log.ALL;
        fileID;
    end
    
    methods (Static)
        function initialise()
            % Reset and remove any existing loggers
            
            % Unfortunate workaround to signal to getLogger (which is managing logger instances)
            paleo_log.getLogger('','','');
            
            
        end
        
        function obj = getLogger( logger, create, init)
            % Return a logger object 
            % With no arguments, returns default top-level logger
            % Optional 2nd argument returns a specific logger (if configured)
            % Optional 3rd argument signal initialise (value is ignored)
            
            persistent loggerObject;  % top level default
            persistent loggerMap;     % optional specific loggers
            
            if nargin > 2
                % initialise - clear any installed loggers
                loggerObject = '';
                loggerMap = '';
            else
                % normal case
                
                if isempty(loggerObject)
                    loggerObject = paleo_log('default');  % create default object
                end
                
                if nargin < 1
                    % return default top-level logger
                    obj = loggerObject;
                else
                    % create a new logger if not
                    if nargin >= 2 && create
                        loggerMap.(logger) = paleo_log(logger);
                    end
                    
                    % return custom logger if available, otherwise system logger
                    if isempty(loggerMap) || ~isfield(loggerMap,logger)
                        obj = loggerObject;
                    else
                        obj = loggerMap.(logger);
                        
                    end
                end
            end
        end
        
         function outputpath = getOutputPathTimeStamped(outputroot, timestamp)
            % timestamped full path in output folder
            
            if nargin < 2
                timestamp = paleo_log.getTimestamp();
            end
            
            outputpath = fullfile(paleo_paths.getOutputDir(),[ outputroot timestamp '.log']);
         end
        
         function timestamp = getTimestamp()
             % character string timestamp for current time 
             % apparently datetime is only in recent (> 2013 ?) Matlab versions
             %timestamp = char(datetime('now','Format','yyyyMMdd-HHmm'));
             [Y, M, D, H, MN, S] = datevec(now);
             timestamp = sprintf('%4i%02i%02i-%02i%02i',Y, M, D, H, MN);
         end
    end
    
    methods
        function setCommandWindowLevel(obj,loggerIdentifier)
            obj.commandWindowLevel = loggerIdentifier;
        end
       
        function setFileLevel(obj,loggerIdentifier)
            obj.fileLevel = loggerIdentifier;
        end
        
        function setLogFile(obj, filename)
            if ~isempty(obj.fileID)
                obj.log(obj.WARN,'paleo_log',sprintf('closing existing log file %s\n',obj.fullpath));
                fclose(obj.fileID);
                obj.fileID = ''; 
                obj.fullpath = '';                
            end
            
            obj.fullpath = filename;
            obj.fileID = fopen(obj.fullpath, 'w');
            obj.log(obj.INFO,'paleo_log',sprintf('opening log file %s\n',obj.fullpath));
        end
        
        function log(obj, level, funcName, message)
            if obj.commandWindowLevel <= level
                switch level
                    case obj.WARN
                        warning('%s: %s', funcName, message);
                    case obj.ERROR
                        error('%s: %s', funcName, message);
                    otherwise
                       fprintf('%s: %s', funcName, message);
                end
            end
            
            if ~isempty(obj.fileID) && obj.fileLevel <= level 
                fprintf(obj.fileID, '%s: %s', funcName, message);
            end
        end

    end
    methods(Access = private)
        function obj = paleo_log(logger)
            obj.logger = logger;
        end
             
        
        function delete(obj)
            if ~isempty(obj.fileID)
                fclose(obj.fileID);
            end
        end
    end
end

