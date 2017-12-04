function [ d_locb, D_P, d_mocb, D_B, d_mccb, d_ocean, d_atmos ] = copse_Cisotopefrac( Tkelvin, pCO2PAL, pO2PAL, phi )
% COPSE_CISOTOPEFRAC Carbon isotope fractionation from Bergman(2004) COPSE model

if nargin < 4
    phi = 0.01614;  %fraction of C in atmosphere:ocean
end

%ocean total dissolved CO2
d_ocean = phi*(9483/Tkelvin-23.89);
%atmosphere CO2
d_atmos = (phi-1)*(9483/Tkelvin-23.89);

%marine calcite burial
d_mccb = d_ocean + 15.10 - 4232/Tkelvin;

%fractionation between marine organic and calcite burial
D_B = 33 -9/sqrt(pCO2PAL) + 5*(pO2PAL-1);
%marine organic carbon burial
d_mocb = d_mccb - D_B;

%fractionation between terrestrial organic burial and atmospheric CO2
D_P = 19 + 5*(pO2PAL-1);
d_locb = d_atmos - D_P;
end

