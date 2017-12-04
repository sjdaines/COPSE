function run = copse_reloaded_reloaded_expts(basemodel, expt, comparedata)
% COPSE reloaded experiments 


%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%% run control
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

run             = paleo_run;
run.config = 'copse_reloaded_reloaded_expts';
run.expt = sprintf('%s', expt);
run.baseconfig  = basemodel;
fprintf('Basemodel %s Experiment %s\n',basemodel, expt);

%%%%%%% Set duration for this run
% For historical forcings, run from before present day to present day
run.Tstart           = paleo_const.time_present_yr-1000e6; % Phanerozoic with longer spinup

% Integrate method
run.integrator = paleo_integrate_ode(1000e6);
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
        'O2';'O2Diff'; 'SIsotopes';'CO2';'CO2Diff';'SIsotopesDiff';'CIsotopes';'CIsotopesDiff';'SrfracDiff';
        'CResChange';'SResChange';'RedoxChange';'CaResChange';'newpage';
        'CDegass'; 'CPWeath'; 'PWeath';'WeathFac2';'PBurial'; 'CPBurialratio'; 'orgCBurial';  'FRatio'; 'CIsotopes'; 'CIsotopesIO'; 'CRes'; 'CCrustRes';
        'SDegass'; 'SWeath'; 'SBurial'; 'GYPPYR'; 'SCAL'; 'SIsotopes'; 'SFW'; 'Srconc'; 'Srfluxes'; 'Srfrac';
        };    
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%% END run control
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Set base model
switch basemodel
    
    case 'reloaded'
        %%%% this is the Lenton et al 'COPSE reloaded' new baseline model,
        % with updated LIP lambda decay rate to generate present-day CFB area = 4.8e6 km2
        run.tm = paleo_modelbuilder.createModel('COPSE_reloaded_reloaded_cfg.yaml','copse_reloaded');

        %%% SET UP THE MODEL FORCING FACTORS
        
        %%%%%%%%%%%% ADD NEW LIPS FORCING DIRECTLY FROM DATA TABLE
        phanlip = copse_load_phanlip('copseRL');
        LIPtrange = [-Inf Inf];  % all lips
        smoothempl = false; % true for pre-revision G3, false for revised paper
        present_day_CFB_area = 4.8e6;
        
        [flips, default_lambda, ~] = phanlip.create_LIP_forcing(run.Tstart, run.Tstart+run.integrator.timetoadd, ...
                                                                'NoCO2', present_day_CFB_area, LIPtrange, smoothempl);  
        fprintf('default_lambda = %g yr-1 to match present day CFB area %g km2\n', default_lambda, present_day_CFB_area);  
        %%% add to forcing list
        run.tm.force{end+1} = flips    ;  

        % get two contributions to present day basalt area
        fdegass = copse_find_force( run.tm, 'copse_force_haq_D'); % NB this is needed for OIB_area     
        present_basalt_area = present_day_CFB_area + fdegass.present_day_OIB_area();
        
        fprintf('updating run.tm.pars.k_present_basalt_area old %g\n',run.tm.pars.k_present_basalt_area);
        run.tm.pars = copse_modify_struct(run.tm.pars, 'k_present_basalt_area', present_basalt_area);
        fprintf('                                           new CFB %g + OIB %g = %g\n', ...
          present_day_CFB_area, fdegass.present_day_OIB_area(), run.tm.pars.k_present_basalt_area);
        %%% Enable basalt area forcing (present-day value for normalisation calculated above)
        run.tm.pars.f_basaltarea   = 'g3_2014_construct_from_lips';
        %%%%%%%%%% FINISH LIPS THING
        
        % Add new plots
        run.analyzers.listplots{end+1} = 'BasaltArea';
        run.analyzers.listplots{end+1} = 'LIPCO2';
        run.analyzers.listplots{end+1} = 'SilicateArea';
        run.analyzers.listplots{end+1} = 'CoalFrac';
               
    case 'original'
        %%%% this is a reconstruction of the original COPSE model
        %%%% run for Phanerozoic with long spin-up as in COPSE reloaded
        % Lenton et al 'COPSE reloaded' 
        run.tm = paleo_modelbuilder.createModel('COPSE_reloaded_bergman2004_cfg.yaml','copse5_14_base');
        
    case 'newbase'
        %%%% this is the new baseline COPSE model structure
        %%%% but without flux updates and additional forcing factors
        %%%% run for Phanerozoic with long spin-up as in COPSE reloaded

        run.tm = paleo_modelbuilder.createModel('COPSE_reloaded_reloaded_cfg.yaml','copse_reloaded');
       
        %%% SET UP THE MODEL FORCING FACTORS
        % Reset (all) forcings to original        
        run.tm.force = {copse_force_CK_solar; copse_force_UDWEbergman2004(1); copse_force_B; copse_force_CPlandrel}; % historical forcings from COPSE
        % Include updates to original forcing factors, plus [Ca++] forcing
        run.tm.force{end+1} = copse_force_haq_D(); 
        run.tm.force{end+1} = copse_force_ramp('Bforcing', [0.75 1.0], [-150e6 -0e6], '=') ;
        run.tm.force{end+1} = copse_force_berner_fr(1);
        run.tm.force{end+1} = copse_force_ramp('EVO', [0 0.15], [-465e6 -445e6], '=') ;
        run.tm.force{end+1} = copse_force_ramp('EVO', [0 0.85], [-400e6 -350e6], '+') ;
        run.tm.force{end+1} = copse_force_ramp('W', [0 0.75], [-465e6 -445e6], '=') ;
        run.tm.force{end+1} = copse_force_ramp('W', [0 0.25], [-400e6 -350e6], '+') ;
        run.tm.force{end+1} = copse_force_ramp('CPland_relative', [1 2], [-465e6 -445e6], '=') ;
        run.tm.force{end+1} = copse_force_ramp('CPland_relative', [0 -1], [-290e6 -280e6], '+') ;
        run.tm.force{end+1} = copse_force_calcium('calnorm');      

        % Accept new model structure from .yaml except...
        run.tm.pars = copse_modify_struct( run.tm.pars,'f_granitearea','Fixed'); 
        run.tm.pars = copse_modify_struct( run.tm.pars,'f_basaltarea','DefaultForced'); 
        
        %%% Adopt G-cubed paper flux parameters
        %%% S cycle original fluxes
        run.tm.pars.k_gypdeg = 0e12;
        run.tm.pars.k_pyrdeg = 0e12;
        run.tm.pars.k21_pyrw = 0.53e12;
        run.tm.pars.k22_gypw = 1.0e12;
        %%% G-cubed paper seafloor weathering flux
        run.tm.pars.k_sfw = 1.75e12;
        %%% Inorganic C cycle original fluxes:
        run.tm.pars.k12_ccdeg = 6.65e12;
        run.tm.pars.k14_carbw = 13.35e12;
        run.tm.pars.k_basfrac = 0.35;
        %%% Organic C cycle original fluxes:
        run.tm.pars.k2_mocb = 4.5e12;
        run.tm.pars.k5_locb = 4.5e12;
        %%% Original P cycle
        run.tm.pars.k_Psilw = (2/12); 
        run.tm.pars.k_Pcarbw = (5/12); 
        run.tm.pars.k_Poxidw = (5/12); 
        run.tm.pars.k6_fepb = 6e9;
        run.tm.pars.k7_capb = 1.5e10;

        % Add new plots
        run.analyzers.listplots{end+1} = 'BasaltArea';
        run.analyzers.listplots{end+1} = 'LIPCO2';
        run.analyzers.listplots{end+1} = 'SilicateArea';
        run.analyzers.listplots{end+1} = 'CoalFrac';
          
    otherwise
        error('unknown basemodel %s',basemodel);
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Choose an 'experiment' (a delta to the base model)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

switch expt
    
    case 'baseline'
        % Baseline configuration

    %%%% Experiments in Fig. 5-7 of COPSE reloaded (for basemodel 'original') 
    case 'DB'
        % Fig.5 blue
        run.tm.force{end+1} = copse_force_haq_D(); 
        run.tm.force{end+1} = copse_force_ramp('Bforcing', [0.75 1.0], [-150e6 -0e6], '=') ;
    case 'U'
        % Fig.5 red
        run.tm.force{end+1} = copse_force_berner_fr(1);
    case 'EWCP'
        % Fig.5 green
        run.tm.force{end+1} = copse_force_ramp('EVO', [0 0.15], [-465e6 -445e6], '=') ;
        run.tm.force{end+1} = copse_force_ramp('EVO', [0 0.85], [-400e6 -350e6], '+') ;
        run.tm.force{end+1} = copse_force_ramp('W', [0 0.75], [-465e6 -445e6], '=') ;
        run.tm.force{end+1} = copse_force_ramp('W', [0 0.25], [-400e6 -350e6], '+') ;
        run.tm.force{end+1} = copse_force_ramp('CPland_relative', [1 2], [-465e6 -445e6], '=') ;
        run.tm.force{end+1} = copse_force_ramp('CPland_relative', [0 -1], [-290e6 -280e6], '+') ;
    case 'DUEWBCP'
        % Fig.5 black / Fig.6 black dashed / Fig.7 black dashed
        run.tm.force{end+1} = copse_force_haq_D(); 
        run.tm.force{end+1} = copse_force_ramp('Bforcing', [0.75 1.0], [-150e6 -0e6], '=') ;
        run.tm.force{end+1} = copse_force_berner_fr(1);
        run.tm.force{end+1} = copse_force_ramp('EVO', [0 0.15], [-465e6 -445e6], '=') ;
        run.tm.force{end+1} = copse_force_ramp('EVO', [0 0.85], [-400e6 -350e6], '+') ;
        run.tm.force{end+1} = copse_force_ramp('W', [0 0.75], [-465e6 -445e6], '=') ;
        run.tm.force{end+1} = copse_force_ramp('W', [0 0.25], [-400e6 -350e6], '+') ;
        run.tm.force{end+1} = copse_force_ramp('CPland_relative', [1 2], [-465e6 -445e6], '=') ;
        run.tm.force{end+1} = copse_force_ramp('CPland_relative', [0 -1], [-290e6 -280e6], '+') ;
    case 'sfw'
        % Fig.6 blue
        run.tm.force{end+1} = copse_force_haq_D(); 
        run.tm.force{end+1} = copse_force_ramp('Bforcing', [0.75 1.0], [-150e6 -0e6], '=') ;
        run.tm.force{end+1} = copse_force_berner_fr(1);
        run.tm.force{end+1} = copse_force_ramp('EVO', [0 0.15], [-465e6 -445e6], '=') ;
        run.tm.force{end+1} = copse_force_ramp('EVO', [0 0.85], [-400e6 -350e6], '+') ;
        run.tm.force{end+1} = copse_force_ramp('W', [0 0.75], [-465e6 -445e6], '=') ;
        run.tm.force{end+1} = copse_force_ramp('W', [0 0.25], [-400e6 -350e6], '+') ;
        run.tm.force{end+1} = copse_force_ramp('CPland_relative', [1 2], [-465e6 -445e6], '=') ;
        run.tm.force{end+1} = copse_force_ramp('CPland_relative', [0 -1], [-290e6 -280e6], '+') ;
        run.tm.pars.k_sfw = 1.75e12;
    case 'basnoU'
        % Fig.6 red
        run.tm.force{end+1} = copse_force_haq_D(); 
        run.tm.force{end+1} = copse_force_ramp('Bforcing', [0.75 1.0], [-150e6 -0e6], '=') ;
        run.tm.force{end+1} = copse_force_berner_fr(1);
        run.tm.force{end+1} = copse_force_ramp('EVO', [0 0.15], [-465e6 -445e6], '=') ;
        run.tm.force{end+1} = copse_force_ramp('EVO', [0 0.85], [-400e6 -350e6], '+') ;
        run.tm.force{end+1} = copse_force_ramp('W', [0 0.75], [-465e6 -445e6], '=') ;
        run.tm.force{end+1} = copse_force_ramp('W', [0 0.25], [-400e6 -350e6], '+') ;
        run.tm.force{end+1} = copse_force_ramp('CPland_relative', [1 2], [-465e6 -445e6], '=') ;
        run.tm.force{end+1} = copse_force_ramp('CPland_relative', [0 -1], [-290e6 -280e6], '+') ;
        run.tm.pars.f_bas_link_u = 'no'; 
    case 'Easplit'
        % Fig.6 cyan
        run.tm.force{end+1} = copse_force_haq_D(); 
        run.tm.force{end+1} = copse_force_ramp('Bforcing', [0.75 1.0], [-150e6 -0e6], '=') ;
        run.tm.force{end+1} = copse_force_berner_fr(1);
        run.tm.force{end+1} = copse_force_ramp('EVO', [0 0.15], [-465e6 -445e6], '=') ;
        run.tm.force{end+1} = copse_force_ramp('EVO', [0 0.85], [-400e6 -350e6], '+') ;
        run.tm.force{end+1} = copse_force_ramp('W', [0 0.75], [-465e6 -445e6], '=') ;
        run.tm.force{end+1} = copse_force_ramp('W', [0 0.25], [-400e6 -350e6], '+') ;
        run.tm.force{end+1} = copse_force_ramp('CPland_relative', [1 2], [-465e6 -445e6], '=') ;
        run.tm.force{end+1} = copse_force_ramp('CPland_relative', [0 -1], [-290e6 -280e6], '+') ;
        run.tm.pars = copse_modify_struct( run.tm.pars,'f_act_energies','split'); 
    case 'vegweath'
        % Fig.6 green
        run.tm.force{end+1} = copse_force_haq_D(); 
        run.tm.force{end+1} = copse_force_ramp('Bforcing', [0.75 1.0], [-150e6 -0e6], '=') ;
        run.tm.force{end+1} = copse_force_berner_fr(1);
        run.tm.force{end+1} = copse_force_ramp('EVO', [0 0.15], [-465e6 -445e6], '=') ;
        run.tm.force{end+1} = copse_force_ramp('EVO', [0 0.85], [-400e6 -350e6], '+') ;
        run.tm.force{end+1} = copse_force_ramp('W', [0 0.75], [-465e6 -445e6], '=') ;
        run.tm.force{end+1} = copse_force_ramp('W', [0 0.25], [-400e6 -350e6], '+') ;
        run.tm.force{end+1} = copse_force_ramp('CPland_relative', [1 2], [-465e6 -445e6], '=') ;
        run.tm.force{end+1} = copse_force_ramp('CPland_relative', [0 -1], [-290e6 -280e6], '+') ;
        run.tm.pars = copse_modify_struct( run.tm.pars,'f_vegweath', 'new2'); 
    case 'bernerT'
        % Fig.6 magenta
        run.tm.force{end+1} = copse_force_haq_D(); 
        run.tm.force{end+1} = copse_force_ramp('Bforcing', [0.75 1.0], [-150e6 -0e6], '=') ;
        run.tm.force{end+1} = copse_force_berner_fr(1);
        run.tm.force{end+1} = copse_force_ramp('EVO', [0 0.15], [-465e6 -445e6], '=') ;
        run.tm.force{end+1} = copse_force_ramp('EVO', [0 0.85], [-400e6 -350e6], '+') ;
        run.tm.force{end+1} = copse_force_ramp('W', [0 0.75], [-465e6 -445e6], '=') ;
        run.tm.force{end+1} = copse_force_ramp('W', [0 0.25], [-400e6 -350e6], '+') ;
        run.tm.force{end+1} = copse_force_ramp('CPland_relative', [1 2], [-465e6 -445e6], '=') ;
        run.tm.force{end+1} = copse_force_ramp('CPland_relative', [0 -1], [-290e6 -280e6], '+') ;
        run.tm.pars = copse_modify_struct( run.tm.pars, 'f_temp', 'Berner' );
    case 'newweath'
        % Fig.6 black
        run.tm.force{end+1} = copse_force_haq_D(); 
        run.tm.force{end+1} = copse_force_ramp('Bforcing', [0.75 1.0], [-150e6 -0e6], '=') ;
        run.tm.force{end+1} = copse_force_berner_fr(1);
        run.tm.force{end+1} = copse_force_ramp('EVO', [0 0.15], [-465e6 -445e6], '=') ;
        run.tm.force{end+1} = copse_force_ramp('EVO', [0 0.85], [-400e6 -350e6], '+') ;
        run.tm.force{end+1} = copse_force_ramp('W', [0 0.75], [-465e6 -445e6], '=') ;
        run.tm.force{end+1} = copse_force_ramp('W', [0 0.25], [-400e6 -350e6], '+') ;
        run.tm.force{end+1} = copse_force_ramp('CPland_relative', [1 2], [-465e6 -445e6], '=') ;
        run.tm.force{end+1} = copse_force_ramp('CPland_relative', [0 -1], [-290e6 -280e6], '+') ;
        run.tm.pars.k_sfw = 1.75e12;
        run.tm.pars.f_bas_link_u = 'no'; 
        run.tm.pars = copse_modify_struct( run.tm.pars,'f_act_energies','split'); 
        run.tm.pars = copse_modify_struct( run.tm.pars,'f_vegweath', 'new2'); 
        run.tm.pars = copse_modify_struct( run.tm.pars, 'f_temp', 'Berner' );
    case 'CAL'
        % Fig.7 blue
        run.tm.force{end+1} = copse_force_haq_D(); 
        run.tm.force{end+1} = copse_force_ramp('Bforcing', [0.75 1.0], [-150e6 -0e6], '=') ;
        run.tm.force{end+1} = copse_force_berner_fr(1);
        run.tm.force{end+1} = copse_force_ramp('EVO', [0 0.15], [-465e6 -445e6], '=') ;
        run.tm.force{end+1} = copse_force_ramp('EVO', [0 0.85], [-400e6 -350e6], '+') ;
        run.tm.force{end+1} = copse_force_ramp('W', [0 0.75], [-465e6 -445e6], '=') ;
        run.tm.force{end+1} = copse_force_ramp('W', [0 0.25], [-400e6 -350e6], '+') ;
        run.tm.force{end+1} = copse_force_ramp('CPland_relative', [1 2], [-465e6 -445e6], '=') ;
        run.tm.force{end+1} = copse_force_ramp('CPland_relative', [0 -1], [-290e6 -280e6], '+') ;
        run.tm.force{end+1} = copse_force_calcium('calnorm');      
        run.tm.pars = copse_modify_struct( run.tm.pars,'CALcycle','None'); 
        run.tm.pars = copse_modify_struct( run.tm.pars, 'f_gypburial', 'Caforced' ); 
    case 'ignit'
        % Fig.7 red
        run.tm.force{end+1} = copse_force_haq_D(); 
        run.tm.force{end+1} = copse_force_ramp('Bforcing', [0.75 1.0], [-150e6 -0e6], '=') ;
        run.tm.force{end+1} = copse_force_berner_fr(1);
        run.tm.force{end+1} = copse_force_ramp('EVO', [0 0.15], [-465e6 -445e6], '=') ;
        run.tm.force{end+1} = copse_force_ramp('EVO', [0 0.85], [-400e6 -350e6], '+') ;
        run.tm.force{end+1} = copse_force_ramp('W', [0 0.75], [-465e6 -445e6], '=') ;
        run.tm.force{end+1} = copse_force_ramp('W', [0 0.25], [-400e6 -350e6], '+') ;
        run.tm.force{end+1} = copse_force_ramp('CPland_relative', [1 2], [-465e6 -445e6], '=') ;
        run.tm.force{end+1} = copse_force_ramp('CPland_relative', [0 -1], [-290e6 -280e6], '+') ;
        run.tm.pars = copse_modify_struct( run.tm.pars,'f_ignit','bookchapter'); 
        run.tm.pars = copse_modify_struct( run.tm.pars,'k_fire',3); 
    case 'pyrweath'
        % Fig.7 cyan
        run.tm.force{end+1} = copse_force_haq_D(); 
        run.tm.force{end+1} = copse_force_ramp('Bforcing', [0.75 1.0], [-150e6 -0e6], '=') ;
        run.tm.force{end+1} = copse_force_berner_fr(1);
        run.tm.force{end+1} = copse_force_ramp('EVO', [0 0.15], [-465e6 -445e6], '=') ;
        run.tm.force{end+1} = copse_force_ramp('EVO', [0 0.85], [-400e6 -350e6], '+') ;
        run.tm.force{end+1} = copse_force_ramp('W', [0 0.75], [-465e6 -445e6], '=') ;
        run.tm.force{end+1} = copse_force_ramp('W', [0 0.25], [-400e6 -350e6], '+') ;
        run.tm.force{end+1} = copse_force_ramp('CPland_relative', [1 2], [-465e6 -445e6], '=') ;
        run.tm.force{end+1} = copse_force_ramp('CPland_relative', [0 -1], [-290e6 -280e6], '+') ;
        run.tm.pars = copse_modify_struct( run.tm.pars,'f_pyrweather', 'copse_noO2' ); 
    case 'newweathredox'
        % Fig.7 green
        run.tm.force{end+1} = copse_force_haq_D(); 
        run.tm.force{end+1} = copse_force_ramp('Bforcing', [0.75 1.0], [-150e6 -0e6], '=') ;
        run.tm.force{end+1} = copse_force_berner_fr(1);
        run.tm.force{end+1} = copse_force_ramp('EVO', [0 0.15], [-465e6 -445e6], '=') ;
        run.tm.force{end+1} = copse_force_ramp('EVO', [0 0.85], [-400e6 -350e6], '+') ;
        run.tm.force{end+1} = copse_force_ramp('W', [0 0.75], [-465e6 -445e6], '=') ;
        run.tm.force{end+1} = copse_force_ramp('W', [0 0.25], [-400e6 -350e6], '+') ;
        run.tm.force{end+1} = copse_force_ramp('CPland_relative', [1 2], [-465e6 -445e6], '=') ;
        run.tm.force{end+1} = copse_force_ramp('CPland_relative', [0 -1], [-290e6 -280e6], '+') ;
        run.tm.pars.k_sfw = 1.75e12;
        run.tm.pars.f_bas_link_u = 'no'; 
        run.tm.pars = copse_modify_struct( run.tm.pars,'f_act_energies','split'); 
        run.tm.pars = copse_modify_struct( run.tm.pars,'f_vegweath', 'new2'); 
        run.tm.pars = copse_modify_struct( run.tm.pars, 'f_temp', 'Berner' );
        run.tm.force{end+1} = copse_force_calcium('calnorm');      
        run.tm.pars = copse_modify_struct( run.tm.pars,'CALcycle','None'); 
        run.tm.pars = copse_modify_struct( run.tm.pars, 'f_gypburial', 'Caforced' ); 
        run.tm.pars = copse_modify_struct( run.tm.pars,'f_ignit','bookchapter'); 
        run.tm.pars = copse_modify_struct( run.tm.pars,'k_fire',3); 
        run.tm.pars = copse_modify_struct( run.tm.pars,'f_pyrweather', 'copse_noO2' ); 
    case 'newbase'
        % Fig.7 black
        run.tm.force{end+1} = copse_force_haq_D(); 
        run.tm.force{end+1} = copse_force_ramp('Bforcing', [0.75 1.0], [-150e6 -0e6], '=') ;
        run.tm.force{end+1} = copse_force_berner_fr(1);
        run.tm.force{end+1} = copse_force_ramp('EVO', [0 0.15], [-465e6 -445e6], '=') ;
        run.tm.force{end+1} = copse_force_ramp('EVO', [0 0.85], [-400e6 -350e6], '+') ;
        run.tm.force{end+1} = copse_force_ramp('W', [0 0.75], [-465e6 -445e6], '=') ;
        run.tm.force{end+1} = copse_force_ramp('W', [0 0.25], [-400e6 -350e6], '+') ;
        run.tm.force{end+1} = copse_force_ramp('CPland_relative', [1 2], [-465e6 -445e6], '=') ;
        run.tm.force{end+1} = copse_force_ramp('CPland_relative', [0 -1], [-290e6 -280e6], '+') ;
        run.tm.pars.k_sfw = 1.75e12;
        run.tm.pars.f_bas_link_u = 'no'; 
        run.tm.pars = copse_modify_struct( run.tm.pars,'f_act_energies','split'); 
        run.tm.pars = copse_modify_struct( run.tm.pars,'f_vegweath', 'new2'); 
        run.tm.pars = copse_modify_struct( run.tm.pars, 'f_temp', 'Berner' );
        run.tm.force{end+1} = copse_force_calcium('calnorm');      
        run.tm.pars = copse_modify_struct( run.tm.pars,'CALcycle','None'); 
        run.tm.pars = copse_modify_struct( run.tm.pars, 'f_gypburial', 'Caforced' ); 
        run.tm.pars = copse_modify_struct( run.tm.pars,'f_ignit','bookchapter'); 
        run.tm.pars = copse_modify_struct( run.tm.pars,'k_fire',3); 
        run.tm.pars = copse_modify_struct( run.tm.pars,'f_pyrweather', 'copse_noO2' ); 
        run.tm.pars = copse_modify_struct( run.tm.pars, 'f_atfrac', 'quadratic' );
        run.tm.pars = copse_modify_struct(run.tm.pars,'f_carbwC','Cprop');
        run.tm.pars = copse_modify_struct( run.tm.pars,'f_gypweather', 'alternative' ); 
        run.tm.pars = copse_modify_struct(run.tm.pars, 'f_anoxia', 'newanoxia');
        run.tm.pars.k_logistic = 12.0 ; 
        run.tm.pars.k_uptake = 0.5 ; 
        run.tm.pars.k1_oxfrac = 1.0 - 1.0/(1.0 + exp(-run.tm.pars.k_logistic*(run.tm.pars.k_uptake-1.0)));
        run.tm.pars = copse_modify_struct(run.tm.pars, 'f_denit', 'new');
        run.tm.pars = copse_modify_struct( run.tm.pars,'f_fepb','pdep'); 

    %%%% Experiments in Fig. 8-9 of COPSE reloaded (for basemodel 'newbase') 
    case 'highS'
        % Fig.8 blue
        run.tm.pars.k_gypdeg = 0.5e12;
        run.tm.pars.k_pyrdeg = 0.25e12;
        run.tm.pars.k21_pyrw = 0.45e12;
        run.tm.pars.k22_gypw = 2.0e12;
    case 'highCin'
        % Fig.8 red
        run.tm.pars.k_sfw = 3e12;
        run.tm.pars.k12_ccdeg = 15e12;
        run.tm.pars.k14_carbw = 8e12;
        run.tm.pars.k_basfrac = 0.25;
    case 'lowCorg'
        % Fig.8 green
        run.tm.pars.k2_mocb = 2.5e12;
        run.tm.pars.k5_locb = 2.5e12;
    case 'Pweath'
        % Fig.8 cyan
        run.tm.pars.k_Psilw = 0.8; 
        run.tm.pars.k_Pcarbw = 0.14; 
        run.tm.pars.k_Poxidw = 0.06; 
    case 'newfluxes'
        % Fig.8 black / Fig.9 black dashed
        run.tm.pars.k_gypdeg = 0.5e12;
        run.tm.pars.k_pyrdeg = 0.25e12;
        run.tm.pars.k21_pyrw = 0.45e12;
        run.tm.pars.k22_gypw = 2.0e12;
        run.tm.pars.k_sfw = 3e12;
        run.tm.pars.k12_ccdeg = 15e12;
        run.tm.pars.k14_carbw = 8e12;
        run.tm.pars.k_basfrac = 0.25;
        run.tm.pars.k2_mocb = 2.5e12;
        run.tm.pars.k5_locb = 2.5e12;
        run.tm.pars.k_Psilw = 0.8; 
        run.tm.pars.k_Pcarbw = 0.14; 
        run.tm.pars.k_Poxidw = 0.06; 
        run.tm.pars.k6_fepb = 1e10;
        run.tm.pars.k7_capb = 2e10;
    case 'basalt'
        % Fig.9 blue
        run.tm.pars.k_gypdeg = 0.5e12;
        run.tm.pars.k_pyrdeg = 0.25e12;
        run.tm.pars.k21_pyrw = 0.45e12;
        run.tm.pars.k22_gypw = 2.0e12;
        run.tm.pars.k_sfw = 3e12;
        run.tm.pars.k12_ccdeg = 15e12;
        run.tm.pars.k14_carbw = 8e12;
        run.tm.pars.k_basfrac = 0.25;
        run.tm.pars.k2_mocb = 2.5e12;
        run.tm.pars.k5_locb = 2.5e12;
        run.tm.pars.k_Psilw = 0.8; 
        run.tm.pars.k_Pcarbw = 0.14; 
        run.tm.pars.k_Poxidw = 0.06; 
        run.tm.pars.k6_fepb = 1e10;
        run.tm.pars.k7_capb = 2e10;
        
        % Add new LIPs forcing
        phanlip = copse_load_phanlip('copseRL');
        LIPtrange = [-Inf Inf];  % all lips
        smoothempl = false; % true for pre-revision G3, false for revised paper
        present_day_CFB_area = 4.8e6;
        
        [flips, default_lambda, ~] = phanlip.create_LIP_forcing(run.Tstart, run.Tstart+run.integrator.timetoadd, ...
                                                                'NoCO2', present_day_CFB_area, LIPtrange, smoothempl);  
        fprintf('default_lambda = %g yr-1 to match present day CFB area %g km2\n', default_lambda, present_day_CFB_area);  
        %%% add to forcing list
        run.tm.force{end+1} = flips    ;  

        % get two contributions to present day basalt area
        fdegass = copse_find_force( run.tm, 'copse_force_haq_D'); % NB this is needed for OIB_area     
        present_basalt_area = present_day_CFB_area + fdegass.present_day_OIB_area();
        
        fprintf('updating run.tm.pars.k_present_basalt_area old %g\n',run.tm.pars.k_present_basalt_area);
        run.tm.pars = copse_modify_struct(run.tm.pars, 'k_present_basalt_area', present_basalt_area);
        fprintf('                                           new CFB %g + OIB %g = %g\n', ...
          present_day_CFB_area, fdegass.present_day_OIB_area(), run.tm.pars.k_present_basalt_area);
        %%% Enable basalt area forcing (present-day value for normalisation calculated above)
        run.tm.pars.f_basaltarea   = 'g3_2014_construct_from_lips';
        
    case 'granite'
        % Fig.9 red
        run.tm.pars.k_gypdeg = 0.5e12;
        run.tm.pars.k_pyrdeg = 0.25e12;
        run.tm.pars.k21_pyrw = 0.45e12;
        run.tm.pars.k22_gypw = 2.0e12;
        run.tm.pars.k_sfw = 3e12;
        run.tm.pars.k12_ccdeg = 15e12;
        run.tm.pars.k14_carbw = 8e12;
        run.tm.pars.k_basfrac = 0.25;
        run.tm.pars.k2_mocb = 2.5e12;
        run.tm.pars.k5_locb = 2.5e12;
        run.tm.pars.k_Psilw = 0.8; 
        run.tm.pars.k_Pcarbw = 0.14; 
        run.tm.pars.k_Poxidw = 0.06; 
        run.tm.pars.k6_fepb = 1e10;
        run.tm.pars.k7_capb = 2e10;
        run.tm.force{end+1} = copse_force_org_evap_area('orgevapnorm');      
        run.tm.force{end+1} = copse_force_granite('silnorm');      
        run.tm.pars = copse_modify_struct( run.tm.pars,'f_granitearea','OrgEvapForced'); 
    case 'PG'
        % Fig.9 cyan
        run.tm.pars.k_gypdeg = 0.5e12;
        run.tm.pars.k_pyrdeg = 0.25e12;
        run.tm.pars.k21_pyrw = 0.45e12;
        run.tm.pars.k22_gypw = 2.0e12;
        run.tm.pars.k_sfw = 3e12;
        run.tm.pars.k12_ccdeg = 15e12;
        run.tm.pars.k14_carbw = 8e12;
        run.tm.pars.k_basfrac = 0.25;
        run.tm.pars.k2_mocb = 2.5e12;
        run.tm.pars.k5_locb = 2.5e12;
        run.tm.pars.k_Psilw = 0.8; 
        run.tm.pars.k_Pcarbw = 0.14; 
        run.tm.pars.k_Poxidw = 0.06; 
        run.tm.pars.k6_fepb = 1e10;
        run.tm.pars.k7_capb = 2e10;
        run.tm.force{end+1} = copse_force_royer_fD(1);      
    case 'bcoal'
        % Fig.9 green
        run.tm.pars.k_gypdeg = 0.5e12;
        run.tm.pars.k_pyrdeg = 0.25e12;
        run.tm.pars.k21_pyrw = 0.45e12;
        run.tm.pars.k22_gypw = 2.0e12;
        run.tm.pars.k_sfw = 3e12;
        run.tm.pars.k12_ccdeg = 15e12;
        run.tm.pars.k14_carbw = 8e12;
        run.tm.pars.k_basfrac = 0.25;
        run.tm.pars.k2_mocb = 2.5e12;
        run.tm.pars.k5_locb = 2.5e12;
        run.tm.pars.k_Psilw = 0.8; 
        run.tm.pars.k_Pcarbw = 0.14; 
        run.tm.pars.k_Poxidw = 0.06; 
        run.tm.pars.k6_fepb = 1e10;
        run.tm.pars.k7_capb = 2e10;
        run.tm.force{end+1} = copse_force_coal('coalnorm');
        run.tm.force{end+1} = copse_force_ramp('CPland_relative', [1 2], [-465e6 -445e6], '=') ;
        run.tm.force{end+1} = copse_force_ramp('CPland_relative', [0 -1], [-345e6 -300e6], '+') ;
 
    %%%% Experiments in Figs. 10-12 of COPSE reloaded (for basemodel 'reloaded')   
    case 'k15025'
        % Fig.10 blue
        run.tm.pars.k15_plantenhance=0.25;        
    case 'k1501'
        % Fig.10 red
        run.tm.pars.k15_plantenhance=0.1;        
    case 'newnpp'
        % Fig.10 green
        run.tm.pars = copse_modify_struct( run.tm.pars,'f_vegweath', 'newnpp');        
    case 'sfwstrong'
        % Fig.10 cyan
        run.tm.pars = copse_modify_struct( run.tm.pars,'f_sfw_opt','sfw_strong');         
    case 'sfwnoT'
        % Fig.10 magenta
        run.tm.pars = copse_modify_struct( run.tm.pars,'f_sfw_opt','sfw_noT'); 
        
    case 'climsens15'
        % Fig.11 blue
        run.tm.pars.k_c = 2.164; %1.5        
    case 'climsens225'
        % Fig.11 green
        run.tm.pars.k_c = 3.246; %2.25        
    case 'climsens45'
        % Fig.11 cyan
        run.tm.pars.k_c = 6.492; %4.5        
    case 'climsens6'
        % Fig.11 red
        run.tm.pars.k_c = 8.656; %6
        
    case 'locbU'
        % Fig.12 blue
        run.tm.pars = copse_modify_struct( run.tm.pars,'f_locb','split');        
    case 'mocbU'
        % Fig.12 red
        run.tm.pars = copse_modify_struct( run.tm.pars,'f_mocb','Uforced');        
    case 'locbUmocbU'
        % Fig.12 green
        run.tm.pars = copse_modify_struct( run.tm.pars,'f_locb','split');
        run.tm.pars = copse_modify_struct( run.tm.pars,'f_mocb','Uforced');        
    case 'mocbO2'
        % Fig.12 cyan
        run.tm.pars = copse_modify_struct( run.tm.pars,'f_mocb','O2dep');
    case 'VCI'
        % Fig.12 magenta
        run.tm.pars = copse_modify_struct( run.tm.pars, 'f_CPsea', 'VCI' );

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
if strcmp(run.tm.pars.f_SRedoxAlk, 'degassing')
    % SD include sulphur degassing 
    run.tm.pars.k_silw         = run.tm.pars.k17_oxidw - (run.tm.pars.k2_mocb + run.tm.pars.k5_locb - run.tm.pars.k13_ocdeg) + run.tm.pars.k12_ccdeg - run.tm.pars.k_sfw + (run.tm.pars.k_pyrdeg + run.tm.pars.k_gypdeg) ;
else
    run.tm.pars.k_silw         = run.tm.pars.k17_oxidw - (run.tm.pars.k2_mocb + run.tm.pars.k5_locb - run.tm.pars.k13_ocdeg) + run.tm.pars.k12_ccdeg - run.tm.pars.k_sfw ;
end
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
