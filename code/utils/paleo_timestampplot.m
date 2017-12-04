function paleo_timestampplot(optlabel)
%  Label current figure with run info and current time.
% Three options:
%  - no argument: just timestamp at bottom right
%  optlabel = string argument: just text at bottom left
%  optlabel = paleo_run instance as argument: COPSE-specific run info

%location in 'normalized' plot coordinates (bottom left (0,0) top right (1,1)
xloc=0.0;
yloc=0.0;
box=annotation('textbox',[xloc yloc 1.0 0.06]);
set(box,'LineStyle','none');

if nargin < 1  % just timestamp
  
    c=fix(clock);
    btxt=sprintf('%s %02i:%02i  ',  date, c(4),c(5));
    set(box,'String',btxt);
    set(box,'HorizontalAlignment','Right');
   
else
    if  isobject(optlabel) % full info from runctrl struct       
        run = optlabel;
        % config;                     % Matlab .m file that sets up model  
        % baseconfig;                 % Parameter passed to 'config' to set baseline expt
        % expt;                       % Parameter passed to 'config' to select specific experiment etc
        % apply defaults if necessary (local changes as Matlab copies arguments)
        config = run.config;
        if isempty(config)
            config = '<not set>';
        end
        baseconfig = run.baseconfig;
        if isempty(baseconfig)
            baseconfig = '<not set>';
        end
        expt = run.expt;
        if isempty(expt)
            expt = '<not set>';
        end
        
        rundesc = sprintf('Run: config ''%s'' baseconfig ''%s'' expt ''%s'' outputfile ''%s'' Date: %s Plot: %s',...
            config, baseconfig, expt, run.outputfile, run.date, datestr(clock));
        
        btxt={sprintf('Code: %s', run.codefile);rundesc};
        %btxt=rundesc(1:148);
 
        set(box,'HorizontalAlignment','Right','FitBoxToText','Off');
        set(box,'LineStyle','none');
        set(box,'Interpreter','none','Fontsize',6);
        %Matlab R2015b generates a spurious warning 'too many input arguments' if text width exceeds plot width
        set(box,'String',btxt)
       
         
    elseif ischar(optlabel)      % text string, bottom left
        btxt=sprintf('  %s', txt);
        set(box,'String',btxt);
        set(box,'HorizontalAlignment','Left');    
    else
        error('copse_timestampplot - unrecognized argument');
    end
end

end