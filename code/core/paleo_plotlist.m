classdef paleo_plotlist
    % Plot top level: multiple plots from 'listplots' using functions in 'plotters'
    
    properties
        plotters                = {};          % cell array of function handle with copse_plot_xxx
        listplots               = {};         % cell array of strings with list of plots.
        
        figfrac = 0;
        %figfrac = 0.8;     % figure size (fraction of screen), or 0 for Matlab default
                           % NB: on Matlab Windows (some versions), each window takes 
                           % ~width x height x 4 bytes of 'Java heap memory'
                           %                         = ~ 6MB for 'figfac = 0.8' (assuming 1920 x 1280 screen)
                           %                         = ~ 1MB for Matlab default figure size
          
        checkmem = true;   % true to check memory before creating a figure
        memcutoff = 50e6;  % refuse to plot another figure if Matlab memory drops below this value
        memfail    = 10e6; % error immediately if below this
        
        % see http://uk.mathworks.com/help/matlab/creating_plots/resolving-low-level-graphics-issues.html
        %forcepainters = true; % force matlab to use 'painters' renderer: possible workaround for TL PC issues..
        forcepainters = false;
        
        % add time, data, id to bottom-right of plot
        % NB: Matlab >= R2015b generates a spurious warning 'too many input arguments' 
        % if text width exceeds plot width
        addidstr = false;
        
        % Specify list of times for output display (eg ocean models)
        Ttoplot                   = [];
    end
    
    methods
        
        function plotlist( obj, XT, XTlimits, XTname, plotdata, varargin )
            %  Plot multiple plots across several figure windows
            %
            % paleo_plotlist( listplots, tlimits, pars, runctrl, T, S, diag, compareC514 )
            %
            % Args:
            %   listplots         -  requested list of plots (cell array of strings)
            %   XT                -  vector with x-axis (usually time)
            %   XTlimits          -  x(time)-axis limits ([xtmin xtmax], or '' for default)
            %   XTname            -  x axis label (usually empty)
            %   plotdata          - struct with files pars, runctrl, S, diag
            %   varargin          - optional comparison dataset, passed through to plotters
            %
            %
            
                       
          
            %Default x (time) axes limits
            if isempty(XTlimits)
                XTlimits = [XT(1) XT(end)];
            end
            
          
            
            
            % Find time step indices ~ corresponding to requested output times
            if isempty(obj.Ttoplot)
                tiplot = [1 length(XT)];  % t steps to plot
            else
                tiplot = [];
                for i = 1:length(obj.Ttoplot)
                    titoplot = find(XT>=obj.Ttoplot(i),1,'first');
                    if ~isempty(titoplot)
                        tiplot(end+1)=titoplot;
                    end
                end
            end
            
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%%%% SETUP
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Set plots per page
            nplotx=3;
            nploty=3;
            
            % Make figure windows as large as possible and slightly non-overlapping
            % ScreenSize is a four-elementvector: [left, bottom, width, height]:
            scrsz = get(0,'ScreenSize');
                    
            %colour for plot axes (?)
            plotcol=[0.95 0.95 0.95];
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%%%% END SETUP
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%% Iterate through list of requested plots
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            % subplot counter (zero offset, so subplot = iplot+1)
            iplot=nplotx*nploty;  % trigger new figure 
            % figure counter
            ifig = 1;

          
            for p = 1:length(obj.listplots)
                wplot=obj.listplots{p};
                
                if obj.checkmem
                    obj.CheckJavaHeapMem();
                end
                
                % generate new figure window
                if iplot >= nplotx*nploty
                    iplot = 0;
                    if obj.figfrac > 0 % large figure
                        figsz = [scrsz(3)*(1-obj.figfrac)-ifig*50 scrsz(4)*(1-obj.figfrac)-ifig*100 scrsz(3)*obj.figfrac scrsz(4)*obj.figfrac];
                        if obj.forcepainters
                            figure('Color',plotcol,'Position',figsz,'Renderer','painters');
                        else
                            figure('Color',plotcol,'Position',figsz);
                        end
                    else              % default size figure
                        if obj.forcepainters
                            figure('Color',plotcol,'Renderer','painters')
                        else
                            figure('Color',plotcol);
                        end
                    end
                    
                    ifig = ifig+1;
                    
                    if obj.addidstr && ~isempty(plotdata)
                        paleo_timestampplot(plotdata);
                    end
                end
                
                
                
                switch wplot
                    case 'startline'
                        % move iplot to beginning of line
                        if mod(iplot,nplotx) ~= 0
                            iplot = iplot + nplotx - mod(iplot,nplotx) ;
                        end
                    case 'skip'
                        %%%% leave a gap in the plot page
                        iplot=iplot+1;
                    case 'newpage'
                        %%%% force new page and do nothing
                        iplot = inf;
                    otherwise
                        %new plot panel                       
                        subplot(nploty,nplotx,iplot+1)
                        %generate the requested plot - carry on past error eg due to missing data
                        try
                            % iterate through the list of plotters until we find one that knows about this plot
                            iplnext = 1;
                            plotted = 0;
                            while ~plotted && iplnext <= length(obj.plotters)
                                plotted = obj.plotters{iplnext}( wplot, XT, XTlimits, tiplot, plotdata, varargin{:});
                                iplnext = iplnext + 1;
                            end
                            % plot not found ?
                            if ~plotted
                                error('Unknown plot %s',wplot);
                            else
                                if ~isempty(XTname)
                                    xlabel(XTname);
                                end
                            end
                        catch err
                            ploterr=sprintf('%s failed',wplot);
                            title(ploterr);
                            fprintf('plot %s:\n', ploterr);
                            disp(getReport(err,'extended'));
                        end
                        iplot=iplot+1;
                end
            end
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%% END Iterate through list of requested plots
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
          
            if obj.checkmem
                mem = paleo_plotlist.GetJavaHeapMem();
                fprintf('paleo_plotlist: Memory max %g total %g free %g avail %g\n',...
                    mem.max,mem.total,mem.free,mem.avail);
            end
         
        end
        
        function CheckJavaHeapMem(obj)
            % check Matlab memory
            % see http://stackoverflow.com/questions/6201272/how-to-avoid-matlab-crash-when-opening-too-many-figures
            
            mem = paleo_plotlist.GetJavaHeapMem();
            if mem.avail < obj.memcutoff && mem.avail > obj.memfail
                fprintf('paleo_plotlist: Memory is low max %g total %g free %g avail %g -> running garbage collector...\n please close some figure windows\n',...
                    mem.max,mem.total, mem.free, mem.avail);
                java.lang.Runtime.getRuntime.gc;
            end
            
            mem = paleo_plotlist.GetJavaHeapMem();            
            if mem.avail < obj.memcutoff
                fprintf('paleo_plotlist: Memory is low max %g total %g free %g avail %g\n',...
                    mem.max,mem.total, mem.free, mem.avail);
                error('Java memory low -> refusing to create a new figure! - please close some figure windows');
            end
            
        end
    end
    
    methods(Static)
        function mem = GetJavaHeapMem()
            mem.max  =java.lang.Runtime.getRuntime.maxMemory;
            mem.total=java.lang.Runtime.getRuntime.totalMemory;
            mem.free =java.lang.Runtime.getRuntime.freeMemory;
            mem.avail= mem.max - mem.total + mem.free;
        end
    end   
       
end

