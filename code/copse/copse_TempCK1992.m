function [ newT, albedo, Tgh, Teff ] = copse_TempCK1992( luminosity, pCO2atm, oldT, fixedalbedo )
% COPSE_TEMPCK1992 Caldeira and Kasting 1992 temperature function
%
% [ newT, albedo, Tgh, Teff ] = copse_TempCK1992( luminosity, pCO2atm, oldT, fixedalbedo )
%
%   luminosity   - solar luminosity, W/m^2 (currently 1368.0)
%   CO2atm          - atmospheric pCO2, atm (pre-industrial 280e-6)
%   oldT         - estimated temperature
%   fixedalbedo  - (optional) fix albedo, default is variable albedo
%
%   newT         - improved estimate
%   albedo       - albedo
%   Tgh          - greenhouse contribution
%   Teff         - black-body effective temperature
%   fixedalbedo  - optional - fix albedo
%
% Caldeira, K., & Kasting, J. F. (1992). The life span of the biosphere revisited. Nature, 360(6406), 721–3. doi:10.1038/360721a0

CK_sigma = 5.67e-8; % Stefan-Boltzmann
CK_a0    = 1.4891;
CK_a1    = -0.0065979;
CK_a2    = 8.567e-6;
CK_1 = 815.17;
CK_2 = 4.895e+7;
CK_3 = -3.9787e+5;
CK_4 = -6.7084;
CK_5 = 73.221;
CK_6 = -30882;

if nargin < 4
    % calculate the effective black body temperature
    albedo = CK_a0 + CK_a1 * oldT + CK_a2 * oldT^2;
else
    albedo = fixedalbedo;
end

Teff = power((1-albedo) * luminosity / (4 * CK_sigma), 0.25);

% calculate the greenhouse effect */
psi = log10(pCO2atm);
Tgh = CK_1 + CK_2 / oldT^2 + CK_3 / oldT + CK_4 / psi^2 ...
    + CK_5 / psi + CK_6 / (psi * oldT);

% Final T is black body T + greenhouse effect

newT = Teff + Tgh;
 
% BM Matlab code - identical to above 
% tempcorrect = 0.194; %%%% COPSE temp correction to 15C at present day
% TEMP = (       (  ((1- (1.4891 - 0.0065979*S.temp + (8.567e-6)*(S.temp^2)  )  )*SOLAR)/(4*5.67e-8)  )^0.25...
%     +  815.17  + (4.895e7)*(S.temp^-2) -  (3.9787e5)*(S.temp^-1)...
%     -6.7084*((log10(  CO2atm  ))^-2) + 73.221*((log10(  CO2atm  ))^-1) -30882*(S.temp^-1)*((log10(  CO2atm ))^-1)     ) + tempcorrect ;

%%%%%%% CK1992 fixed albedo
% 
% TEMP = (       (  ((1- ( ALBEDO )  )*D.SOLAR)/(4*5.67e-8)  )^0.25     +  815.17  + (4.895e7)*(S.temp^-2) -  (3.9787e5)*(S.temp^-1)  -6.7084*((log10(  D.pCO2atm  ))^-2) + 73.221*((log10(  D.pCO2atm  ))^-1) -30882*(S.temp^-1)*((log10(  D.pCO2atm ))^-1)     ) ;

end

