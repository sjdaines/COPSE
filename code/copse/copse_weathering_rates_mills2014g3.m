function D = copse_weathering_rates_mills2014g3(pars, tmodel, S, D ) 
 
 
%%% weathering kinetics 
switch pars.f_act_energies 
    case 'single' 
        %%%% use same activation energy for granite and basalt  
        D.f_T_gran = exp(0.09*(D.TEMP-288.15)) ; 
        D.f_T_bas = exp(0.09*(D.TEMP-288.15)) ; 
    case 'split_bug_g32014_Toffset'
        %%%% Mills G3 2014 paper used 288, results in ~1% offset in pCO2
        D.f_T_gran = exp(0.0724*(D.TEMP-288)) ; %%% 50 kJ/mol 
        D.f_T_bas = exp(0.0608*(D.TEMP-288)) ; %%% 42 kJ/mol 
    case 'split' 
        %%%% revert to 288.15 
        D.f_T_gran = exp(0.0724*(D.TEMP-288.15)) ; %%% 50 kJ/mol 
        D.f_T_bas = exp(0.0608*(D.TEMP-288.15)) ; %%% 42 kJ/mol 
    otherwise 
        error('unrecognized f_act_energies %s', pars.f_act_energies);                     
end 


%%% activation energy for apatite (decide whether to use it in _fluxes) 
D.f_T_ap = exp(0.0507*(D.TEMP-288.15)) ; %%% 35 kJ/mol 

 
%%% runoff temperature dependence 
D.f_T_runoff = ( (1 + 0.038*(D.TEMP - 288.15))^0.65 ) ; 
D.g_T_runoff = 1 + 0.087*(D.TEMP - 288.15) ; 

 
%%% CO2 dependence 
D.f_CO2_abiotic = D.pCO2PAL^0.5 ; 
switch(pars.f_co2fert) 
     case 'original' 
         D.f_CO2_biotic = ( 2*D.pCO2PAL / (1 + D.pCO2PAL) )^0.4 ; 
     case 'geocarb3' 
         D.f_CO2_biotic = ( 2*D.pCO2PAL / (1 + D.pCO2PAL) ) ; 
     case 'off' 
         D.f_CO2_biotic = 1.0 ; 
     otherwise 
         error('Unknown f_co2fert %s',pars.f_co2fert); 
end 
 
 
%%% O2 dependence 
switch(pars.f_oxwO) 
      case 'PowerO2'   % Copse 5_14 base with f_oxw_a = 0.5 
          D.oxw_fac = D.pO2PAL^pars.f_oxw_a; 
      case 'SatO2' 
          D.oxw_fac = D.pO2PAL/(D.pO2PAL + pars.f_oxw_halfsat); 
      case 'IndepO2' 
          D.oxw_fac = 1; 
      otherwise 
          error('Unknown f_foxwO %s',pars.f_oxwO); 
end 
 
 
%%% vegetation dependence 
switch(pars.f_vegweath) 
     case 'original' 
         D.VWmin = min(D.VEG*D.W,1); 
         D.f_co2_gran = D.f_T_gran*D.f_T_runoff*(D.f_CO2_abiotic*(1 - D.VWmin) + D.f_CO2_biotic*D.VWmin) ; 
         D.f_co2_bas = D.f_T_bas*D.f_T_runoff*(D.f_CO2_abiotic*(1 - D.VWmin) + D.f_CO2_biotic*D.VWmin) ; 
         D.f_co2_ap = D.f_T_ap*D.f_T_runoff*(D.f_CO2_abiotic*(1 - D.VWmin) + D.f_CO2_biotic*D.VWmin) ; 
         D.g_co2 = D.g_T_runoff*(D.f_CO2_abiotic*(1 - D.VWmin) + D.f_CO2_biotic*D.VWmin) ; 
         D.w_plantenhance = (  pars.k15_plantenhance  + (1-pars.k15_plantenhance)*D.W*D.VEG  ); 
         %combining plant and other effects on rates 
         D.f_gran = D.w_plantenhance *D.f_co2_gran ; 
         D.f_bas = D.w_plantenhance *D.f_co2_bas ; 
         D.f_ap = D.w_plantenhance *D.f_co2_ap ; 
         D.f_carb = D.w_plantenhance*D.g_co2 ;       
     case 'new' 
         D.Vmin = min(D.VEG,1);      
         D.f_gran = D.f_T_gran*D.f_T_runoff*((1-D.Vmin)*pars.k15_plantenhance*D.f_CO2_abiotic + D.VEG) ; 
         D.f_bas = D.f_T_bas*D.f_T_runoff*((1-D.Vmin)*pars.k15_plantenhance*D.f_CO2_abiotic + D.VEG) ; 
         D.f_ap = D.f_T_ap*D.f_T_runoff*((1-D.Vmin)*pars.k15_plantenhance*D.f_CO2_abiotic + D.VEG) ; 
         D.f_carb = D.g_T_runoff*((1-D.Vmin)*pars.k15_plantenhance*D.f_CO2_abiotic + D.VEG) ; 
     case 'new2' 
         D.VWmin = min(D.VEG*D.W,1); 
         D.f_gran = D.f_T_gran*D.f_T_runoff*((1-D.VWmin)*pars.k15_plantenhance*D.f_CO2_abiotic + D.VEG*D.W) ; 
         D.f_bas = D.f_T_bas*D.f_T_runoff*((1-D.VWmin)*pars.k15_plantenhance*D.f_CO2_abiotic + D.VEG*D.W) ; 
         D.f_ap = D.f_T_ap*D.f_T_runoff*((1-D.VWmin)*pars.k15_plantenhance*D.f_CO2_abiotic + D.VEG*D.W) ; 
         D.f_carb = D.g_T_runoff*((1-D.VWmin)*pars.k15_plantenhance*D.f_CO2_abiotic + D.VEG*D.W) ; 
     case 'newnpp' 
         D.VWmin = min(D.V_npp*D.W,1); 
         D.f_gran = D.f_T_gran*D.f_T_runoff*((1-D.VWmin)*pars.k15_plantenhance*D.f_CO2_abiotic + D.V_npp*D.W) ; 
         D.f_bas = D.f_T_bas*D.f_T_runoff*((1-D.VWmin)*pars.k15_plantenhance*D.f_CO2_abiotic + D.V_npp*D.W) ; 
         D.f_ap = D.f_T_ap*D.f_T_runoff*((1-D.VWmin)*pars.k15_plantenhance*D.f_CO2_abiotic + D.V_npp*D.W) ; 
         D.f_carb = D.g_T_runoff*((1-D.VWmin)*pars.k15_plantenhance*D.f_CO2_abiotic + D.V_npp*D.W) ; 
     otherwise 
         error('Unknown f_vegweath %s',pars.f_vegweath); 
end 

end 

