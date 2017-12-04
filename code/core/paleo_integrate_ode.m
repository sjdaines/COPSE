classdef paleo_integrate_ode < handle
    % Integrate using Matlab ode15s 'gear' stiff ODE solver
    % ODE only (no DAE support)
            
    properties
        timetoadd;  % yr to integrate for
      
         % For adaptive step size, identify any discontinuities (in forcings) and force restart with small step size
        timerestarts              = [];
 
        %%%%%%% Max function calls for integration (set to eg 1000 to force failure of runs
        %%%%%%% that make no progress)
        maxcalls                = Inf;
     
        
         % Report statistics after integration
        odeoptions               = odeset('Stats','on');

        %runctrl.odeoptions          = odeset(runctrl.odeoptions,'NonNegative','on','AbsTol',1e5) ;
        %runctrl.odeoptions          = odeset(runctrl.odeoptions,'RelTol',1e-5) ;  % almost identical run times vs default 1e-3 ?
        %runctrl.odeoptions          = odeset(runctrl.odeoptions,'BDF','on') ;
        

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Options used by COPSE_integrate 
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        timeint;                        % concatenation of timeend, timestart and timerestarts
        
        
        telltime         = 100;  % print status every telltime timesteps
        callsctr                = 0;   % counter for number of function calls used
        
        ncalls;                         % total number of calls actually used for integration 
        cpusec;                        % seconds of cputime used
        
        % Mapping from PALEO struct (S, diag) <-> Matlab Y vector
        StoYmapper;
    
        tm;                                % reference to tm (to pass to ode integrator)
    end
    
    
    methods
        function obj = paleo_integrate_ode(timetoadd)
            obj.timetoadd = timetoadd;
        end
        
        function [ T, S, diag ] = integrate( obj, tm, Tstart, Sinit, Timeoutput )
            %%%%%%% Sinit               initial conditions (struct with field for each state variable)
            %%%%%%% Sscale              scaling for each state variable
            %%%%%%%
            %%%%%%% Output:
            %%%%%%% T                   solution timesteps  (vector)
            %%%%%%% S                   solution state vector (struct, fields as Sinit, mapped from Marlab ODE solver Y vector)
            %%%%%%% diag                solution diagnostic variables (struct)
            %%%%%%%
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
                        
            % store reference to tm (in order to pass through to ode integrator)
            obj.tm  = tm;
            
            %Initialise struct <-> y vec mapper
            %obj.StoYmapper = paleo_Stovec(Sinit,'field');
            obj.StoYmapper = paleo_structtovec(Sinit,1,'field');
            
            % time cpu used
            cpustart           = cputime;
            
            % Matlab ODE solver with adaptive timestep
            
            
            % Initial values
            Yinit = obj.StoYmapper.struct2vector(Sinit);
            
            %Create vector of time intervals
            Tend = Tstart + obj.timetoadd;
            
            validrestarts=[];
            for i=1:length(obj.timerestarts);
                if obj.timerestarts(i) > Tstart && obj.timerestarts(i) < Tend
                    validrestarts(end+1) = obj.timerestarts(i);
                end
            end
            obj.timeint = [Tstart validrestarts Tend];
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%%%%% %Integrate forward in time restarting at specified intervals and
            %       concatenating output
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            
            for ti=1:(length(obj.timeint)-1)
                fprintf('\nintegrating from time\t%g\tto %g yr\n',obj.timeint(ti),obj.timeint(ti+1));
                % generate set of output times within this interval
                if ~isempty(Timeoutput)
                    outputidx = find(Timeoutput>obj.timeint(ti) & Timeoutput < obj.timeint(ti+1));
                    tspan = [obj.timeint(ti) Timeoutput(outputidx) obj.timeint(ti+1)];
                    fprintf('adaptive timestep: saving output at %g times :\n',length(tspan));
                    fprintf('  %g',tspan);
                    fprintf('\n');
                else
                    fprintf('adaptive timestep: saving output for every timestep\n');
                    tspan = [obj.timeint(ti) obj.timeint(ti+1)];
                end
                
                
                [Tint,Yint] = ode15s(@obj.ode_adaptor,tspan,Yinit,obj.odeoptions);
                %restart from where we just got to
                Yinit = Yint(end,:);
                %concatenate output
                if ti == 1
                    T = Tint;
                    Y = Yint;
                else
                    % start at second point to avoid repeating same T value which
                    % confuses interpolation etc
                    T = [T ; Tint(2:end) ];
                    Y = [Y ; Yint(2:end,:)];
                end
            end
            
            clear Tint Yint Yinit;      %clear intermediate results
            
            
            obj.ncalls     = obj.callsctr;
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%%%%% Second pass - calculate diagnostics (two passes as Matlab ODE solver
            %%%%%%% timesteps are not the same as function evaluations)
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            fprintf('calculating diagnostics...\n');
            
            diag = [];  % remove old data
            
            obj.callsctr    = 0;
            for idiag=1:length(T)
                
                SattimeT = obj.StoYmapper.vector2struct(Y(idiag,:));

                [dummy, D] = tm.timederiv(T(idiag),SattimeT);  
                
                %Store diagnostic variables in global struct diag for future analysis
                diag = paleo_structtovec.addRecord(diag, idiag,  D);                
                
            end
            
            % Convert T and S
            T = T';   % ' to convert to row vector for consistency with 'diag' and normal matlab use
            S=obj.StoYmapper.matrix2struct(Y);
            
            
            
            %%%%%%% Report cpu etc
            obj.cpusec = cputime - cpustart;
           
            fprintf('\nfunction evaluations (first pass) %g cputime (total) %g sec\n',obj.ncalls,obj.cpusec);
            
            
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Adaptor to map function required by Matlab ODE solver (using vectors)
        % to our version (using structs).
        % Also keeps track of number of function calls
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        function dydt = ode_adaptor(obj, tmodel,y)
            %  Called by Matlab ODE solver, adapts paleo_model.timederiv (based on struct S & dSdt) to Matlab vector Y & dYdt
            %
            % tmodel        - time, yr
            % y             - state vector, as passed in by Matlab ODE solver
            % dydt          - time derivate of state vector, as required by Matlab ODE solver
            %
            
            % Convert Matlab vector y -> our struct S
            S = obj.StoYmapper.vector2struct(y');
            
            % Call our paleo equations
            dSdt = obj.tm.timederiv(tmodel,S);
           
            % Convert our struct dSdt -> Matlab vector dydy
            dydt = obj.StoYmapper.struct2vector(dSdt);
            
            % Some housekeeping - report and check number of function calls
            
            % output timestep if specified
            if obj.telltime
                if mod(obj.callsctr,obj.telltime)==0
                    fprintf('nsteps % 10i tmodel % 16.4f\n',obj.callsctr,tmodel);
                end
            end
            obj.callsctr=obj.callsctr+1;
            
            % Force runs that make no progress (ie reduce step size and crawl to a halt) to exit,
            % enabling eg a grid of runs over a parameter space with some unfeasible regions
            if obj.callsctr > obj.maxcalls;
                ME = MException('PALEO:maxcalls','number of function calls obj.maxcalls %g exceeded',obj.maxcalls);
                throw(ME);
            end
            
        end
        

    end
    
    
end

