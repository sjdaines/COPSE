function run = copse_millsg3_millsg3_expts(basemodel, expt, comparedata)
% COPSE reloaded experiments 


%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%% run control
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

run             = paleo_run;
run.config = 'copse_millsg3_millsg3_expts';
run.expt = sprintf('%s', expt);
run.baseconfig  = basemodel;
fprintf('Basemodel %s Experiment %s\n',basemodel, expt);

%%%%%%% Set duration for this run
% For historical forcings, run from before present day to present day
run.Tstart           = paleo_const.time_present_yr-250e6; % run for Mesozoic only

% Integrate method
run.integrator = paleo_integrate_ode(250e6);
%%%%%%% Set maximum step size for solver (to avoid omitting short-timescale
%%%%%%% change in forcings)
run.integrator.odeoptions          = odeset(run.integrator.odeoptions, 'maxstep',1e6) ;

%%%%%%% Budget calculations (derived after solution calculated)
run.postprocessors   = copse_budgets_base();

%%%%%%% Plot configuration 
run.analyzers = paleo_plotlist();
run.analyzers.plotters = {@copse_plot_sfbw;@copse_plot_base};


%%%% model does not output necessary fields for WeathFacNorm, so removed from plotlist
run.analyzers.listplots={ 'PhysForc'; 'EvolForc'; 'O2'; 'CO2'; 'Temp'; 'OceanNP'; 'Biota'; 'LandBiota';'FireIgnit';
        'O2';'O2Diff'; 'SIsotopes';'CO2';'CO2Diff';'SIsotopesDiff';'CIsotopes';'CIsotopesDiff';'newpage';
        'CResChange';'SResChange';'RedoxChange';'CaResChange';'newpage';
        'CDegass'; 'CPWeath'; 'PWeath';'WeathFac2';'PBurial'; 'CPBurialratio'; 'orgCBurial';  'FRatio'; 'CIsotopes'; 'CIsotopesIO'; 'CRes'; 'CCrustRes';
        'SDegass'; 'SWeath'; 'SBurial'; 'GYPPYR'; 'SCAL'; 'SIsotopes'; 'SFW'; 'Srconc'; 'Srfluxes'; 'Srfrac'; 'BasaltArea';
        };    
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%% END run control
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Set base model
switch basemodel
   
   
    case 'g3mills2014nobugs'
        % Mills etal (2014) G3 update
        run.tm = paleo_modelbuilder.createModel('COPSE_millsg3_millsg3_cfg.yaml','copse_millsg3_2014');
        
    case 'g3mills2014withbugs'
        % Mills etal (2014) G3 update
        run.tm = paleo_modelbuilder.createModel('COPSE_millsg3_millsg3_cfg.yaml','copse_millsg3_2014');
              
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%% add in bugs to make model match paper runs exactly
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                          
        %%%% implement G3 2014 bug in land biota temp response
        run.tm.pars = copse_modify_struct( run.tm.pars,'f_bug_g32014_landbiotatemp','Yes'); 

        %%%% Replicate Sr system concentration bug from Mills 2014 G3
        run.tm.pars = copse_modify_struct( run.tm.pars, 'f_bug_g32014_Srconc', 'Yes');  

        %%%% Original Granite area calc, not very good
        run.tm.pars = copse_modify_struct( run.tm.pars,'f_granitearea', 'G3original');
        
        %%%% Silicate weathering rates used 288K offset, resulting ~1% difference in pCO2
        run.tm.pars = copse_modify_struct( run.tm.pars, 'f_act_energies', 'split_bug_g32014_Toffset');
      
    otherwise
        error('unknown basemodel %s',basemodel);
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Choose an 'experiment' (a delta to the base model)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

switch expt
    
    case 'baseline'
        % Baseline configuration


        
    %%%% Model experiments related to G-cubed paper (Mills et al. 2014)
        
    case 'sfwalpha'
        % alternate seafloor weathering, with alpha=0 (no CO2 dependence)
        run.tm.pars = copse_modify_struct( run.tm.pars,'k_sfw', 1.75e12 );       
        run.tm.pars = copse_modify_struct( run.tm.pars,'f_sfw_alpha', 0);      
   
    case {'g3revBAavg','g3revBAmin','g3revBAmax'}
        % avg (default) / min / max basalt area forcing
         BAstr = expt(6:end) ;
         % Locate copse_force_revision_ba in the list of forcings
         baforce = copse_find_force( run.tm, 'copse_force_revision_ba', false );
         
         % set property controlling the field from spreadsheet to use
         baforce.estimate = BAstr; 
         
    case {'LipNoCO2';'LipCO2min';'LipCO2max'}
        % Spreadsheet-based LIP forcings
        % Requires g3-based model with basalt area etc
        
        % Locate copse_force_revision_ba in the list of forcings (to be replaced it with spreadsheet-based version)              
        [~, baforceidx] = copse_find_force( run.tm, 'copse_force_revision_ba', false );
        
        % Locate degass forcing (needed for normalisation check as this supplies oib_area)
        [vandforce, ~] = copse_find_force( run.tm, 'copse_force_vandermeer', false);
                               
        LIPstr = expt(4:end) ;
        % Add LIB basalt area       
        phanlip = copse_load_phanlip('mills2014g3');
        LIPtrange = [-Inf Inf];  % all lips
        smoothempl = false; % true for pre-revision G3, false for revised paper
        present_day_CFB_area = 4.8e6;
        % Create list of LIPs, no CO2
        [flips, default_lambda, ~] = phanlip.create_LIP_forcing(run.Tstart, run.Tstart+run.integrator.timetoadd, ...
                                                LIPstr, present_day_CFB_area, LIPtrange, smoothempl);        
        fprintf('default_lambda = %g yr-1 to match present day CFB area %g km2\n', default_lambda, present_day_CFB_area);        
                     
        fprintf('replacing copse_force_revision_ba forcing with spreadsheet-based LIP forcing\n');        
        run.tm.force{baforceidx} = flips;
        
        % evaluate the new forcing functions at present day to get present-day basalt area
        D.CFB_area = 0;
        D.LIP_CO2 = 0;
        D.LIP_CO2moldelta = 0;
        D.oib_area = 0;        
        D = vandforce.force(paleo_const.time_present_yr, D);
        D = flips.force(paleo_const.time_present_yr, D);
        
        fprintf('updating run.tm.pars.k_present_basalt_area old %g\n',run.tm.pars.k_present_basalt_area);
        run.tm.pars = copse_modify_struct(run.tm.pars, 'k_present_basalt_area', D.CFB_area + D.oib_area);
        fprintf('                                           new CFB %g + OIB %g = %g\n', ...
          D.CFB_area, D.oib_area, run.tm.pars.k_present_basalt_area);
        
        % Enable basalt area forcing (present-day value for normalisation calculated below)
        run.tm.pars.f_basaltarea   = 'g3_2014_construct_from_lips';
        
        % Add new plots       
        run.analyzers.listplots{end+1} = 'LIPCO2';
        
    case 'weather'
        %try Ben's initialisation for 250 Ma
        run.tm.pars = copse_modify_struct(run.tm.pars, 'Ginit',     run.tm.pars.G0*1.0);
        run.tm.pars = copse_modify_struct(run.tm.pars, 'Cinit',     run.tm.pars.C0*1.0);     
        run.tm.pars = copse_modify_struct(run.tm.pars, 'PYRinit',   run.tm.pars.PYR0*1.1);
        run.tm.pars = copse_modify_struct(run.tm.pars, 'GYPinit',   run.tm.pars.GYP0*0.9);    
        run.tm.pars = copse_modify_struct(run.tm.pars, 'Oinit',     run.tm.pars.O0*1.0);
        run.tm.pars = copse_modify_struct(run.tm.pars, 'Sinit',     run.tm.pars.S0*0.8);
        run.tm.pars = copse_modify_struct(run.tm.pars, 'Ainit',     run.tm.pars.A0*1.0);
        %run.tm.forcemode = 'SteadyState';
        %run.tm.timeforceSteadyState = paleo_const.time_present_yr;
        %run.tm.pars.k15_plantenhance=0.25;
        %run.tm.pars.f_co2fert = 'geocarb3';
        %run.tm.pars = copse_modify_struct(run.tm.pars, 'f_vegweath', 'new');
        run.tm.pars = copse_modify_struct( run.tm.pars,'k_Psilw',0.56); %0.5
        run.tm.pars = copse_modify_struct( run.tm.pars,'k_Pcarbw',0.21); %0.2
        run.tm.pars = copse_modify_struct( run.tm.pars,'k_Poxidw',0.23); %0.3
        %run.tm.pars = copse_modify_struct( run.tm.pars,'f_p_kinetics','yes');
        run.tm.pars = copse_modify_struct( run.tm.pars,'f_p_apportion','yes');
        %also change seafloor weathering
        %run.tm.pars = copse_modify_struct( run.tm.pars,'f_sfw_opt','sfw_Tbotw');
        run.tm.pars = copse_modify_struct( run.tm.pars,'f_sfw_opt','sfw_temp');
        % Experiment strengthening fire feedback in early Cretaceous
        %run.tm.perturb{end+1} = copse_force_ramp('fireforcing', [0 -0.8], [-135e6 -100e6], '+')
        % Similar experiment based on bookchapter formulation
        %run.tm.pars = copse_modify_struct( run.tm.pars,'f_ignit','bookchapter');
        %run.tm.pars = copse_modify_struct( run.tm.pars,'k_fire',20);
        %run.tm.perturb{end+1} = copse_force_ramp('fireforcing', [0 -0.85], [-135e6 -100e6], '+')
        
    %%%% example model perturbation experiment
        
    case 'modernperturb'

        % Forcing perturbations against Modern steady-state
        
        % SteadyState fixes historical forcing at timeforceSteadyState
        run.tm.forcemode = 'SteadyState';
        run.tm.timeforceSteadyState = paleo_const.time_present_yr;
        
        % Add perturbations to forcing
        run.tm.perturb{end+1} = copse_force_examples;
        %                       copse_force_co2pulse(size, duration, tstart,d13C)
        run.tm.perturb{end+1} = copse_force_co2pulse(3e18, 10e3,600000e3,-30) ;
        
        %%%%%%% Set duration for this run
        
        % For eg perturbation experiments that don't use historical forcings, can start from zero for convenience
        run.Tstart             = 100e6;
        run.integrator.timetoadd= 550e6;
        
        % Identifiy any discontinuities and force restart with small step size
        %runctrl.timerestarts              = [];
        run.integrator.timerestarts              = [600e6];
        

otherwise
        error('unknown expt %s\n', expt);
end


% optionally plot against proxy data
if nargin >= 3 && comparedata
    run.analyzers.listplots = [run.analyzers.listplots; 
        {'newpage';'datamrO2'; 'datapO2'; 'dataCO2'; 'dataSO4'; 'datad13C'; 'datad34Smov'; 'data8786Sr' } ];
    run.analyzers.plotters = [run.analyzers.plotters; {@copse_plot_data}];
end
    

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%% calculate unknowns assuming present day steady state
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% S burial to balance S weathering + S degassing
run.tm.pars.k_mpsb = run.tm.pars.k21_pyrw + run.tm.pars.k_pyrdeg ;
run.tm.pars.k_mgsb = run.tm.pars.k22_gypw + run.tm.pars.k_gypdeg ;
% oxidw to balance degassing and carbon burial
run.tm.pars.k17_oxidw      = run.tm.pars.k2_mocb + run.tm.pars.k5_locb -run.tm.pars.k13_ocdeg  ;
% silicate weathering to balance degassing +/- organic C cycle
run.tm.pars.k_silw         = run.tm.pars.k17_oxidw - (run.tm.pars.k2_mocb + run.tm.pars.k5_locb - run.tm.pars.k13_ocdeg) + run.tm.pars.k12_ccdeg - run.tm.pars.k_sfw ;
% SD include sulphur degassing (for 'f_SRedoxAlk' == 'degassing')
%run.tm.pars.k_silw         = run.tm.pars.k17_oxidw - (run.tm.pars.k2_mocb + run.tm.pars.k5_locb - run.tm.pars.k13_ocdeg) + run.tm.pars.k12_ccdeg - run.tm.pars.k_sfw + (run.tm.pars.k_pyrdeg + run.tm.pars.k_gypdeg) ;
run.tm.pars.k_granw = run.tm.pars.k_silw*(1-run.tm.pars.k_basfrac);
run.tm.pars.k_basw = run.tm.pars.k_silw*(run.tm.pars.k_basfrac);
% P weathering to balance P burial
%run.tm.pars.k10_phosw      = ( run.tm.pars.k2_mocb/run.tm.pars.CPsea0  +run.tm.pars.k7_capb +run.tm.pars.k6_fepb )  / (1-run.tm.pars.k11_landfrac) ;
%TL alternative approach to avoid redundancy and derive k11
run.tm.pars.k10_phosw      = ( run.tm.pars.k2_mocb/run.tm.pars.CPsea0  +run.tm.pars.k7_capb +run.tm.pars.k6_fepb )  + (run.tm.pars.k5_locb/run.tm.pars.CPland0) ;
run.tm.pars.k11_landfrac   = (run.tm.pars.k5_locb/run.tm.pars.CPland0)/run.tm.pars.k10_phosw ;
% N fixation to balance denit + monb
run.tm.pars.k3_nfix = 2*run.tm.pars.k4_denit + run.tm.pars.k2_mocb/run.tm.pars.CNsea0;

%%% Make sure Sr fluxes follow basfrac apportioning
run.tm.pars.k_Sr_igg = run.tm.pars.k_Sr_total_igw * (1 - run.tm.pars.k_basfrac);
run.tm.pars.k_Sr_igb = run.tm.pars.k_Sr_total_igw * run.tm.pars.k_basfrac;
%%%% calculate unknowns for Sr system
run.tm.pars.k_Sr_total_burial = run.tm.pars.k_Sr_sedw + run.tm.pars.k_Sr_mantle + run.tm.pars.k_Sr_total_igw ; %%%% sum for total burial
%%% assume same fraction of Sr is buried by sfw as carbonates
run.tm.pars.k_Sr_sfw = run.tm.pars.k_Sr_total_burial * (  run.tm.pars.k_sfw / ( run.tm.pars.k14_carbw + run.tm.pars.k_silw + run.tm.pars.k_sfw)  ) ;
%%% aternative set sfw to equal mantle input (Francois and Walker 1992)
%run.tm.pars.k_Sr_sfw = run.tm.pars.k_Sr_mantle ;
%%% calculate sed burial of Sr for stability
run.tm.pars.k_Sr_sedb = run.tm.pars.k_Sr_total_burial - run.tm.pars.k_Sr_sfw ; 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%% Set run.tm.Tstart %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

run.tm.Tstart = run.Tstart ;



end
