classdef paleo_const
    % Global constant values
    
    properties(Constant)
        % Define model time offset (user preference - all code should obey this)
        time_present_yr     = 0;        % model time at present epoch
        
        %%%% Physical constants
        k_CtoK              = 273.15;   %  convert degrees C to Kelvin
        k_Rgas              = 8.3144621 % J/K/mol gas constant
        k_molVolIdealGas    = 22.4136;  % l/mol  molar volume of ideal gas at STP (0C, 1 atm) 
        
        % Earth system present-day parameters
        k_solar_presentday  = 1368;    % present-day solar insolation W/m^2
        k_secpyr            = 3.15569e7;%present-day seconds per year
        k_daypyr            = paleo_const.k_secpyr/(24*3600);  % days in a year
         
        k_moles1atm         = 1.77e20; % Moles in 1 atm
               
        k_preindCO2atm      = 280e-6;   %  

        % Atmospheric composition from Sarmiento & Gruber (2006) Table 3.1.1 (which cites Weast & Astle 1982)
        k_atmmixrN2         = 0.78084;  % N2 atmospheric mixing ratio (moles / moles dry air)
        k_atmmixrO2         = 0.20946;  % O2 atmospheric mixing ratio (moles / moles dry air)
    end
    
    
end

