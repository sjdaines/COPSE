classdef copse_fig

    methods(Static)
        function xlim(limits, figs, direction)
            % COPSE_FIG.XLIM reset x axes of all subpanels within specified figures
            %
            % limits      - [xmin xmax]
            % figs        - 1, 1:4 etc
            % direction   - 'normal' or 'reverse'
            
            if nargin < 2
                figs = gcf;
            end
            
            if nargin < 3
                direction = 'normal';
            end
            
            %iterate through the supplied list of figures
            for fig = figs
                % find axes in figure, avoiding legends
                hlist=findobj(fig,'Type','axes','-not','Tag','legend');
                for hi=1:length(hlist)
                    xlim(hlist(hi),limits);
                    set(hlist,'XDir',direction);   % see 'Axes Properties' help page
                end
            end
        end
        
        function ylim(limits, figs, direction)
            % COPSE_FIG.YLIM reset Y axes of all subpanels within specified figures
            %
            % limits      - [ymin ymax]
            % figs        - 1, 1:4 etc
            % direction   - 'normal' or 'reverse'

            if nargin < 2
                figs = gcf;
            end

            if nargin < 3
                direction = 'normal';
            end

            %iterate through the supplied list of figures
            for fig = figs
                % find axes in figure, avoiding legends
                hlist=findobj(fig,'Type','axes','-not','Tag','legend');
                for hi=1:length(hlist)
                    ylim(hlist(hi),limits);
                    set(hlist,'YDir',direction);   % see 'Axes Properties' help page
                end
            end
        end
        
        function expand(figs, figfrac)
            % Expand figures - NB on some Windows Matlab versions, each figure takes ~ 6MB of Java Heap memory
            % which has a relatively small available ~128MB by default
            %
            % figs        - 1, 1:4 etc
            % figfrac     - fraction of screen
            if nargin < 1
                figs = gcf;
            end
            
            if nargin < 2
                figfrac = 0.8;
            end
            
            % Make figure windows as large as possible and slightly non-overlapping
            % ScreenSize is a four-elementvector: [left, bottom, width, height]:
            scrsz = get(0,'ScreenSize');
       
            
            %iterate through the supplied list of figures
            ifig = 1;
            for fig = figs
                figsz = [scrsz(3)*(1-figfrac)-ifig*50 scrsz(4)*(1-figfrac)-ifig*100 scrsz(3)*figfrac scrsz(4)*figfrac];
                set(fig,'Position',figsz);
                figure(fig);
                ifig = ifig + 1;
            end
        end
        
        
        function printpdf(fh, pdfname,sz,scx,scy, addfname)
            % print specified figure full-size on A4 paper
            %
            % Input:
            % fh          - figure handle (number)
            % pdfname     - filename for output
            % sz          - (optional, default 's') 'f' or 'l' (full A4 size) or 's' (square)
            % scx,scy     - (optional, default 1.0, 1.0) fractional size for output x,y
            % addfname    - (optional, default 1). 1 to add a text label with output
            %               filename, 0 to not add label.
            %
            % SD 2010-11-29  add comments for 'help'
            %
            % see MATLAB->Graphics->Printing and Exporting->Changing a Figure's settings

            if nargin < 3
                sz = 's';
            end

            if nargin < 4
                scx = 1.0;
            end

            if nargin < 5
                scy=scx;
            end

            if nargin < 6
                addfname = 1;
            end

            figure(fh);
            if addfname
                %location in 'normalized' plot coordinates (bottom left (0,0) top right (1,1)
                xloc=0.0;
                yloc=0.0;
                box=annotation('textbox',[xloc yloc 1.0 0.05]);
                btxt=['  ' (fullfile(pwd, pdfname))];
                set(box,'String',btxt,'Interpreter','none','Fontsize',6,'FitBoxToText','on');
                set(box,'LineStyle','none');
                set(box,'VerticalAlignment','bottom');
            end

            % see Matlab 'help print'
            set(fh,'PaperType','A4');


            if strcmp(sz,'f')
                orient('portrait');
                psize=get(gcf,'PaperSize');
                %20.9840   29.6774
                hzps=psize(1);
                vtps=psize(2);
                hzbord=0.6;
                vtbord=2;
                hzsz=hzps-hzbord*2;
                vtsz=vtps-vtbord*2;
            elseif strcmp(sz,'l')
                orient('landscape');
                psize=get(gcf,'PaperSize');
                %20.9840   29.6774
                hzps=psize(1);
                vtps=psize(2);
                hzbord=2;
                vtbord=0.6;
                hzsz=hzps-hzbord*2;
                vtsz=vtps-vtbord*2;
            elseif strcmp(sz,'s');
                orient('portrait');
                psize=get(gcf,'PaperSize');
                %20.9840   29.6774
                hzps=psize(1);
                vtps=psize(2);
                hzbord=0.6;
                hzsz=hzps-hzbord*2;
                vtsz=hzsz;
                vtbord=0.5*(vtps-vtsz);
            else
                error('unknown paper size',sz);
            end

            set(fh,'PaperPosition',[hzbord vtbord hzsz*scx vtsz*scy]);
            %defaults  get(gcf,'PaperPosition')
            %rect = [left, bottom, width, height]
            %0.6345    6.3452   20.3046   15.2284
            % which look wrong!? (width goes to extreme rh edge with border 0.6 at lh?)

            %SD 2010-07-29 '-painters' sets rendering algorithm
            %Matlab appears to be buggy here (or at least have cryptic behaviour)
            %sometimes it uses this by default, sometimes it uses something else and 
            %produces blocky output
            print(['-f' num2str(fh)],'-dpdf',pdfname, '-painters');
            %print(['-f' num2str(fh)],'-dpdf',pdfname, '-zbuffer');

            if addfname
                set(box,'String','');
            end
        end
           
    end
end