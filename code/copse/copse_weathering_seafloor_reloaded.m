function D = copse_weathering_seafloor_reloaded(pars, tmodel, S, D )
% Seafloor weathering flux

% Tectonic forcing
% D.RHOSFW is a hook to apply perturbations for sensitivity studies (usually = 1)
switch pars.f_sfw_force
    case 'None'
        force_sfw = D.RHOSFW * 1;
    case 'DEGASS'  
        force_sfw = D.RHOSFW *D.DEGASS;
    case 'MetRip'
        force_sfw = D.RHOSFW *D.DEGASSrip;
    otherwise
        error('unknown f_sfw_force %s', pars.f_sfwforce);
end


% Temperature / CO2 dependence
% NB: two temperature-based functions are _very_ similar 
switch pars.f_sfw_opt
    case 'mills2014pCO2'   % Mills (2014) PNAS 10.1073/pnas.1321679111
        f_sfw = (D.pCO2PAL^pars.f_sfw_alpha) ;
        
    case 'sfw_Tbotw' % Stuart sfw function for ox weath model
        % normalised to bottom-water temperature (global TEMP(in C) - 12.5)
        D.TbotwC = max(D.GLOBALT - paleo_const.k_CtoK - 12.5, 0);  % from S&G high-lat T = 2.5C for Temp = 15C, don't go below freezing
        
        f_sfw = exp(0.066*(D.TbotwC - 2.5));  % activation energy 41 kJ mol^{-1}
        % NB: oxweath had normalisation error, gave f_sfw = exp(0.165) = 1.18 for present day TEMP = 15C
        
    case 'sfw_temp' % Josh Improved sfw function considering temperature
        f_sfw =  exp(0.0608*(D.GLOBALT-288))  ; %%% 42KJ/mol activation energy assumed as with terrestrial basalt
      
    case 'sfw_strong' % Coogan&Dosso 92 kJ/mol apparent activation energy
        f_sfw =  exp(0.1332*(D.GLOBALT-288.15))  ;
        
    case 'sfw_noT' % No temperature dependence
        f_sfw =  1.0  ;
        
    otherwise
        error('unrecognized pars.f_sfw_opt %s',pars.f_sfw_opt);
end
            

%%%% calculate relative rate of seafloor weathering (give zero if k_sfw is zero)
if pars.k_sfw == 0
    D.sfw_relative = 0 ;
else    
    D.sfw_relative =   force_sfw * f_sfw;
end
D.sfw = pars.k_sfw  * D.sfw_relative ;
            
end

