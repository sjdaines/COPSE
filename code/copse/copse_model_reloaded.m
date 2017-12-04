classdef copse_model_reloaded < handle
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%% COPSE for MATLAB (Reloaded)
    %%%%%%% ported by B Mills, 2013
    %%%%%%%
    %%%%%%% updated by S Daines, 2014
    %%%%%%%
    %%%%%%% further updated by T Lenton, 2016-7
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    properties
        pars;                   % global model constants
        
        forcemode = 'TimeDep';  % Set forcing mode for this run(options  'TimeDep', 'SteadyState')
        timeforceSteadyState;   % For forcemode='SteadyState', (constant) time seen by forcings
        
        force;                  % Cell array of copse_force_xxx instances representing historical forcings.
                                % (these are called either with model time, or a fixed time,  depending on the setting of runctrl.forcemode)

        perturb;                % Cell array of copse_force_xxx instances (these are always called with model time).
        
    end
    
    methods
        
        function   [dSdt, D] = timederiv(obj, tmodel, S)  
            % Time derivative and diagnostic variables (COPSE reloaded equations)
            %
            % Args:
            %   tmodel (float): (yr) model time
            %   S (struct):     state vector
            %
            % Returns:
            %   dSdt (struct):  time derivative of state vector S (struct, fields matching S)
            %   D (struct):     diagnostic variables (create D and add fields as needed, these will be accumulated into struct 'diag')
            %
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%%%%% CHOOSE FORCING FUNCTIONS
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            switch(obj.forcemode)
                case 'SteadyState'
                    % Disconnect tforce from model time for steady-state with fixed forcing
                    D.tforce = obj.timeforceSteadyState;
                case 'TimeDep'
                    % Usual forward-model case
                    D.tforce = tmodel;
                otherwise
                    error('unknown forcemode %s',obj.forcemode);
            end
                        
            % Default (disabled) values for forcings / perturbations.
            % These are (re)set by forcing functions, if in use.
            % NB: many forcings have no default and are not set here.
            %
            % D.RHO additional enhancement to carbonate/silicate weathering
            D.RHO                       = 1;
            % D.RHOSFW additional enhancement to seafloor weathering
            D.RHOSFW                    = 1;
            % F_EPSILON enhances nutrient weathering only
            D.F_EPSILON                   = 1;
            % PG paleogeog weathering factor
            D.PG                        = 1;
            % Basalt area relative to present day
            D.BA                        = 1;
            % Land temperature adjustment
            D.GEOG                      = 0;
            % Granite area relative to present day
            D.GRAN_AREA = 1;
            % Carbonate area relative to present day
            D.CARB_AREA                 = 1;
            % Total land area relative to present day
            D.TOTAL_AREA                = 1;
            % C/P land multiplier
            D.CPland_relative           = 1;
            % P to land multiplier
            D.Ptoland                   = 1;
            % Coal depositional area multiplier
            D.COAL                      = 1;
            % Evaporite exposed area relative to present day
            D.EVAP_AREA                 = 1;
            % Evaporite depositional area multiplier
            D.SALT                      = 1;
            % Shale+coal area relative to present day
            D.ORG_AREA                  = 1;
            % Shale area relative to present day
            D.SHALE_AREA                = 1;
            % Shale+coal+evaporite area relative to present day
            D.ORGEVAP_AREA              = 1;
            % Prescribed calcium concentration - no default
            % D.CAL_NORM                  = 1;
            % LIP area and co2
            D.CFB_area                  = 0;  % no sensible default - if used, supplied by forcing
            D.LIP_CO2                   = 0;
            D.LIP_CO2moldelta           = 0;
            % Perturbation (injection in mol/yr) to A reservoir
            D.co2pert                   = 0;
            D.co2pertmoldelta           = 0;
            % Alteration of fire feedback
            D.fireforcing               = 1;
            
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
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%%%% CO2 and Temperature
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            D.pO2PAL = (S.O/obj.pars.O0);
            
            %%%%%%%% calculations for pCO2
            switch(obj.pars.f_atfrac)
                case 'original'
                    D.pCO2PAL = (S.A/obj.pars.A0) ; %pre-industrial = 1
                    D.phi = 0.01614 ;
                case 'quadratic'
                    D.pCO2PAL = (S.A/obj.pars.A0)^2 ;
                    D.phi = 0.01614*(S.A/obj.pars.A0) ;
                otherwise
                    error('Unknown f_atfrac %s',obj.pars.f_atfrac);
            end
    
            D.pCO2atm = D.pCO2PAL*obj.pars.pCO2atm0;   % pre-industrial = 280e-6

            %%%%%%% Iteratively improved temperature estimate
            D.TEMP = copse_temperature( obj.pars, tmodel, D, S.temp );
            D.GLOBALT = D.TEMP;
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%%%% END CO2 and Temperature
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%%% land biota
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            D = copse_landbiota_reloaded( obj.pars, tmodel, S, D, D.TEMP );
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%%%%%% calculate weathering
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            % calculate relative land surface areas
            D = copse_landsurfaceareas_reloaded( obj.pars, tmodel, S, D );
            
            % define normalisation for convenience, to decouple copse_weathering_  functions so they can be reused for modular version
            D.normG  = S.G/obj.pars.G0;
            D.normC  = S.C/obj.pars.C0;
            switch(obj.pars.Scycle)
                case 'Enabled'
                    D.normPYR  = S.PYR/obj.pars.PYR0;
                    D.normGYP  = S.GYP/obj.pars.GYP0;
                case 'None'
                    D.normPYR    = 1;
                    D.normGYP    = 1;
                otherwise
                    error('unrecogized obj.pars.Scycle %s',obj.pars.Scycle);
            end
                        
            
            D = copse_weathering_rates_reloaded( obj.pars, tmodel, S, D );
             
            D = copse_weathering_fluxes_reloaded( obj.pars, tmodel, S, D );
            
            switch(obj.pars.f_locb)
                case 'original'
                    D.pland = obj.pars.k11_landfrac*D.VEG*D.phosw ;
                case 'Uforced'
                    %Uplift/erosion control of locb
                    D.pland = obj.pars.k11_landfrac*D.UPLIFT*D.VEG*D.phosw ;
                case 'coal'
                    %Coal basin forcing of locb
                    D.pland = obj.pars.k11_landfrac*D.VEG*D.phosw*(obj.pars.k_aq+(1-obj.pars.k_aq)*D.COAL) ;
                case 'split'
                    %Separating aquatic and coal basin components of locb
                    D.pland = obj.pars.k11_landfrac*D.VEG*D.phosw*(obj.pars.k_aq*D.UPLIFT+(1-obj.pars.k_aq)*D.COAL) ;
                otherwise
                    error('unknown f_locb %s',obj.pars.f_locb);
            end
            
            D.psea = D.phosw - D.pland ;
            
            % Seafloor weathering (SD kept this separate so weathering functions just include land surface)
            D = copse_weathering_seafloor_reloaded( obj.pars, tmodel, S, D );
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%%%%%% END calculate weathering
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%%%%%% calculate degassing
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            % Inorganic carbon
            switch obj.pars.f_ccdeg
                case 'original'
                    D.ccdeg     = obj.pars.k12_ccdeg*D.DEGASS*(S.C/obj.pars.C0)*D.Bforcing ;
                case 'noB'
                    D.ccdeg     = obj.pars.k12_ccdeg*D.DEGASS*(S.C/obj.pars.C0) ;
                otherwise
                    error('unrecogized obj.pars.f_ccdeg %s',obj.pars.f_ccdeg);
            end
                    
                    
            % Organic carbon
            switch obj.pars.f_ocdeg
                case 'O2indep'
                    D.ocdeg     = obj.pars.k13_ocdeg*D.DEGASS*(S.G/obj.pars.G0) ;
                case 'O2copsecrashprevent'
                    % COPSE 5_14 does this (always) apparently to prevent pO2 dropping to zero ?
                    % This has a big effect when pO2 dependence of oxidative weathering switched off
                    D.ocdeg     = obj.pars.k13_ocdeg*D.DEGASS*(S.G/obj.pars.G0)*copse_crash(S.O/obj.pars.O0,'ocdeg',tmodel);
                otherwise
                    error('unrecogized obj.pars.f_ocdeg %s',obj.pars.f_ocdeg);
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
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%%%%% Marine biota
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            D = copse_marinebiota_reloaded( obj.pars, tmodel, S, D );
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%%%%% Burial
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            %%%%% Reduced C species burial
            % Marine organic carbon burial
            switch(obj.pars.f_mocb)
                case 'original'
                    D.mocb = obj.pars.k2_mocb*((D.newp/obj.pars.newp0)^obj.pars.f_mocb_b) ;
                case 'Uforced'
                    D.mocb = obj.pars.k2_mocb*D.UPLIFT*((D.newp/obj.pars.newp0)^obj.pars.f_mocb_b) ;
                case 'O2dep'
                    D.mocb = obj.pars.k2_mocb*((D.newp/obj.pars.newp0)^obj.pars.f_mocb_b)*2.1276*exp(-0.755*(S.O/obj.pars.O0));
                case 'both'
                    D.mocb = obj.pars.k2_mocb*D.UPLIFT*((D.newp/obj.pars.newp0)^obj.pars.f_mocb_b)*2.1276*exp(-0.755*(S.O/obj.pars.O0));
                otherwise
                    error('unknown f_ocb %s',obj.pars.f_mocb);
            end

            % Land organic carbon burial - uplift control in pland
            D.locb = D.pland*obj.pars.CPland0*D.CPland_relative ;

            % Marine organic P burial
            D.mopb = ( D.mocb/D.CPsea ) ;
            % Marine carbonate-associated P burial
            switch(obj.pars.f_capb)
                case 'original'
                    D.capb = obj.pars.k7_capb*( (D.newp/obj.pars.newp0)^obj.pars.f_mocb_b );
                case 'redox'
                    D.capb = obj.pars.k7_capb*( (D.newp/obj.pars.newp0)^obj.pars.f_mocb_b )*(0.5+0.5*(1-D.ANOX)/obj.pars.k1_oxfrac);
                otherwise
                    error('unknown f_capb %s',obj.pars.f_capb);
            end
            % Marine Fe-sorbed P burial NB: COPSE 5_14 uses copse_crash to limit at low P
            switch(obj.pars.f_fepb)
                case 'original'
                    D.fepb = (obj.pars.k6_fepb/obj.pars.k1_oxfrac)*(1-D.ANOX)*copse_crash(S.P/obj.pars.P0,'fepb',tmodel) ;
                case 'Dforced'
                    D.fepb = D.DEGASS*(obj.pars.k6_fepb/obj.pars.k1_oxfrac)*(1-D.ANOX)*copse_crash(S.P/obj.pars.P0,'fepb',tmodel) ;
                case 'sfw'
                    D.fepb = (D.sfw/obj.pars.k_sfw)*(obj.pars.k6_fepb/obj.pars.k1_oxfrac)*(1-D.ANOX)*copse_crash(S.P/obj.pars.P0,'fepb',tmodel) ;
                case 'pdep'
                    D.fepb = (obj.pars.k6_fepb/obj.pars.k1_oxfrac)*(1-D.ANOX)*(S.P/obj.pars.P0) ;
                otherwise
                    error('unknown f_fepb %s',obj.pars.f_fepb);
            end
            % Marine organic nitrogen burial
            D.monb = D.mocb/obj.pars.CNsea0 ;
            
            % Marine sulphur burial
            switch(obj.pars.Scycle)
                case 'Enabled'
                    % Marine gypsum sulphur burial
                    switch(obj.pars.f_gypburial)
                        case 'original' % dependent on sulphate and [Ca]
                            D.mgsb = obj.pars.k_mgsb*(S.S/obj.pars.S0)*(S.CAL/obj.pars.CAL0) ;
                        case 'Caforced' % dependent on sulphate and prescribed [Ca]
                            D.mgsb = obj.pars.k_mgsb*(S.S/obj.pars.S0)*D.CAL_NORM ;
                        otherwise
                            error('unknown f_gypburial %s',obj.pars.f_gypburial);
                    end        
                    % Marine pyrite sulphur burial
                    switch(obj.pars.f_pyrburial)
                        case 'copse_noO2'    % dependent on sulphate and marine carbon burial
                            D.mpsb = obj.pars.k_mpsb*(S.S/obj.pars.S0)*(D.mocb/obj.pars.k2_mocb) ;
                        case 'copse_O2' % dependent on oxygen, sulphate, and marine carbon burial
                            D.mpsb = obj.pars.k_mpsb*(S.S/obj.pars.S0)/(S.O/obj.pars.O0)*(D.mocb/obj.pars.k2_mocb) ;
                        case 'anoxia' % Experiment: dependent on oxygen, sulphate, marine carbon burial and anoxia
                            D.mpsb = obj.pars.k_mpsb*(D.mocb/obj.pars.k2_mocb)*(1+4*D.ANOX)*(S.S/obj.pars.S0)/(S.O/obj.pars.O0) ;
                        otherwise
                            error('unknown f_pyrburial %s',obj.pars.f_pyrburial);
                    end
                case 'None'
                    D.mgsb = 0;
                    D.mpsb = 0;
                otherwise
                    error('unrecogized obj.pars.Scycle %s',obj.pars.Scycle);
            end
            
            %%%% marine carbonate carbon burial from alkalinity balance
            switch obj.pars.f_SRedoxAlk
                case 'on'
                    %%%%% couple pyrite weathering / burial to marine alkalinity balance TODO is this correct Alk vs S ?
                    D.mccb = D.carbw + D.silw + (D.mpsb - D.pyrw) ;
                case 'degassing'
                    %%%%% includes pyrite and gypsum degassing as a source of H2SO4:
                    D.mccb = D.carbw + D.silw + (D.mpsb - D.pyrw - D.pyrdeg - D.gypdeg) ;
                case 'off'
                    %%%%% Oxidised C species burial
                    D.mccb = D.carbw + D.silw ;
                otherwise
                    error('unrecognized f_SRedoxAlk %s', obj.pars.f_SRedoxAlk);
            end
            
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%%%%% END Burial
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%%%%% Update state variables / reservoirs
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            %%%% Iterated temperature
            dSdt.temp = D.TEMP - S.temp ;
            
            %%%% Atmosphere / ocean reservoirs
            
            %%%% Oxygen
            if obj.pars.o2fix == 1
                dSdt.O=0;
            else
                dSdt.O = D.locb + D.mocb - D.oxidw - D.ocdeg + (2)*(D.mpsb - D.pyrw - D.pyrdeg) ;
            end
            
            %%%% Carbon dioxide
            dSdt.A = -D.locb - D.mocb + D.oxidw + D.ocdeg + D.ccdeg - D.mccb + D.carbw - D.sfw + D.LIP_CO2 + D.co2pert ;
            
            %%%% Marine nutrient reserviors
            dSdt.P = D.psea - D.mopb - D.capb - D.fepb ;
            dSdt.N = D.nfix - D.denit - D.monb;
            
            %%%% Marine calcium
            switch(obj.pars.CALcycle)
                case 'Enabled'
                    dSdt.CAL = D.silw + D.carbw + D.gypw - D.mccb -D.mgsb;
                case 'None'
                    % No CAL reservoir
                otherwise
                    error('unrecognized obj.pars.CALcycle %s',obj.pars.CALcycle);
            end
            
            %%%% Crustal C reservoirs
            %%%%  Buried organic C
            dSdt.G = D.locb + D.mocb -D.oxidw -D.ocdeg ;
            
            %%%% Buried carb C
            dSdt.C = D.mccb + D.sfw - D.carbw - D.ccdeg ;
            
            %%%% C isotope fractionation
            
            % Carbon isotope fractionation (relative to total CO2 (A reservoir)
            switch(obj.pars.f_cisotopefrac)
                case 'fixed'
                    D.d_mocb = -30;
                    D.d_locb = -30;
                    D.d_mccb = 0;
                case 'fixed2'  % TL 2016 better values
                    D.d_mocb = -27;
                    D.d_locb = -27;
                    D.d_mccb = 0.5;
                case 'copse_base'
                    [ D.d_locb, D.D_P, D.d_mocb, D.D_B, D.d_mccb, D.d_ocean, D.d_atmos ] = copse_Cisotopefrac( D.TEMP, D.pCO2PAL, S.O/obj.pars.O0, D.phi );
                case 'copse_noO2'
                    [ D.d_locb, D.D_P, D.d_mocb, D.D_B, D.d_mccb, D.d_ocean, D.d_atmos ] = copse_Cisotopefrac( D.TEMP, D.pCO2PAL, 1, D.phi );
                otherwise
                    error('unknown f_cisotopefrac %s',obj.pars.f_cisotopefrac);
            end
            
            
            %%%%%%% calculate isotopic fractionation of reservoirs
            
            D.delta_G     = S.moldelta_G/S.G;
            D.delta_C     = S.moldelta_C/S.C;
            D.delta_A     = S.moldelta_A/S.A ;
            
            % isotopic fractionation of mccb
            D.delta_mccb = D.delta_A + D.d_mccb;
            
            D.d13Cin = (D.oxidw*D.delta_G + D.ocdeg*D.delta_G + D.ccdeg*D.delta_C + D.carbw*D.delta_C)/(D.oxidw + D.ocdeg + D.ccdeg + D.carbw) ;
            D.d13Cout = (D.locb*( D.delta_A + D.d_locb ) + D.mocb*( D.delta_A + D.d_mocb ) + (D.sfw + D.mccb)*D.delta_mccb)/(D.locb + D.mocb + D.mccb + D.sfw) ;
            D.avgfrac = (D.mocb*(D.delta_A+D.d_mocb)+D.locb*(D.delta_A+D.d_locb))/((D.mocb+D.locb)*D.delta_A) ;
            
            % deltaORG_C*ORG_C
            dSdt.moldelta_G =  D.mocb*( D.delta_A + D.d_mocb ) +  D.locb*( D.delta_A + D.d_locb ) -   D.oxidw*D.delta_G     -   D.ocdeg*D.delta_G      ;
            
            % deltaCARB_C*CARB_C
            dSdt.moldelta_C =  (D.mccb + D.sfw)*D.delta_mccb   -  D.carbw*D.delta_C  -   D.ccdeg*D.delta_C        ;
            
            %%% delta_A * A
            dSdt.moldelta_A = -D.locb*( D.delta_A + D.d_locb ) -D.mocb*( D.delta_A + D.d_mocb ) ...
                + D.oxidw*D.delta_G + D.ocdeg*D.delta_G + D.ccdeg*D.delta_C + D.carbw*D.delta_C ...
                - (D.mccb + D.sfw)*D.delta_mccb  + D.LIP_CO2moldelta+ D.co2pertmoldelta ;
            
            
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
            %%%%%%% Strontium system
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            %%%%%%%%%%%%%%%%%%%%%%%% 
            % flux calculations
            %%%%%%%%%%%%%%%%%%%%%%%%            
            
            %%%% ocean inputs
            D.Sr_old_igw = obj.pars.k_Sr_igg * ( D.granw / obj.pars.k_granw ) ;  %%% weathering of old igneous rocks
            D.Sr_new_igw = obj.pars.k_Sr_igb * ( D.basw / obj.pars.k_basw) ; %%% weathering of new igneous rocks
            D.Sr_mantle = obj.pars.k_Sr_mantle * D.DEGASS ;
            
            switch(obj.pars.f_Sr_sedw)
                case 'original'
                    D.Sr_sedw = obj.pars.k_Sr_sedw * ( D.carbw / obj.pars.k14_carbw ) ; %%% carbonate weathering
                case 'alternative'
                    D.Sr_sedw = obj.pars.k_Sr_sedw * ( D.carbw / obj.pars.k14_carbw ) * (S.Sr_sed / obj.pars.Sr_sed0) ; 
                otherwise
                    error('unrecognized f_Sr_sedw %s', obj.pars.f_Sr_sedw);
            end
            
            %%%% Sr outputs to sediments
                       
            Sr_ocean_relative = ( S.Sr_ocean / obj.pars.Sr_ocean0 ) ; %%% assume dependence on Sr conc in ocean
                
            D.Sr_sfw = obj.pars.k_Sr_sfw * ( D.sfw_relative ) * Sr_ocean_relative ; %%% assume dependence on Sr conc in ocean
            D.Sr_sedb = obj.pars.k_Sr_sedb * ( ( D.silw + D.carbw ) / ( obj.pars.k_silw + obj.pars.k14_carbw ) )  * Sr_ocean_relative ; %%% assume dependence on Sr conc in ocean
  
            Sr_sed_relative = (S.Sr_sed / obj.pars.Sr_sed0) ;
            %%%% loss from sediments
            switch(obj.pars.f_Sr_metam)
                 case 'original'
                    D.Sr_metam = obj.pars.k_Sr_metam * D.DEGASS ;
                 case 'alternative'
                    D.Sr_metam = obj.pars.k_Sr_metam * Sr_sed_relative * D.DEGASS ;
                otherwise
                    error('unrecognized f_Sr_metam %s', obj.pars.f_Sr_metam);
            end
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%% ISOTOPE calculations %%%
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            % present day isotope values pars.delta_ defined in .yaml file
             
            %%%% Sr ratios increasing with time due to 87Rb decay
            lambda_Rb = 1.4e-11 ;
            d_Sr_0 = 0.69898 ; %%% value at formation of earth 
            t_present = 4.5e9 ; %%% present time
            %%%%% calculate Rb to Sr ratios at present day value (assume unchanging)
            d_RbSr_old_ig = (obj.pars.delta_old_ig_present - d_Sr_0)/( 1 - exp(-lambda_Rb*t_present) ) ;
            d_RbSr_new_ig = (obj.pars.delta_new_ig_present - d_Sr_0)/( 1 - exp(-lambda_Rb*t_present) ) ;
            d_RbSr_mantle = (obj.pars.delta_mantle_present - d_Sr_0)/( 1 - exp(-lambda_Rb*t_present) ) ;
            
            sediment_rbsr = 0.5 ; %%% present-day inferred from avg crustal value
            
            %%%% for each timestep calculate d_Sr and d_RbSr
            tforwards = 4.5e9 + tmodel ; %%% get old model time from paleo time
            D.delta_old_ig = d_Sr_0  +  d_RbSr_old_ig*( 1 - exp(-lambda_Rb*tforwards) ) ;
            D.delta_new_ig = d_Sr_0  +  d_RbSr_new_ig*( 1 - exp(-lambda_Rb*tforwards) ) ;
            D.delta_mantle = d_Sr_0  +  d_RbSr_mantle*( 1 - exp(-lambda_Rb*tforwards) ) ;
            
            %%% calculate fractionations in ocean and sediment reservoirs
            D.delta_Sr_ocean   = S.moldelta_Sr_ocean/S.Sr_ocean;
             
            % Simplified code for time-evolution of delta_Sr_sed due to Rb decay
            D.delta_Sr_sed   = ( S.moldelta_Sr_sed / S.Sr_sed ); 
            % rate-of-change of moldelta_Sr_sed due to Rb decay
            % (also include a very small secular decrease in Rb abundance for consistency, ~+1.4% at 1 Ga relative to present)
            D.dmoldelta_Sr_sed_dt_Rb = S.Sr_sed*lambda_Rb*sediment_rbsr*exp(lambda_Rb*(t_present - tforwards));
                                   
            %%% calculate igneous river composition for plotting
            D.delta_igw = (D.Sr_old_igw*D.delta_old_ig + D.Sr_new_igw*D.delta_new_ig)/(D.Sr_old_igw+D.Sr_new_igw) ;
            
            %%%%%%%%%%%%%%%%%%%%%%%% 
            % reservoir calculations
            %%%%%%%%%%%%%%%%%%%%%%%%
     
            %%% Ocean Sr
            dSdt.Sr_ocean = D.Sr_old_igw + D.Sr_new_igw + D.Sr_sedw + D.Sr_mantle - D.Sr_sedb - D.Sr_sfw ;
            
            %%% Sediment Sr
            dSdt.Sr_sed = D.Sr_sedb  - D.Sr_sedw - D.Sr_metam  ;
            
            %%% Ocean Sr * frac
            dSdt.moldelta_Sr_ocean = D.Sr_old_igw*D.delta_old_ig  +  D.Sr_new_igw*D.delta_new_ig   +  D.Sr_sedw*D.delta_Sr_sed  + D.Sr_mantle*D.delta_mantle   -  D.Sr_sedb*D.delta_Sr_ocean - D.Sr_sfw*D.delta_Sr_ocean ; 
            
            %%% Sediment Sr * frac
            dSdt.moldelta_Sr_sed = D.Sr_sedb*D.delta_Sr_ocean  -  D.Sr_sedw*D.delta_Sr_sed   -  D.Sr_metam*D.delta_Sr_sed + D.dmoldelta_Sr_sed_dt_Rb;
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%%%%% END strontium system
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%           
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%%%%% END update reservoirs
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%%%%% END timederiv()
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        end
        
        function   Sinit     = initialise(obj)
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%%%%% Initialise reservoir (state variable) sizes etc
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            %LN = 'copse_model_reloaded.initialise'; L = paleo_log.getLogger('copse_model'); 
             
            Sinit = struct;
                        
            Sinit.P             = obj.pars.Pinit;
            Sinit.O             = obj.pars.Oinit;
            Sinit.A             = obj.pars.Ainit;
            Sinit.G             = obj.pars.Ginit;
            Sinit.C             = obj.pars.Cinit;
            
            switch(obj.pars.CALcycle)
                case 'Enabled'
                    Sinit.CAL           = obj.pars.CALinit;
                case 'None'
                    % No CAL reservoir
                otherwise
                    error('unrecognized obj.pars.CALcycle %s',obj.pars.CALcycle);
            end
            
            Sinit.N             = obj.pars.Ninit;
            
            % Initalise Sr
            Sinit.Sr_ocean      = obj.pars.Sr_ocean_init;
            Sinit.Sr_sed        = obj.pars.Sr_sed_init;


            % Initialise C isotope reservoirs
            Sinit.moldelta_G    = Sinit.G*obj.pars.delta_Ginit;
            Sinit.moldelta_C    = Sinit.C*obj.pars.delta_Cinit ;
            Sinit.moldelta_A    = Sinit.A*obj.pars.delta_Ainit;
            
            % Initialise Sr isotope reservoirs
            Sinit.moldelta_Sr_ocean   = Sinit.Sr_ocean * obj.pars.delta_Sr_ocean_start;
            Sinit.moldelta_Sr_sed     = Sinit.Sr_sed *   obj.pars.delta_Sr_sed_start;


            % Initialise S cycle if required
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

