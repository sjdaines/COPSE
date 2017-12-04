function g_T = copse_g_T(Tk)
% COPSE_G_T  Temperature dependence of carbonate weathering from COPSE (Bergman 2004)
%
% Tk   - Temperature (Kelvin)
% g_T  - weathering rate relative to Tzero = 15 C
% NB: will go negative to T <~ 5C !!
%
% See also COPSE_equations GEOCARB_equations test_copse_weathering

    CtoK = 273.15;
    Tzero = CtoK+15;
    
    g_T= 1 + 0.087*(Tk - Tzero);
    if g_T < 0
        fprintf('negative g_T %g for Tk %g\n',g_T,Tk);
        g_T = 0;
    end
end