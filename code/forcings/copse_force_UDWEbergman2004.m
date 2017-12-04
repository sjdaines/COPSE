classdef copse_force_UDWEbergman2004 < copse_force
    % Interpolate and optionally apply naive extrapolation of forcings into (constant) Precambrian and future
    %
    % U  tectonic uplift   
    %       GEOCARB II (Berner 1994) based on Sr isotopes
    % D  metamorphic and volcanic degassing. 
    %       Bergman etal (2004), same as GEOCARB II (Berner 1994): 
    %       Engerbretson etal (1992) seafloor subduction (spreading) rate 0 - 150Ma, 
    %       Gaffin (1987) Paleo-sealevel based 570 - 150Ma 
    % E  land plant evolution and colonisation
    %       Bergman etal (2004)
    % W  biological enhancement of weathering
    %       Bergman etal (2004)
    %
    properties
        doU = 1;
        doD = 1;
        doE = 1;
        doW = 1;
    end
    properties(SetAccess=private)
        extrapolate;
        C_514_forcings;        
        forcingfile='forcings/copse_forcings';
    end
    
    methods
        % Constructor. This loads data when object is created
        function f = copse_force_UDWEbergman2004(extrapolate)
            f.extrapolate = extrapolate;
            f.load();
        end
        
        % Load data from Noam's COPSE run, datafile modified to remove NaNs
        function load(obj)
             
            fprintf('loading U,D,W,E forcings from COPSE datafile "%s"\n',obj.forcingfile);
   
            load(obj.forcingfile);
            
            % Label with present epoch at year time_present_yr (zero in this case)
            obj.C_514_forcings.time_present_yr = 0;
            
            %%%% convert time to forwards in years
            obj.C_514_forcings.Tyr = - copse_forcings(:,1) ;
                       
            obj.C_514_forcings.U=copse_forcings(:,2);
            obj.C_514_forcings.D=copse_forcings(:,3);
            obj.C_514_forcings.W=copse_forcings(:,4);
            obj.C_514_forcings.E=copse_forcings(:,5);
            
        end
        
        function D = force(obj, tforce_presentdayiszeroyr, D)
            % Convert requested time to offset used by the forcing file
            tforce = tforce_presentdayiszeroyr + obj.C_514_forcings.time_present_yr;
            
            if obj.doU
                if obj.extrapolate && (tforce  < obj.C_514_forcings.Tyr(1))
                    D.UPLIFT        = 1;
                elseif obj.extrapolate && (tforce  > obj.C_514_forcings.Tyr(end))
                    D.UPLIFT        = 1;
                else
                    D.UPLIFT        = interp1(obj.C_514_forcings.Tyr,obj.C_514_forcings.U,tforce) ;
                end
            end
            if obj.doD
                if obj.extrapolate && (tforce  < obj.C_514_forcings.Tyr(1))
                    D.DEGASS        = 1;
                    
                elseif obj.extrapolate && (tforce  > obj.C_514_forcings.Tyr(end))
                    D.DEGASS        = 1;
                else
                    D.DEGASS        = interp1(obj.C_514_forcings.Tyr,obj.C_514_forcings.D,tforce) ;
                end
            end
            if obj.doW
                if obj.extrapolate && (tforce  < obj.C_514_forcings.Tyr(1))
                    D.W             = 0;
                elseif obj.extrapolate && (tforce  > obj.C_514_forcings.Tyr(end))
                    D.W             = 1;
                else
                    D.W             = interp1(obj.C_514_forcings.Tyr,obj.C_514_forcings.W,tforce) ;
                end
            end
            if obj.doE
                if obj.extrapolate && (tforce  < obj.C_514_forcings.Tyr(1))
                    D.EVO           = 0;
                elseif obj.extrapolate && (tforce  > obj.C_514_forcings.Tyr(end))
                    D.EVO           = 1;
                else
                    D.EVO           = interp1(obj.C_514_forcings.Tyr,obj.C_514_forcings.E,tforce) ;
                end
            end
        end
    end
end

