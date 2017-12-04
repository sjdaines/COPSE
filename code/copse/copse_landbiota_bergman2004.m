function D = copse_landbiota_bergman2004(pars, tmodel, S, D, TEMP )
%COPSE_LANDBIOTA COPSE OCT dynamic land vegetation model
% 

%global pars;

%%%% effect of temp on VEG

D.V_T = 1 - (( (TEMP - paleo_const.k_CtoK-25)/25 )^2) ;
  
% 
%%%% effect of CO2 on VEG
P_atm = D.pCO2atm*1e6 ;
P_half = 183.6 ;
P_min = 10 ;
D.V_co2 = (P_atm - P_min) / (P_half + P_atm - P_min) ;

%%%% effect of O2 on VEG 
D.V_o2 = 1.5 - 0.5*D.pO2PAL ;

%%%% full VEG limitation
D.V_npp = 2*D.EVO*D.V_T*D.V_o2*D.V_co2 ;

%%% fire feedback
%calculate atmospheric mixing ratio of O2 (for constant atmospheric N etc!)
%(only used for fire ignition probability)
D.mrO2 = D.pO2PAL  /   ( D.pO2PAL  +pars.k16_PANtoO ) ;
D.ignit = max(586.2*(D.mrO2)-122.102 , 0  ) ;
D.firef = pars.k_fire/(pars.k_fire - 1 + D.ignit) ;


%%% Mass of terrestrial biosphere
D.VEG = D.V_npp * D.firef ;


end

