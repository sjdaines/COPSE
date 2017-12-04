classdef paleo_run < handle
    % Container for COPSE model, integrator, output data, postprocessing, and plotting
    %
    % Usually created and used by scripts in examples/copse
    % These scripts automate:
    % 1) Create paleo_run and populate with 'tm' (model), 'integrator', 'postprocessors', 'analyzers'
    % 2) paleo_run.initisalise()
    % 3) paleo_run.integrate()
    % 4) paleo_run.postprocess()
    % 5) paleo_run.saveoutput()
    % 6) paleo_run.plot()
    %
    % Saved runs can be reloaded with
    % > my_run = paleo_run.loadoutput(<filename>, <outputdir>)
    
    
    properties
        tm;                                             %  'The model'
        outputdir       = paleo_paths.getOutputDir();   % Directory for model output

        Tstart          = 0;                            % (yr) initial time 
        
        % set to list of times to save output (in S, diag). Empty means 'all' for adaptive timestepper
        timeoutput      = [];   
        
        integrator;                % paleo_integrate_xxx  time integrator
        
        % Model output
        Sinit           = struct;         % Sinit.statevar1(1 .. nT,1) or Sinit.Ocean.statevar(1 .. nbox)
        T               = [];             % T(1 .. nT)
        S               = struct;         % S.statevar1(1 .. nT,1) or S.Ocean.statevar1(1 .. nT, 1 .. nbox) 
        diag            = struct;         % diag.diagvar1(1 .. nT,1) or diag.Ocean.diagvar1(1 .. nT, 1 .. nbox) 
                
        postprocessors;           % function handle containing function to add additional checks/statistics etc following model run.
      
        budgets = struct;        % struct with summary output from postprocessing 
               
        %%% Name of results file (change this in config file to archive a run);                
        outputfile         = 'COPSEtesting';
        
        analyzers;            % run analysis
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Fields available to define / describe experiment
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Free-form text fields to identify run, label plots etc
        date               = datestr(clock);
        codefile           = mfilename('fullpath'); %
        
        config;                     % Matlab .m file that sets up model  
        baseconfig;                 % Parameter passed to 'config' to set baseline expt
        expt;                       % Parameter passed to 'config' to select specific experiment etc
        expars;                     % struct with any additional parameters                      
        
    end
    
    methods
        
        function initialise(obj)   
            % Initialise reservoirs (state variables)
        
            LN = 'paleo_run.initialise'; L = paleo_log.getLogger('paleo_run'); 
       
            L.log(L.INFO,LN, sprintf('initialise from parameters\n'));
            obj.Sinit              = obj.tm.initialise();

        end
        
        
        function integrate(obj)
            % Integrate ODE
            
            LN = 'paleo_run.integrate'; L = paleo_log.getLogger('paleo_run');
            
            L.log(L.INFO,LN, sprintf('start model integration\n'));
            L.log(L.INFO,LN, sprintf('(default) output dir %s\n', obj.outputdir)); 
            L.log(L.INFO,LN, sprintf('(default) outputfile %s\n', obj.outputfile)); 
            
            
            % standard ODE integration  
           
            [ obj.T, obj.S, obj.diag ] = obj.integrator.integrate( obj.tm, obj.Tstart, obj.Sinit, obj.timeoutput );
                   
        end
        
        function postprocess(obj)          
            % Integrate up budgets and do some conservation checks
            % (fills struct obj.budgets)
            
            LN = 'paleo_run.postprocess'; L = paleo_log.getLogger('paleo_run');
            pplist =  obj.postprocessors;
            if ~isempty(pplist)
                % handle a single postprocessor - put into a cell array
                if ~iscell(pplist)
                    pplist = {pplist};
                end
                
                % iterate through list
                for b=1:length(pplist)
                    switch class(pplist{b})
                        case 'function_handle'
                            % deprecated 
                            [ obj.diag, obj.budgets ] = pplist{b}( obj.T, obj.S, obj.diag,obj.budgets );
                        otherwise
                            % assume a paleo_postprocessor instance
                            [ obj.diag, obj.budgets ] = pplist{b}.calcall( obj.T, obj.S, obj.diag,obj.budgets );
                    end
                end
            else
                L.log(L.INFO,LN, sprintf('no postprocessors defined\n'));                
            end
        end
            
        function plot(obj, XTlimits, XTname, varargin)
            % Plot output
            %
            % Args:
            %   obj (paleo_run):                    class instance (generated automatically if called as paleo_run.plot)
            %   XTlimits ([xtmin xtmax], optional): x(time)-axis limits ('' for default)
            %   XTname (str, optional):             x axis label (usually empty)          
            %   varargin (paleo_run, optional):     comparison dataset, passed through to plotters
            
            LN = 'paleo_run.plot'; L = paleo_log.getLogger('paleo_run'); 
            if nargin < 2
                XTlimits = '';
            end
            if nargin < 3
                XTname = '';
            end
            
            if isempty(obj.analyzers)
                L.log(L.ERROR,LN, sprintf('no output plotter defined\n'));
            else
                obj.analyzers.plotlist(obj.T,XTlimits,XTname,obj,varargin{:});
            end
        end
              
        
        function t = astable(obj)
            % Return run output (T, S, diag) as a Matlab table
            %
            % Returns:
            %   t (table): T, S, diag as Matlab table 
            %               This can be viewed in the Matlab Workspace browser
            %               It can be written to a spreadsheet with
            %               > writetable(t,'test.xls')
            
            t = table(obj.T', 'VariableNames', {'T'});
            
            Sfields = fields(obj.S);
            for s = 1:length(Sfields)
                sf = Sfields{s};
                t.(sf) = obj.S.(sf);
            end
            
            Dfields = fields(obj.diag);
            for d = 1:length(Dfields)
                df = Dfields{d};
                t.(df) = obj.diag.(df);
            end
 
        end
        
        
        function saveoutput(obj, outfile, outputdir)
            % Save output
            %
            % Args:
            %   outfile (str, optional): ouput file, defaults to obj.outfile
            %   outputdir (str, optional): output folder, defaults to obj.outputdir
                        
            LN = 'paleo_run.saveoutput'; L = paleo_log.getLogger('paleo_run'); 
            
            % override outputfile if requested
            if nargin >= 2
                obj.outputfile = paleo_paths.fixFileSep(outfile);
            end            
            
            % override outputfile if requested
            if nargin >= 3
                obj.outputdir = paleo_paths.fixFileSep(outputdir);
            end
            
            
            % Transfer fields from the object to a struct and save that
            % This provides some backwards compatiblity, including at minimum ability to load the data fields
            % NB: if asked to save a class instance, Matlab will save, but then may fail to load (with warning) if
            % a class of that name is not present, or (worse) may appear to load but actually 'load' different code.
            % So to avoid this, we don't save class instances.
            rs.output_version = 'COPSE_2.0';
            p=properties(obj);
            for i=1:length(p);
                switch(p{i})
                    case {'outputdir', 'Tstart', 'timeoutput', 'Sinit', 'T', 'S', 'diag', 'outputfile', ...
                            'date', 'codefile', 'config', 'baseconfig', 'expt', 'expars'}
                        rs.(p{i}) = obj.(p{i});
                    case 'tm'
                        % transfer parameters, if present
                        % don't save the model instance, as that might change in future versions
                        if isprop(obj.tm, 'pars')
                            rs.tm = struct();
                            rs.tm.pars = obj.tm.pars;
                        end
                    otherwise
                        % don't save class instances, for future compatibility (see note above).
                end
            end
             
            pfile = fullfile(paleo_paths.fixFileSep(obj.outputdir),paleo_paths.fixFileSep(obj.outputfile));
            L.log(L.INFO,LN, sprintf('saving output to file %s\n',pfile));
            save(pfile,'rs');
        end
    end

    methods(Static)
        function obj = loadoutput(filename, outputdir)
            % Load output file
            %
            % Args:
            %   filename (str):  filename of output (optionally can be a full path)
            %   outputdir (str, optional):  folder for output, defaults to paleo_paths.getOutputDir()
            % Returns:
            %   obj (paleo_run): run loaded from disk
            
            LN = 'paleo_run.loadoutput'; L = paleo_log.getLogger('paleo_run'); 
            
            filename = paleo_paths.fixFileSep(filename);
            
            if strncmp(filename,filesep,1)
                L.log(L.INFO,LN, sprintf('using full path from filename %s\n',filename));                
            elseif nargin < 2 
                outputdir = paleo_paths.getOutputDir();
                L.log(L.INFO,LN, sprintf('using default outputdir %s\n',outputdir));
            else
               L.log(L.INFO,LN, sprintf('using supplied outputdir %s\n',outputdir)); 
            end
            
            pfile = fullfile(paleo_paths.fixFileSep(outputdir),filename);
            L.log(L.INFO,LN, sprintf('loading output from file %s\n',pfile));
             
            % load data into struct 'rs'
            load(pfile);
            
            obj = paleo_run();
            rsfields=fields(rs);
            p=properties(obj);           
            
            % transfer fields from struct to paleo_run, with some checking for mismatches
            for i=1:length(rsfields)
                pf = find(strcmp(p,rsfields{i}));
                if pf
                    obj.(rsfields{i}) = rs.(rsfields{i});
                    % remove from list of properties once set
                    p=p([1:pf-1 pf+1:end]);
                elseif strcmp(rsfields{i}, 'version')
                    % version of output data format - not stored                 
                else
                    L.log(L.INFO,LN, sprintf('no property for field %s\n',rsfields{i}));
                end  
            end

            for i=1:length(p)
                L.log(L.INFO,LN, sprintf('no data field for property %s\n',p{i}));
            end
            
            % update outputdir
            obj.outputdir = outputdir;
        end
    end
end