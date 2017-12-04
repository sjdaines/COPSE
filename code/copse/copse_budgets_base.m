classdef copse_budgets_base < paleo_postprocessor
    
    properties
        
    end
    
    methods
        function [ diag, budgets ] = calcall(obj, T, S, diag, budgets )
            %COPSE_BUDGETS_BASE Integrate budgets and check conservation (COPSE 'classic')
            %
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Derive budgets
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            % Calculate Ca budget - split into silicate+C, CAL+sulphates as these are separately conserved (in COPSE base)
            % Ca in silicate crust
            % Integrate up some useful budgets that enable us to track Ca in silicate crust
            diag.int_silw = zeros(length(T),1);
            diag.int_sfw = zeros(length(T),1);
            diag.int_ccdeg=zeros(length(T),1);
            diag.int_gypdeg = zeros(length(T),1);
            if isfield(diag,'silw')
                for idiag=2:length(T)
                    diag.int_silw(idiag) = diag.int_silw(idiag-1)+trapz(T(idiag-1:idiag),diag.silw(idiag-1:idiag));
                end
            end
            if isfield(diag,'sfw')
                for idiag=2:length(T)
                    diag.int_sfw(idiag) = diag.int_sfw(idiag-1)+trapz(T(idiag-1:idiag),diag.sfw(idiag-1:idiag));
                end
            end
            if isfield(diag,'ccdeg')
                for idiag=2:length(T)
                    diag.int_ccdeg(idiag) = diag.int_ccdeg(idiag-1)+trapz(T(idiag-1:idiag),diag.ccdeg(idiag-1:idiag));
                end
            end
            if isfield(diag,'gypdeg')
                for idiag=2:length(T)
                    diag.int_gypdeg(idiag) = diag.int_gypdeg(idiag-1)+trapz(T(idiag-1:idiag),diag.gypdeg(idiag-1:idiag));
                end
            end
            
            % Ca in silicate crust relative to initial condition
            diag.clc_deltaCaSil = diag.int_ccdeg + diag.int_gypdeg - diag.int_silw - diag.int_sfw;
           
            % Ca in CAL and S reservoirs (if any)
            diag.clc_CALGYPSCa = zeros(length(T),1);
            if isfield(S,'CAL')
                diag.clc_CALGYPSCa = diag.clc_CALGYPSCa + S.CAL;
            end
            if isfield(S,'GYP')
                diag.clc_CALGYPSCa = diag.clc_CALGYPSCa + S.GYP;
            end
            
            % Net Earth surface Ca
            diag.clc_CaNet = diag.clc_CALGYPSCa + S.C + diag.clc_deltaCaSil;
            
            % Redox
            % Carbon reservoirs redox change
            diag.clc_RedoxC = S.C + S.A;
            % Sulphur reservoirs redox change
            diag.clc_RedoxS = zeros(length(T),1);
            if isfield(S,'S')
                diag.clc_RedoxS = diag.clc_RedoxS + 2*S.S;
            end
            if isfield(S,'GYP')
                diag.clc_RedoxS = diag.clc_RedoxS + 2*S.GYP;
            end
            
            % Overall surface system redox change
            diag.clc_RedoxNet = diag.clc_RedoxC + S.O + diag.clc_RedoxS;
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Check conservation of budgets
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            % Carbon
            budgets.totalcarbon=(S.A(end)+S.G(end)+S.C(end))  -(S.A(1)+S.G(1)+S.C(1));
            
            % Redox
            budgets.totalO2equiv = diag.clc_RedoxNet(end) - diag.clc_RedoxNet(1);
            
            % Ca in CAL and sulphates
            budgets.CALGYPSCa = diag.clc_CALGYPSCa(end) - diag.clc_CALGYPSCa(1);
            % Ca in crust and carbonates
            budgets.CsilCa = (S.C(end) + diag.clc_deltaCaSil(end)) - ...
                (S.C(1) + diag.clc_deltaCaSil(1));
            % Ca total
            budgets.totalCa = diag.clc_CaNet(end) - diag.clc_CaNet(1);
            
            % Sulphur
            if isfield(S,'S')
                budgets.totalsulphur=(S.S(end)+S.PYR(end)+S.GYP(end))  -(S.S(1)+S.PYR(1)+S.GYP(1));
            else
                budgets.totalsulphur = NaN;
            end
            
            
            
            fprintf('\ntotal at end - total at start\n');
            fprintf('  carbon  (A + G + C reservoirs)       %e mol\n',budgets.totalcarbon);
            fprintf('  sulphur (S + PYR + GYP reservoirs)   %e mol\n',budgets.totalsulphur);
            fprintf('  redox   (O + C + A + 2*(S+GYP))      %e mol O_2 equiv\n',budgets.totalO2equiv);
            fprintf('  Ca      (C + deltaCaSil)             %e mol\n',budgets.CsilCa);
            fprintf('  Ca      (CAL + GYP + S)              %e mol\n',budgets.CALGYPSCa);
            fprintf('  Ca      (CAL + GYP + C + deltaCaSil) %e mol\n',budgets.totalCa);
            

        end
    end
    
end

