classdef copse_model_bergman2004 < handle
    % Time derivative and diagnostic variables (COPSE 'classic' Bergman etal 2004)
    %
    % Input:
    % tmodel        - model time (yr)
    % S             - state vector  (struct)
    %
    % Output:
    % dSdt          - time derivative of state vector S (struct, fields matching S)
    % D             - diagnostic variables (create D and add fields as needed, these will be accumulated into struct 'diag')
    %
    %%%%%%% COPSE for MATLAB
    %%%%%%% ported by B Mills, 2013
    %%%%%%%
    %%%%%%% updated by S Daines, 2014
    %%%%%%%
    %%%%%%% See also PALEO_examples_COPSE
    
    properties
        pars;              % global model constants
          
        % Set forcing mode for this run        
        forcemode;                  %  Options  'TimeDep', 'SteadyState';
        timeforceSteadyState;       % for SteadyState mode, (constant) time seen by forcings
        
        force;             % cell array of copse_force_xxx instances representing historical forcings.
                           % These are called either with model time, or a fixed time,  depending on the setting of runctrl.forcemode
        perturb;           % cell array of copse_force_xxx instance. These are always called with model time.
     
 
    end
    
    methods
       
        
        function   [dSdt, D ] = timederiv(obj, tmodel, S )  
            % Time derivative and diagnostic variables (monolithic 'copse classic' equations file)
            
            %% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%%%%% CHOOSE FORCING FUNCTIONS
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            switch(obj.forcemode)
                case 'SteadyState'
                    % Disconnect tforce from model time for steady-state with fixed forcing
                    D.tforce = obj.timeforceSteadyState;
                case 'TimeDep'
                    D.tforce = tmodel;
                otherwise
                    error('unknown forcemode %s',obj.forcemode);
            end
            
            % Default (disabled) values for perturbations
            D.CONTAREA          = 1;
            %%% D.RHO additional  enhancement to carbonate/silicate weathering
            D.RHO               = 1;
            %%% F_EPSILON enhances nutrient weathering only
            D.F_EPSILON           = 1;
            %%% Perturbation (injection in mol/yr) to A reservoir
            D.co2pert           = 0;
            D.co2pertmoldelta   = 0;
            
            
            % Iterate through forcing and perturbation functions as defined in config file
            for i = 1:length(obj.force)
                D = obj.force{i}.force( D.tforce - paleo_const.time_present_yr, D ) ;
            end
            for i = 1:length(obj.perturb)
                D = obj.perturb{i}.force( tmodel, D ) ;
            end
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%%%%% END OF FORCING SETUP
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            %% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%%%% CO2 and Temperature
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            D.pO2PAL = (S.O/obj.pars.O0);
            
            %%%%%%%% calculations for pCO2
            D.pCO2PAL = (S.A/obj.pars.A0) ; %pre-industrial = 1
            D.pCO2atm = D.pCO2PAL*obj.pars.pCO2atm0;   % pre-industrial = 280e-6
            
            %%%%%%% Iteratively improved temperature estimate
            D.TEMP = copse_temperature(obj.pars, tmodel, D ,S.temp );
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%%%% END CO2 and Temperature
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            %% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%%% land biota
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            D = copse_landbiota_bergman2004(obj.pars, tmodel, S, D, D.TEMP );
            
            %% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%%%%%% calculate weathering
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            %%%% Plant effects on weathering
            
            D.f_preplant = copse_f_T(D.TEMP) * (D.pCO2PAL^0.5) ;
            D.f_plant = copse_f_T(D.TEMP) * ( ( 2*D.pCO2PAL / (1 + D.pCO2PAL) )^0.4 ) ;
            
            D.g_preplant = copse_g_T(D.TEMP) * (D.pCO2PAL^0.5);
            D.g_plant = copse_g_T(D.TEMP) * ( ( 2*D.pCO2PAL / (1 + D.pCO2PAL) )^0.4 ) ;
            
            D.VWmin = min(D.VEG*D.W,1);
            
            D.f_co2 = D.f_preplant*(1 - D.VWmin) + D.f_plant*D.VWmin ;
            D.g_co2 = D.g_preplant*(1 - D.VWmin) + D.g_plant*D.VWmin ;
            
            D.w_plantenhance = (  obj.pars.k15_plantenhance  + (1-obj.pars.k15_plantenhance)*D.W*D.VEG  );
            
            %%% silicate and carbonate weathering
            D.silw = obj.pars.k_silw*D.CONTAREA*D.UPLIFT*D.RHO* D.w_plantenhance *D.f_co2 ;
            D.carbw_fac = D.CONTAREA*D.UPLIFT*D.RHO*D.w_plantenhance*D.g_co2 ;
            switch(obj.pars.f_carbwC)
                case 'Cindep'   % Copse 5_14
                    D.carbw = obj.pars.k14_carbw*D.carbw_fac;
                case 'Cprop'    % A generalization for varying-size C reservoir
                    D.carbw = obj.pars.k14_carbw*D.carbw_fac*(S.C/obj.pars.C0);
                otherwise
                    error('Unknown f_carbw %s',obj.pars.f_carbw);
            end
            
            %%%% Oxidative weathering
            % Functional form of oxidative weathering
            switch(obj.pars.f_oxwO)
                case 'PowerO2'   % Copse 5_14 base with f_oxw_a = 0.5
                    D.oxw_fac = (S.O/obj.pars.O0)^obj.pars.f_oxw_a;
                case 'SatO2'
                    D.oxw_fac = (S.O/obj.pars.O0)/((S.O/obj.pars.O0) + obj.pars.f_oxw_halfsat);
                otherwise
                    error('Unknown f_foxwO %s',obj.pars.f_oxwO);
            end
            
            % C oxidative weathering
            D.oxidw = obj.pars.k17_oxidw*D.CONTAREA*D.UPLIFT*(S.G/obj.pars.G0)*D.oxw_fac ;
            
            % Sulphur weathering
            switch(obj.pars.Scycle)
                case 'Enabled'
                    % Gypsum weathering tied to carbonate weathering
                    D.gypw = obj.pars.k22_gypw*(S.GYP/obj.pars.GYP0)*D.carbw_fac ;
                    % Pyrite oxidative weathering with same functional form as carbon
                    D.pyrw = obj.pars.k21_pyrw*D.CONTAREA*D.UPLIFT*(S.PYR/obj.pars.PYR0)*D.oxw_fac  ;
                case 'None'
                    D.gypw = 0;
                    D.pyrw = 0;
                otherwise
                    error('unrecogized obj.pars.Scycle %s',obj.pars.Scycle);
            end
            
            
            %%%%%%% P weathering and delivery to land and sea
            D.phosw_s = D.F_EPSILON*obj.pars.k10_phosw*(2/12)*(D.silw/obj.pars.k_silw) ;
            D.phosw_c = D.F_EPSILON*obj.pars.k10_phosw*(5/12)*(D.carbw/obj.pars.k14_carbw);
            D.phosw_o = D.F_EPSILON*obj.pars.k10_phosw*(5/12)*(D.oxidw/obj.pars.k17_oxidw)  ;
            D.phosw   = D.phosw_s + D.phosw_c + D.phosw_o;
            
            D.pland = obj.pars.k11_landfrac*D.VEG*D.phosw ;
            pland0 = obj.pars.k11_landfrac*obj.pars.k10_phosw;
            
            D.psea = D.phosw - D.pland ;
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%%%%%% END calculate weathering
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            %% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%%%%%% calculate degassing
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            % Inorganic carbon
            D.ccdeg     = obj.pars.k12_ccdeg*D.DEGASS*(S.C/obj.pars.C0)*D.Bforcing ;
            
            % Organic carbon
            switch obj.pars.f_ocdeg
                case 'O2indep'
                    D.ocdeg     = obj.pars.k13_ocdeg*D.DEGASS*(S.G/obj.pars.G0) ;
                case 'O2copsecrashprevent'
                    % COPSE 5_14 does this (always) apparently to prevent pO2 dropping to zero ?
                    % This has a big effect when pO2 dependence of oxidative weathering switched off
                    D.ocdeg     = obj.pars.k13_ocdeg*D.DEGASS*(S.G/obj.pars.G0)*copse_crash(S.O/obj.pars.O0,'ocdeg',tmodel);
                otherwise
                    error('unrecogized obj.pars.f_ocdeg %s',obj.pars.Scycle);
            end
            
            % Sulphur
            switch(obj.pars.Scycle)
                case 'Enabled'
                    D.pyrdeg    = obj.pars.k_pyrdeg*(S.PYR/obj.pars.PYR0)*D.DEGASS;
                    D.gypdeg    = obj.pars.k_gypdeg*(S.GYP/obj.pars.GYP0)*D.DEGASS;
                case 'None'
                    D.pyrdeg    = 0;
                    D.gypdeg    = 0;
                otherwise
                    error('unrecogized obj.pars.Scycle %s',obj.pars.Scycle);
            end
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%%%%%% END calculate degassing
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            %% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%%%%% Marine biota
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            D = copse_marinebiota_bergman2004(obj.pars, tmodel, S, D );
            
            %% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%%%%% Burial
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            %%%%% Oxidised C species burial
            D.mccb = D.carbw + D.silw ;   % disguised alkalinity balance
            
            %%%%% Reduced C species burial
            % Marine organic carbon burial
            D.mocb = obj.pars.k2_mocb*((D.newp/obj.pars.newp0)^obj.pars.f_mocb_b) ;
            % Land organic carbon burial
            D.locb = obj.pars.k5_locb*(D.pland/pland0)*D.CPland_relative ;
            
            % Marine organic P burial
            D.mopb = ( D.mocb/D.CPsea ) ;
            % Marine carbonate-associated P burial
            D.capb = obj.pars.k7_capb*( (D.newp/obj.pars.newp0)^obj.pars.f_mocb_b );
            % Marine Fe-sorbed P burial NB: COPSE 5_14 uses copse_crash to limit at low P
            D.fepb = (obj.pars.k6_fepb/obj.pars.k1_oxfrac)*(1-D.ANOX)*copse_crash(S.P/obj.pars.P0,'fepb',tmodel) ;
            
            % Marine organic nitrogen burial
            D.monb = D.mocb/obj.pars.CNsea0 ;
            
            % Marine sulphur burial
            switch(obj.pars.Scycle)
                case 'Enabled'
                    % Marine gypsum sulphur burial
                    D.mgsb = obj.pars.k_mgsb*(S.S/obj.pars.S0)*(S.CAL/obj.pars.CAL0) ;
                    % Marine pyrite sulphur burial
                    switch(obj.pars.f_pyrburial)
                        case 'copse_noO2'    % dependent on sulphate and marine carbon burial
                            D.mpsb = obj.pars.k_mpsb*(S.S/obj.pars.S0)*(D.mocb/obj.pars.k2_mocb) ;
                        case 'copse_O2' % dependent on oxygen, sulphate, and marine carbon burial
                            D.mpsb = obj.pars.k_mpsb*(S.S/obj.pars.S0)/(S.O/obj.pars.O0)*(D.mocb/obj.pars.k2_mocb) ;
                        otherwise
                            error('unknown f_pyrburial %s',obj.pars.f_pyrburial);
                    end
                case 'None'
                    D.mgsb = 0;
                    D.mpsb = 0;
                otherwise
                    error('unrecogized obj.pars.Scycle %s',obj.pars.Scycle);
            end
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%%%%% END Burial
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            %% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%%%%% Update state variables / reservoirs
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            %%% Iterated temperature
            dSdt.temp = D.TEMP - S.temp ;
            
            %%%% Atmosphere / ocean reservoirs
            
            %%% Oxygen
            if obj.pars.o2fix == 1
                dSdt.O=0;
            else
                dSdt.O = D.locb + D.mocb - D.oxidw - D.ocdeg + (2)*(D.mpsb - D.pyrw - D.pyrdeg) ;
            end
            
            %%% Carbon 
            dSdt.A = -D.locb -D.mocb + D.oxidw + D.ocdeg + D.ccdeg + D.carbw - D.mccb + D.co2pert ;
            % dSdt.A=0;
            
            % Marine nutrient reserviors
            dSdt.P = D.psea - D.mopb - D.capb - D.fepb ;
            dSdt.N = D.nfix - D.denit - D.monb;
            
            %%% Marine calcium
            dSdt.CAL = D.silw + D.carbw + D.gypw - D.mccb -D.mgsb;
            
            %%%% Crustal C reservoirs
            %%%Buried organic C
            dSdt.G = D.locb + D.mocb -D.oxidw -D.ocdeg ;
            
            %%% Buried carb C
            dSdt.C = D.mccb - D.carbw - D.ccdeg ;
            
            %%%%%%% C isotope fractionation
            
            % Carbon isotope fractionation (relative to total CO2 (A reservoir)
            switch(obj.pars.f_cisotopefrac)
                case 'fixed'
                    D.d_mocb = -30;
                    D.d_locb = -30;
                    D.d_mccb = 0;
                case 'copse_base'
                    [ D.d_locb, D_P, D.d_mocb, D_B, D.d_mccb, d_ocean, d_atmos ] = copse_Cisotopefrac( D.TEMP, D.pCO2PAL, S.O/obj.pars.O0 );
                case 'copse_noO2'
                    [ D.d_locb, D_P, D.d_mocb, D_B, D.d_mccb, d_ocean, d_atmos ] = copse_Cisotopefrac( D.TEMP, D.pCO2PAL, 1 );
                otherwise
                    error('unknown f_cisotopefrac %s',obj.pars.f_cisotopefrac);
            end
            
            
            %%%%%%% calculate isotopic fractionation of reservoirs
            
            D.delta_G     = S.moldelta_G/S.G;
            D.delta_C     = S.moldelta_C/S.C;
            D.delta_A     = S.moldelta_A/S.A ;
            
            % isotopic fractionation of mccb
            D.delta_mccb = D.delta_A + D.d_mccb;
            
            % deltaORG_C*ORG_C
            dSdt.moldelta_G =  D.mocb*( D.delta_A + D.d_mocb ) +  D.locb*( D.delta_A + D.d_locb ) ...
                                -   D.oxidw*D.delta_G     -   D.ocdeg*D.delta_G      ;
            
            % deltaCARB_C*CARB_C
            dSdt.moldelta_C =  D.mccb*D.delta_mccb   -  D.carbw*D.delta_C  -   D.ccdeg*D.delta_C        ;
            
            %%% delta_A * A
            dSdt.moldelta_A = -D.locb*( D.delta_A + D.d_locb ) -D.mocb*( D.delta_A + D.d_mocb ) ...
                              + D.oxidw*D.delta_G + D.ocdeg*D.delta_G + D.ccdeg*D.delta_C ...
                              + D.carbw*D.delta_C - D.mccb*D.delta_mccb  + D.co2pertmoldelta ;
            
            
            % Sulphur
            switch(obj.pars.Scycle)
                case 'Enabled'
                    %%% Marine sulphate
                    dSdt.S = D.gypw + D.pyrw -D.mgsb - D.mpsb +D.gypdeg + D.pyrdeg ;
                    % dSdt.S=0;
                    %%% Buried pyrite S
                    dSdt.PYR = D.mpsb - D.pyrw - D.pyrdeg ;
                    %%% Buried gypsum S
                    dSdt.GYP = D.mgsb - D.gypw -D.gypdeg ;
                    
                    %Isotopes
                    
                    %Pyrite sulphur isotope fractionation relative to sulphate and gypsum
                    switch(obj.pars.f_sisotopefrac)
                        case 'fixed'
                            D.D_mpsb = 35;
                        case 'copse_O2'
                            D.D_mpsb = 35*(S.O/obj.pars.O0);
                        otherwise
                            error('unknown f_sisotopefrac %s',obj.pars.f_sisotopefrac);
                    end
                    
                    D.delta_GYP   = S.moldelta_GYP/S.GYP;
                    D.delta_PYR   = S.moldelta_PYR/S.PYR;
                    D.delta_S     = S.moldelta_S/S.S;
                    % deltaPYR_S*PYR_S
                    dSdt.moldelta_PYR =  D.mpsb*( D.delta_S - D.D_mpsb ) - D.pyrw*D.delta_PYR   - D.pyrdeg*D.delta_PYR ;
                    % deltaGYP_S*GYP_S
                    dSdt.moldelta_GYP =  D.mgsb*D.delta_S   - D.gypw*D.delta_GYP      - D.gypdeg*D.delta_GYP  ;
                    %%% delta_S * S
                    dSdt.moldelta_S = D.gypw*D.delta_GYP + D.pyrw*D.delta_PYR - D.mgsb*D.delta_S -D.mpsb*(D.delta_S - D.D_mpsb ) +D.gypdeg*D.delta_GYP + D.pyrdeg*D.delta_PYR ;
                    
                case 'None'
                otherwise
                    error('unrecognized obj.pars.Scycle %s',obj.pars.Scycle);
            end
            
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%%%%% END update reservoirs
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%%%%% END COPSE_equations
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        end
        
        
        function   Sinit     = initialise(obj)
            %% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%%%%% Initialise reservoir (state variable) sizes etc
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            %LN = 'copse_model_bergman2004.initialise'; L = paleo_log.getLogger('copse_model'); 
             
            Sinit = struct; 
            
            Sinit.P             = obj.pars.Pinit;
            Sinit.O             = obj.pars.Oinit;
            Sinit.A             = obj.pars.Ainit;
            Sinit.G             = obj.pars.Ginit;
            Sinit.C             = obj.pars.Cinit;
            Sinit.CAL           = obj.pars.CALinit;
            Sinit.N             = obj.pars.Ninit;
            
            %Initialise C isotope reservoirs
            Sinit.moldelta_G    = Sinit.G*obj.pars.delta_Ginit;
            Sinit.moldelta_C    = Sinit.C*obj.pars.delta_Cinit;
            Sinit.moldelta_A    = Sinit.A*obj.pars.delta_Ainit;
            
            %Initialise S cycle if required
            switch obj.pars.Scycle
                case 'Enabled'
                    Sinit.S             = obj.pars.Sinit;
                    Sinit.PYR           = obj.pars.PYRinit;
                    Sinit.GYP           = obj.pars.GYPinit;
                    Sinit.moldelta_PYR  = Sinit.PYR*obj.pars.delta_PYRinit;
                    Sinit.moldelta_GYP  = Sinit.GYP*obj.pars.delta_GYPinit;
                    Sinit.moldelta_S    = Sinit.S*obj.pars.delta_Sinit;
                case 'None'
                    % no S reservoirs
                otherwise
                    error('unrecognized obj.pars.Scycle %s',obj.pars.Scycle);
            end
            
            % Initialise temperature
            Sinit.temp          = paleo_const.k_CtoK+15;
            
        end
        
        
    end
    
end

