function D = copse_landbiota_reloaded(pars, tmodel, S, D, TEMP )
% COPSE_LANDBIOTA COPSE OCT dynamic land vegetation model 

%%%% effect of temp on VEG
D.V_T = 1 - (( (TEMP - paleo_const.k_CtoK-25)/25 )^2) ;
   
%%%% effect of CO2 on VEG
P_atm = D.pCO2atm*1e6 ;
P_half = 183.6 ;
P_min = 10 ;
D.V_co2 = (P_atm - P_min) / (P_half + P_atm - P_min) ;
% Berner choice
D.V_co2_b = 2*D.pCO2PAL / (1.0 + D.pCO2PAL) ;
% New option
D.V_co2_new = D.pCO2PAL^0.5 ;

%%%% effect of O2 on VEG 
D.V_o2 = 1.5 - 0.5*D.pO2PAL ;

%%%% full VEG limitation
switch pars.f_npp
    case 'original'
        D.V_npp = 2*D.EVO*D.V_T*D.V_o2*D.V_co2 ;
    case 'noT'
        D.V_npp = 2*D.EVO*0.84*D.V_o2*D.V_co2 ;
    case 'noO2'
        D.V_npp = 2*D.EVO*D.V_T*1.0*D.V_co2 ;
    case 'noCO2'
        D.V_npp = 2*D.EVO*D.V_T*D.V_o2*0.5952381 ;
    case 'bernerCO2'
        D.V_npp = D.EVO*(D.V_T/0.84)*D.V_o2*D.V_co2_b ;
    case 'newCO2'
        D.V_npp = D.EVO*(D.V_T/0.84)*D.V_o2*D.V_co2_new ;
    case 'constant'
        D.V_npp = D.EVO ;
    otherwise
        error('Unknown f_npp %s',pars.f_npp);
end

%%% fire feedback
%calculate atmospheric mixing ratio of O2 (for constant atmospheric N etc!)
%(only used for fire ignition probability)
D.mrO2 = D.pO2PAL  /   ( D.pO2PAL  +pars.k16_PANtoO ) ;
switch pars.f_ignit
    case 'original'
        D.ignit = max(586.2*(D.mrO2)-122.102 , 0  ) ;
    case 'bookchapter'
        %%% TML new fn. based on data for fuel of 10% moisture content
        D.ignit = min(max(48.0*(D.mrO2)-9.08 , 0  ) , 5  ) ;
    case 'nofbk'
        D.ignit = 1.0 ;
    otherwise
        error('Unknown f_ignit %s',pars.f_ignit);
end
D.firef = D.fireforcing*pars.k_fire/(D.fireforcing*pars.k_fire - 1 + D.ignit) ;

%%% Mass of terrestrial biosphere
D.VEG = D.V_npp * D.firef ;


end

