function copse_f_T = copse_f_T(Tk)
% COPSE_F_T Temperature dependence of silicate weathering from COPSE (Bergman 2004)
%
% Tk   - Temperature (Kelvin)
% f_T  - weathering rate relative to Tzero = 15 C
%
% See also COPSE_equations GEOCARB_equations test_copse_weathering

    CtoK = 273.15;
    Tzero = CtoK+15;
    copse_f_T = exp(0.09*(Tk-Tzero)) * ( (1 + 0.038*(Tk - Tzero))^0.65 );
end
