classdef copse_force_LIP < copse_force
    % Forcing (CO2, basalt area) due to one LIP
    %
    %
    properties
        Name           % vector of spreadsheet rows accumulated into this event
        Type
        liptime        % emplacement time, yr relative to present-day
        peakCFBarea    % km2 peak area exposed to subaerial weathering
        presentCFBarea % km2 present-day area, or NaN if not available
        co2_potential  % co2 released (mol C)
        co2_d13c = -5  % co2 release isotopic composition TODO value ?
        
        decayoffset;   % yr    wait before erosion begins.       
        lamb;          % 1/yr lambda for exponential area decay
        co2releasetime; % yr  timeframe for CO2 release (yrs) (full width of gaussian)
        smoothempl;     % true for sigmoidal emplacement
    end
    
    methods
        
        function f = copse_force_LIP(liptime, Name, Type, peakCFBarea, smoothempl, co2_potential, decayoffset, lamb, co2releasetime)
            % Constructor. See properties for information on parameters
            %          
            f.liptime = liptime;
            f.Name = Name;
            f.Type = Type;
            f.peakCFBarea = peakCFBarea;
            f.smoothempl = smoothempl;
            f.co2_potential = co2_potential;
            f.decayoffset = decayoffset;
            f.lamb = lamb;
            f.co2releasetime = co2releasetime;
        end
        
        function area = calc_LIP_CFBarea(obj,timeyr)
            % create a sigmoidal or step rise and exponential decline in area.
            
            smoothing = 3e-6 ; %%% smooth curve to build up area
            offset = 1.5e6; %%% shift curve
            
            if obj.smoothempl
                %%% emplacement function is made from sigmoid
                empl = sigmoid(smoothing,timeyr - obj.liptime + offset);
            else
                % step at obj.liptime
                empl = 0.5 + 0.5.*sign(timeyr - obj.liptime);
            end
            %  exponential decay
            erode =  ( 0.5 + 0.5.*sign(timeyr - obj.liptime - obj.decayoffset) ) ...
                        .* ( 1 - exp(-obj.lamb*(timeyr - obj.liptime - obj.decayoffset) ) ); 
            
            area =  obj.peakCFBarea.*(empl - erode);
        end
        
        function co2release = calc_LIP_co2(obj,timeyr)
            % release function uses gaussian
            co2release =  obj.co2_potential.*gaussnorm(0.5*obj.co2releasetime,timeyr - obj.liptime)  ;
        end
        
        
        function D = force(obj, tforce_presentdayiszeroyr, D )
            % Calculate basalt area and CO2 releate
            D.CFB_area = D.CFB_area + obj.calc_LIP_CFBarea(tforce_presentdayiszeroyr) ;
            co2 = obj.calc_LIP_co2(tforce_presentdayiszeroyr) ;            
            D.LIP_CO2  = D.LIP_CO2 + co2;
            D.LIP_CO2moldelta = D.LIP_CO2moldelta + co2*obj.co2_d13c;
        end
    end
end

function s=sigmoid(smooth, t)
    s = 1./(1+exp(-t*smooth));
end

function g=gaussnorm(width,offset)
    g = 1./(width*(2*pi)^0.5)*exp(-offset.^2/(2*width^2));
end
