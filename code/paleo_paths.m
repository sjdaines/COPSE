classdef paleo_paths
    % Global path defaults
    % To override, create a 'paleo_local_paths' class with outputdir property
    
    properties(Constant)
        outputdir_rel  = 'output';  % relative to ../PALEO/
             
    end
    
    methods(Static)
        function paleo_root = paleo_root()
            % Full path to top-level PALEO directory
            thisfile = mfilename('fullpath');
            
            filesp = strfind(thisfile,filesep); % array of indices of / (or \)
            
            % ..  PALEO\code\paleo_paths.m
            %         end-1 end
            paleo_root = thisfile(1:filesp(end-1));                    
        end
        
        function outputdir = getOutputDir()
            % override outputdir definition with local value ?
            
            % machine specific file
            localmachinefile = ['paleo_local_paths_' paleo_paths.getHostname()];          
            
            if exist(localmachinefile,'class') && any(strcmp('outputdir',properties(localmachinefile)))
                % try a machine specific version first 
                outputdir = paleo_paths.fixFileSep(eval(sprintf('%s.outputdir',localmachinefile)));                
            elseif exist('paleo_local_paths','class') && any(strcmp('outputdir',properties('paleo_local_paths')))
                % or a generic local version
                outputdir = paleo_paths.fixFileSep(paleo_local_paths.outputdir);
            else
                % or the supplied standard version
                outputdir = fullfile(paleo_paths.paleo_root(), paleo_paths.fixFileSep(paleo_paths.outputdir_rel));
            end
            
            if ~exist(outputdir, 'dir')
                warning(['output dir\n%s\nis either not present or not a directory.\n' ...
                        '\nIf this path is correct, then please create the directory.\n' ...
                        '\nTo customize output path for all computer:\n' ...
                        'create and edit ''paleo_local_paths.m''\n' ...
                        'in directory ''%s'' ,\n' ...                        
                        '\nTo customize output path for this computer:\n' ...
                        'create and edit ''%s''\n' ...
                        '\n(use paleo_local_paths_example.m as an example)'], ...
                        outputdir, ....
                        fullfile(paleo_paths.paleo_root(),'code'),...                      
                        [localmachinefile '.m'] );
            end
                
            
        end
        
        function outputpath = getOutputPath(outputfile)
            outputpath = fullfile(paleo_paths.getOutputDir(),outputfile);
        end
        
       
        
        function hostname = getHostname()
            % short version of computer name.
            % Appears to work on Windows and linux
            %
            % eg to suffix machine-specific paths etc
            
            [ret, hostname] = system('hostname');   
            
            % trim trailing cr/lf (? or some invisible character..)
            hostname = strtrim(hostname);
            
            % substitute illegal Matlab filename characters
            % Matlab only allows letter, numbers, and underscores
            hostname = strrep(hostname,'-','_');
            
        end
            
        function path = fixFileSep(path)
            % Replace \ / with appropriate platform defaults
            path = strrep(path,'/',filesep);
            path = strrep(path   ,'\',filesep);
        end
    end
end

