function run = copse_reloaded_bergman2004_expts(basemodel, expt, comparedata)
% COPSE reloaded experiments 


%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%% run control
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

run             = paleo_run;
run.config = 'copse_reloaded_bergman2004_expts';
run.expt = sprintf('%s',expt);
run.baseconfig  = basemodel;
fprintf('Basemodel %s Experiment %s\n',basemodel, expt);

%%%%%%% Set duration for this run
% For historical forcings, run from before present day to present day
run.Tstart           = paleo_const.time_present_yr-600e6; % for COPSE historical forcings

% Integrate method
run.integrator = paleo_integrate_ode(600e6);
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
        'SDegass'; 'SWeath'; 'SBurial'; 'GYPPYR'; 'SCAL'; 'SIsotopes'; 'SFW'; 'Srconc'; 'Srfluxes'; 'Srfrac';
        };    
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%% END run control
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Set base model
switch basemodel
        

    case 'bergman2004'
        %%%% this is a reconstruction of the Bergman (2004) AJS COPSE original model
        %%%% run for Phanerozoic to reproduce Bergman et al 2004 results
        run.Tstart                  = paleo_const.time_present_yr-600e6; 
        run.integrator.timetoadd = 600e6 ; 
        
        % Lenton et al 'COPSE reloaded' 
        run.tm = paleo_modelbuilder.createModel('COPSE_reloaded_bergman2004_cfg.yaml','copse5_14_base');
    
    otherwise
        error('unknown basemodel %s',basemodel);
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Choose an 'experiment' (a delta to the base model)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

switch expt
    
    case 'baseline'
        % Baseline configuration    

    %%%% Experiments in Bergman et al. (2004)
        
    case 'run2'
        % Marine CP ratio depends on anoxia
        run.tm.pars = copse_modify_struct( run.tm.pars, 'f_CPsea', 'VCI' );

    case 'run3'
        % Oxidative weathering not dependent on O2
        run.tm.pars = copse_modify_struct( run.tm.pars,'f_oxwO','SatO2');
        run.tm.pars.f_oxw_halfsat = 1e-6;   % not defined in base configuration
        
        %Bergman (2004) uses this, which limits fall of pO2 prior to Ordovician
        %run.tm.pars = copse_modify_struct( run.tm.pars,'f_ocdeg','O2copsecrashprevent');
        
    case 'run6'
        % strong fire feedback
        run.tm.pars = copse_modify_struct( run.tm.pars,'k_fire',20);
        
    case 'run7'
        % no fire feedback,
        run.tm.pars = copse_modify_struct( run.tm.pars,'k_fire',1e10);       %to effectively switch off fire feedback
        
    case 'run8'
        % Pyrite burial not dependent on oxygen      
        run.tm.pars = copse_modify_struct( run.tm.pars,'f_pyrburial','copse_noO2');
        
    case 'run9'
        % no S cycle
        run.tm.pars = copse_modify_struct( run.tm.pars,'Scycle','None');
        
    case 'run11'
        % C isotope fractionation independent of oxygen    
        run.tm.pars = copse_modify_struct( run.tm.pars,'f_cisotopefrac','copse_noO2');
        
    case 'run12'
        % S isotope fractionation dependent on oxygen
        if ~isfield(run.tm.pars,'f_sisotopefrac'); error 'no parameter'; end;
        run.tm.pars = copse_modify_struct( run.tm.pars,'f_sisotopefrac','copse_O2');
        
    case 'run3VCI'
        % Oxidative weathering not dependent on O2
        % Marine CP ratio depends on anoxia        
        run.tm.pars = copse_modify_struct( run.tm.pars, 'f_CPsea', 'VCI' );
        run.tm.pars = copse_modify_struct( run.tm.pars,'f_oxwO','SatO2');
        run.tm.pars.f_oxw_halfsat = 1e-6;   % not defined in base configuration        
        %Bergman (2004) uses the following, which limits fall of pO2 prior to Ordovician
        %run.tm.pars = copse_modify_struct( run.tm.pars,'f_ocdeg','O2copsecrashprevent');
        
    %%%% Subsequent papers that are simple variants of original COPSE
        
    case 'bookchapter'
        % Book chapter for Claire (Lenton, 2013)
        run.tm.pars = copse_modify_struct( run.tm.pars,'f_ignit','bookchapter');
        run.tm.pars = copse_modify_struct( run.tm.pars,'k_fire',3);

    case 'ordovician'
        % Ordovician model as in Lenton et al. (2012) [without smoothing geologic forcing]
        run.tm.pars = copse_modify_struct( run.tm.pars, 'f_atfrac', 'quadratic' );
        run.tm.perturb{end+1} = copse_force_ramp('F_EPSILON', [0 1], [-460e6 -458e6], '+') ;
        run.tm.perturb{end+1} = copse_force_ramp('F_EPSILON', [0 -1], [-458e6 -456e6], '+') ;
        run.tm.perturb{end+1} = copse_force_ramp('F_EPSILON', [0 2], [-447e6 -445e6], '+') ;
        run.tm.perturb{end+1} = copse_force_ramp('F_EPSILON', [0 -2], [-445e6 -443e6], '+') ;
        run.tm.perturb{end+1} = copse_force_ramp('EVO', [0 0.15], [-475e6 -460e6], '=') ;
        run.tm.perturb{end+1} = copse_force_ramp('EVO', [0 0.1], [-400e6 -380e6], '+') ;
        run.tm.perturb{end+1} = copse_force_ramp('EVO', [0 0.5], [-380e6 -330e6], '+') ;
        run.tm.perturb{end+1} = copse_force_ramp('EVO', [0 0.25], [-330e6 -300e6], '+') ;
        run.tm.perturb{end+1} = copse_force_ramp('W', [0 0.75], [-475e6 -460e6], '=') ;
        run.tm.perturb{end+1} = copse_force_ramp('W', [0 0.25], [-115e6 -100e6], '+') ;
       
    case 'paleozoic_base'
        % Paleozoic model as in Lenton et al. (2016) - baseline
        run.tm.pars = copse_modify_struct( run.tm.pars, 'f_atfrac', 'quadratic' );
    case 'paleozoic_blue'
        % Paleozoic model as in Lenton et al. (2016) - blue run
        run.tm.pars = copse_modify_struct( run.tm.pars, 'f_atfrac', 'quadratic' );
        %Paleozoic paper forcing of E
        run.tm.perturb{end+1} = copse_force_ramp('EVO', [0 0.15], [-465e6 -445e6], '=') ;
        run.tm.perturb{end+1} = copse_force_ramp('EVO', [0 0.1], [-400e6 -380e6], '+') ;
        run.tm.perturb{end+1} = copse_force_ramp('EVO', [0 0.5], [-380e6 -330e6], '+') ;
        run.tm.perturb{end+1} = copse_force_ramp('EVO', [0 0.25], [-330e6 -300e6], '+') ;
    case 'paleozoic_cyan'
        % Paleozoic model as in Lenton et al. (2016) - cyan run
        run.tm.pars = copse_modify_struct( run.tm.pars, 'f_atfrac', 'quadratic' );
        %Paleozoic paper forcing of E
        run.tm.perturb{end+1} = copse_force_ramp('EVO', [0 0.15], [-465e6 -445e6], '=') ;
        run.tm.perturb{end+1} = copse_force_ramp('EVO', [0 0.1], [-400e6 -380e6], '+') ;
        run.tm.perturb{end+1} = copse_force_ramp('EVO', [0 0.5], [-380e6 -330e6], '+') ;
        run.tm.perturb{end+1} = copse_force_ramp('EVO', [0 0.25], [-330e6 -300e6], '+') ;
        %Paleozoic forcing of C/P land
        run.tm.perturb{end+1} = copse_force_ramp('CPland_relative', [0 1], [-465e6 -445e6], '+') ;
        run.tm.perturb{end+1} = copse_force_ramp('CPland_relative', [0 -1], [-355e6 -345e6], '+') ;
    case 'paleozoic_magenta'
        % Paleozoic model as in Lenton et al. (2016) - magenta run
        run.tm.pars = copse_modify_struct( run.tm.pars, 'f_atfrac', 'quadratic' );
        %Paleozoic paper forcing of E
        run.tm.perturb{end+1} = copse_force_ramp('EVO', [0 0.15], [-465e6 -445e6], '=') ;
        run.tm.perturb{end+1} = copse_force_ramp('EVO', [0 0.1], [-400e6 -380e6], '+') ;
        run.tm.perturb{end+1} = copse_force_ramp('EVO', [0 0.5], [-380e6 -330e6], '+') ;
        run.tm.perturb{end+1} = copse_force_ramp('EVO', [0 0.25], [-330e6 -300e6], '+') ;
        %Paleozoic paper forcing of W
        run.tm.perturb{end+1} = copse_force_ramp('W', [0 0.75], [-465e6 -445e6], '=') ;
        run.tm.perturb{end+1} = copse_force_ramp('W', [0 0.25], [-115e6 -100e6], '+') ;
    case 'paleozoic_green'
        % Paleozoic model as in Lenton et al. (2016) - green run
        run.tm.pars = copse_modify_struct( run.tm.pars, 'f_atfrac', 'quadratic' );
        %Paleozoic paper forcing of E
        run.tm.perturb{end+1} = copse_force_ramp('EVO', [0 0.15], [-465e6 -445e6], '=') ;
        run.tm.perturb{end+1} = copse_force_ramp('EVO', [0 0.1], [-400e6 -380e6], '+') ;
        run.tm.perturb{end+1} = copse_force_ramp('EVO', [0 0.5], [-380e6 -330e6], '+') ;
        run.tm.perturb{end+1} = copse_force_ramp('EVO', [0 0.25], [-330e6 -300e6], '+') ;
        %Paleozoic paper forcing of W
        run.tm.perturb{end+1} = copse_force_ramp('W', [0 0.75], [-465e6 -445e6], '=') ;
        run.tm.perturb{end+1} = copse_force_ramp('W', [0 0.25], [-115e6 -100e6], '+') ;
        %Paleozoic forcing of C/P land
        run.tm.perturb{end+1} = copse_force_ramp('CPland_relative', [0 1], [-465e6 -445e6], '+') ;
        run.tm.perturb{end+1} = copse_force_ramp('CPland_relative', [0 -1], [-355e6 -345e6], '+') ;
    case 'paleozoic_yellow'
        % Paleozoic model as in Lenton et al. (2016) - yellow run
        run.tm.pars = copse_modify_struct( run.tm.pars, 'f_atfrac', 'quadratic' );
        %Paleozoic paper forcing of E
        run.tm.perturb{end+1} = copse_force_ramp('EVO', [0 0.15], [-465e6 -445e6], '=') ;
        run.tm.perturb{end+1} = copse_force_ramp('EVO', [0 0.1], [-400e6 -380e6], '+') ;
        run.tm.perturb{end+1} = copse_force_ramp('EVO', [0 0.5], [-380e6 -330e6], '+') ;
        run.tm.perturb{end+1} = copse_force_ramp('EVO', [0 0.25], [-330e6 -300e6], '+') ;
        %Paleozoic paper forcing of W
        run.tm.perturb{end+1} = copse_force_ramp('W', [0 0.75], [-465e6 -445e6], '=') ;
        run.tm.perturb{end+1} = copse_force_ramp('W', [0 0.25], [-115e6 -100e6], '+') ;
        %Ramp up P weathering to get +2 per mil d13C plateau
        run.tm.perturb{end+1} = copse_force_ramp('F_EPSILON', [0 0.5], [-465e6 -445e6], '+') ;
        run.tm.perturb{end+1} = copse_force_ramp('F_EPSILON', [0 -0.5], [-410e6 -400e6], '+') ;
    case 'paleozoic_red'
        % Paleozoic model as in Lenton et al. (2016) - red run
        run.tm.pars = copse_modify_struct( run.tm.pars, 'f_atfrac', 'quadratic' );
        %Paleozoic paper forcing of E
        run.tm.perturb{end+1} = copse_force_ramp('EVO', [0 0.15], [-465e6 -445e6], '=') ;
        run.tm.perturb{end+1} = copse_force_ramp('EVO', [0 0.1], [-400e6 -380e6], '+') ;
        run.tm.perturb{end+1} = copse_force_ramp('EVO', [0 0.5], [-380e6 -330e6], '+') ;
        run.tm.perturb{end+1} = copse_force_ramp('EVO', [0 0.25], [-330e6 -300e6], '+') ;
        %Paleozoic paper forcing of W
        run.tm.perturb{end+1} = copse_force_ramp('W', [0 0.75], [-465e6 -445e6], '=') ;
        run.tm.perturb{end+1} = copse_force_ramp('W', [0 0.25], [-115e6 -100e6], '+') ;
        %Paleozoic forcing of C/P land
        run.tm.perturb{end+1} = copse_force_ramp('CPland_relative', [0 1], [-465e6 -445e6], '+') ;
        run.tm.perturb{end+1} = copse_force_ramp('CPland_relative', [0 -1], [-355e6 -345e6], '+') ;
        %Ramp up P weathering to get +2 per mil d13C plateau
        run.tm.perturb{end+1} = copse_force_ramp('F_EPSILON', [0 0.25], [-465e6 -445e6], '+') ;
        run.tm.perturb{end+1} = copse_force_ramp('F_EPSILON', [0 -0.25], [-410e6 -400e6], '+') ;
    case 'paleozoic_black'
        % Paleozoic model as in Lenton et al. (2016) - black run
        run.tm.pars = copse_modify_struct( run.tm.pars, 'f_atfrac', 'quadratic' );
        %Paleozoic paper forcing of E
        run.tm.perturb{end+1} = copse_force_ramp('EVO', [0 0.15], [-465e6 -445e6], '=') ;
        run.tm.perturb{end+1} = copse_force_ramp('EVO', [0 0.1], [-400e6 -380e6], '+') ;
        run.tm.perturb{end+1} = copse_force_ramp('EVO', [0 0.5], [-380e6 -330e6], '+') ;
        run.tm.perturb{end+1} = copse_force_ramp('EVO', [0 0.25], [-330e6 -300e6], '+') ;
        %Paleozoic paper forcing of W
        run.tm.perturb{end+1} = copse_force_ramp('W', [0 0.75], [-465e6 -445e6], '=') ;
        run.tm.perturb{end+1} = copse_force_ramp('W', [0 0.25], [-115e6 -100e6], '+') ;
        %Paleozoic forcing of C/P land
        run.tm.perturb{end+1} = copse_force_ramp('CPland_relative', [0 1], [-465e6 -445e6], '+') ;
        run.tm.perturb{end+1} = copse_force_ramp('CPland_relative', [0 -1], [-355e6 -345e6], '+') ;
        %P weathering spikes
        run.tm.perturb{end+1} = copse_force_ramp('F_EPSILON', [0 1.5], [-453e6 -452.5e6], '+') ;
        run.tm.perturb{end+1} = copse_force_ramp('F_EPSILON', [0 -1.5], [-452.5e6 -452e6], '+') ;
        run.tm.perturb{end+1} = copse_force_ramp('F_EPSILON', [0 2.5], [-445e6 -444.5e6], '+') ;
        run.tm.perturb{end+1} = copse_force_ramp('F_EPSILON', [0 -2.5], [-444.5e6 -444e6], '+') ;
        run.tm.perturb{end+1} = copse_force_ramp('F_EPSILON', [0 1], [-433.25e6 -433e6], '+') ;
        run.tm.perturb{end+1} = copse_force_ramp('F_EPSILON', [0 -1], [-432e6 -431.5e6], '+') ;
        run.tm.perturb{end+1} = copse_force_ramp('F_EPSILON', [0 0.5], [-430e6 -429e6], '+') ;
        run.tm.perturb{end+1} = copse_force_ramp('F_EPSILON', [0 -0.5], [-429e6 -428e6], '+') ;
        run.tm.perturb{end+1} = copse_force_ramp('F_EPSILON', [0 2], [-424.75e6 -424.25e6], '+') ;
        run.tm.perturb{end+1} = copse_force_ramp('F_EPSILON', [0 -2], [-424.25e6 -423e6], '+') ;
        run.tm.perturb{end+1} = copse_force_ramp('F_EPSILON', [0 1.25], [-420e6 -419e6], '+') ;
        run.tm.perturb{end+1} = copse_force_ramp('F_EPSILON', [0 -1.25], [-419e6 -418e6], '+') ;
        run.tm.perturb{end+1} = copse_force_ramp('F_EPSILON', [0 0.5], [-416e6 -415e6], '+') ;
        run.tm.perturb{end+1} = copse_force_ramp('F_EPSILON', [0 -0.5], [-408e6 -404e6], '+') ;
        
    
        
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
        {'newpage';'datamrO2'; 'datapO2'; 'dataCO2'; 'dataSO4'; 'datad13C'; 'datad13Cnew'; 'datad34Smov'; 'datad34Sbinmov'; 'data8786Sr' } ];
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


end
