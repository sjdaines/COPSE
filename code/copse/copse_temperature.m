function TEMP = copse_temperature( pars, tmodel, D, temp )
%COPSE_TEMPERATURE Calculate updated temperature
% NB: this is an iteratively improved temperature based on insolation, pCO2, and current temperature

%global pars;

%%%%%%% Temperature function:
switch pars.f_temp
    case 'CK1992'  % Caldeira and Kasting 1992 (variable albedo)
        %SD for legibility, moved this code to a function (no change in functionality)
        tempcorrect = 0.194; %%%% COPSE temp correction to 15C at present day
        TEMP=copse_TempCK1992(D.SOLAR, D.pCO2atm, temp)+tempcorrect;
    case 'CK1992fixalbedo'
        ALBEDO = 0.3;
        tempcorrect = 0.194; %%%% COPSE temp correction to 15C at present day
        TEMP=copse_TempCK1992(D.SOLAR, D.pCO2atm, temp, ALBEDO)+tempcorrect;
%     case 'mills2011' % mills2011 temp (fixed albedo)
%         ALBEDO = 0.3;
%         TEMP   =   ((   (D.SOLAR.*(1-ALBEDO))./(4.*(1-(0.773./2)).*5.67e-8)  ).^0.25)          +    0.1815.*(        0.2507.*((log10(D.pCO2atm)).^4)  +  3.9216.*((log10(D.pCO2atm)).^3) + 23.8113.*((log10(D.pCO2atm)).^2) + 83.4113.*((log10(D.pCO2atm))) + 131.6138        )   ; 
    case 'Berner'
        %TL note that this uses its own luminosity (implicitly)
        TEMP = paleo_const.k_CtoK + 15 + pars.k_c*log(D.pCO2PAL) + pars.k_l*tmodel/570e6;
    otherwise
         error('Unknown f_temp %s',pars.f_temp);
end

end

