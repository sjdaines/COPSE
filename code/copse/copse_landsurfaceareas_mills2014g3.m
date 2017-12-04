function D = copse_landsurfaceareas_mills2014g3( pars, tmodel, S, D )
% Calculate relative basalt, granite, and carbonate areas
%
% Areas are relative to present-day, and 
% are "absolute" ie no further normalisation to total land area is used.
% Can be supplied by forcing files (preferred)
% or can be derived as in Mills(2014) G3 paper

% Basalt area relative to present day
switch(pars.f_basaltarea)

    case {'DefaultForced','g3_2014_datafile'}
        % D.BA defined by forcing eg copse_force_revision_ba
        % or left at default D.BA=1
    
    case 'g3_2014_construct_from_lips'
        D.BA    = (D.CFB_area + D.oib_area) / pars.k_present_basalt_area;
        %case 'Constant'
        % leave as constant
    
    otherwise
        error('unknown f_basaltarea %s',pars.f_basaltarea);
end


%%%% relative area forcing for granites
switch pars.f_granitearea
    case 'Fixed'
        % D.GRAN_AREA set to 1
        D.GRAN_AREA = 1 ;        
        
    case 'G3original'
        
        %%%% old G3 calculation, uses only CFB area in historical calc
        land_area = pars.k_present_land_area * D.TOTAL_AREA ; %%% = present * relative forcing
        carbonate_area = pars.k_present_carbonate_area * D.CARB_AREA ; %%% = present * relative forcing
        total_basalt = pars.k_present_basalt_area * D.BA ; %%% = present * relative forcing
        continental_basalt_area = total_basalt - D.oib_area ;  %%%% in km^2 remove the OIB/IA part (provided by copse_force_vandermeer.m degassing)
        granite_area = land_area - carbonate_area - continental_basalt_area ; %%% SHOULD BE ALL BASALT PROBABLY
        
        D.GRAN_AREA = granite_area / pars.k_present_granite_area ;
        
    case 'G3improved'
        
        %%%% uses same calc as for present day areas
        %%%%  calc for: granite_area = land_area - carbonate_area - total_basalt ;
        granite_area = ( pars.k_present_land_area * D.TOTAL_AREA ) - ( pars.k_present_carbonate_area * D.CARB_AREA ) - ( pars.k_present_basalt_area * D.BA ) ;
        D.GRAN_AREA = granite_area / pars.k_present_granite_area ;
        
    otherwise
        error('unrecognized f_granitearea %s',pars.f_granitearea);
end


end

