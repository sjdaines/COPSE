function D = copse_marinebiota_reloaded(pars, tmodel, S, D )
%COPSE_MARINEBIOTA COPSE marine ecosystem model
%  

%%%% convert marine nutrient reservoir moles to micromoles/kg concentration
D.Pconc = ( S.P/pars.P0 ) * 2.2 ;
D.Nconc = ( S.N / pars.N0 ) * 30.9 ;

%%%%% Marine new production
D.newp = 117 * min(D.Nconc/16,D.Pconc) ;

%%%%%% OCEAN ANOXIC FRACTION
switch pars.f_anoxia
    case 'original'
        D.ANOX = max( 1 - pars.k1_oxfrac*( D.pO2PAL)*( pars.newp0/D.newp ) , 0 );
    case 'newanoxia'
        D.ANOX = 1/(1 + exp(-pars.k_logistic*(pars.k_uptake*(D.newp/pars.newp0)-(D.pO2PAL))));
    otherwise
        error('unrecognized f_anoxia %s',pars.f_anoxia);
end

%%%% CP ratio
switch pars.f_CPsea
    case 'Fixed'
        D.CPsea = pars.CPsea0;
    case 'VCI'  % NB typo in Bergman (2004) has dependency reversed
        D.CPsea = pars.f_CPsea_VCI_oxic*pars.f_CPsea_VCI_anoxic / ((1-D.ANOX)*pars.f_CPsea_VCI_anoxic + D.ANOX*pars.f_CPsea_VCI_oxic);
    otherwise
        error('unrecognized f_CPsea %s',pars.f_CPsea);
end

%%%%% nitrogen cycle
if (S.N/16) < S.P
    D.nfix = pars.k3_nfix *( ( S.P - (S.N/16)  ) / (  pars.P0 - (pars.N0/16)    ) )^pars.f_nfix_power ;
else
    D.nfix = 0;
end

% Denitrification 
switch pars.f_denit
    case 'original'  % NB: COPSE 5_14 uses copse_crash to limit at low N
        D.denit = pars.k4_denit * ( 1 + ( D.ANOX / (1-pars.k1_oxfrac) )  )*copse_crash(S.N/pars.N0,'denit',tmodel) ;
    case 'new'  % Introduce dependence on [NO3] throughout
        D.denit = pars.k4_denit * ( 1 + ( D.ANOX / (1-pars.k1_oxfrac) )  )*(S.N/pars.N0) ;
    otherwise
            error('unrecognized f_denit %s',pars.f_denit);
end

end

