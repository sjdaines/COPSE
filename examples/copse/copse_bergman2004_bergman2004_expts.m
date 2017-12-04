function run = copse_bergman2004_bergman2004_expts(baseline, expt)
% COPSE experiments from Bergman (2004), Table 3 + additional examples 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%% 'The model': Create and set parameters from config file 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
run             = paleo_run;

run.tm = paleo_modelbuilder.createModel('COPSE_bergman2004_bergman2004_cfg.yaml','copse5_14_base');
tm = run.tm;

% string for plot labelling
run.baseconfig  = '';
run.config      = 'copse_bergman2004_bergman2004_expts';
% text strings for plot labelling etc
run.expt        = expt;
fprintf('Experiment %s\n',run.expt);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%% calculate unknowns assuming present day steady state
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
run.tm.pars.k17_oxidw      = run.tm.pars.k2_mocb + run.tm.pars.k5_locb -run.tm.pars.k13_ocdeg  ;
run.tm.pars.k_silw         = -run.tm.pars.k2_mocb -run.tm.pars.k5_locb + run.tm.pars.k17_oxidw + run.tm.pars.k13_ocdeg + run.tm.pars.k12_ccdeg ;
run.tm.pars.k10_phosw      = ( run.tm.pars.k2_mocb/run.tm.pars.CPsea0  +run.tm.pars.k7_capb +run.tm.pars.k6_fepb )  / (1-run.tm.pars.k11_landfrac) ;


    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%% run control
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%% Set forcing mode for this run (defines time supplied to historical
%%%%%%% forcings)
run.tm.forcemode = 'TimeDep';          
% SteadyState fixes historical forcing at timeforceSteadyState
%runctrl.forcemode = 'SteadyState'
%runctrl.timeforceSteadyState = run.tm.pars.time_present_yr-550e6

%%%%%%%% Set forcing functions for this run
run.tm.force = {copse_force_CK_solar; copse_force_UDWEbergman2004(1); copse_force_B; copse_force_CPlandrel}; % historical forcings from COPSE
run.tm.perturb = {};

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

%%%%% Plot configuration 

run.analyzers = paleo_plotlist();
run.analyzers.plotters = {@copse_plot_base};
run.analyzers.listplots={ 'PhysForc'; 'EvolForc'; 'O2'; 'CO2'; 'Temp'; 'OceanNP'; 'Biota'; 'LandBiota';'FireIgnit';
        'O2';'O2Diff'; 'SIsotopes';'CO2';'CO2Diff';'SIsotopesDiff';'CIsotopes';'CIsotopesDiff';'newpage';
        'CResChange';'SResChange';'RedoxChange';'CaResChange';'newpage';
        'CDegass'; 'CPWeath'; 'PWeath';'WeathFac'; 'WeathFacNorm';'PBurial'; 'CPBurialratio'; 'orgCBurial';  'FRatio'; 'CIsotopes'; 'CRes'; 'CCrustRes';
        'SDegass'; 'SWeath'; 'SBurial'; 'GYPPYR'; 'SCAL'; 'SIsotopes';
        };

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%% END run control
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%% Modify base configuration for requested expt
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

switch expt
    case 'baseline'
        % Baseline configuration
        
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
        
        %Bergman (2004) uses this, which limits fall of pO2 prior to Ordovician
        %run.tm.pars = copse_modify_struct( run.tm.pars,'f_ocdeg','O2copsecrashprevent');
        
    case 'fixedcisotopefrac'
        % Fixed C isotope fractions
        run.tm.pars = copse_modify_struct( run.tm.pars,'f_cisotopefrac','fixed');
        
    case 'longspinup'
        %Baseline config, with longer spinup
        %Illustrates that crustal reservoirs need ~200My to equilibrate from
        %Modern starting values to steady-state (less C burial in low O)
        %(which might not be right, of course... no Neoproterozoic events here)
        
        run.Tstart           = paleo_const.time_present_yr-1000e6; % longer spinup
        run.integrator.timetoadd = 1000e6;
        run.tm.pars = copse_modify_struct(run.tm.pars, 'Ainit', 20*run.tm.pars.A0); % high CO2 - modify default initialisation
        
    case 'carbwC'
        % Carbonate weathering proportional to C reservoir size
        % very small change as expected, as C only varies by ~2%
        
        run.tm.pars = copse_modify_struct( run.tm.pars,'f_carbw','Cprop');
        
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
        
    case 'cambperturb'
        % Forcing perturbations against Cambrian steady-state
        
        % SteadyState fixes historical forcing at timeforceSteadyState
        run.tm.forcemode = 'SteadyState';
        run.tm.timeforceSteadyState = paleo_const.time_present_yr-550e6;
        
        % Add perturbations to forcing
        run.tm.perturb{end+1} = copse_force_examples;
        %                       copse_force_co2pulse(size, duration, tstart,d13C)
        run.tm.perturb{end+1} = copse_force_co2pulse(3e18, 10e3,600000e3,-30) ;
        
        %%%%%%% Set duration for this run
        
        % For eg perturbation experiments that don't use historical forcings, can start from zero for convenience
        run.Tstart             = 100e6;
        run.integrator.timetoadd=550e6;
        
        % Identifiy any discontinuities and force restart with small step size
        %runctrl.timerestarts              = [];
        run.integrator.timerestarts              = [600e6];
        
    
        
    otherwise
        error('unknown runctrl.expt %s\n',runctrl.expt);
end
