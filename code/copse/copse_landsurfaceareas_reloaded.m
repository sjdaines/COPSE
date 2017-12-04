function D = copse_landsurfaceareas_reloaded( pars, tmodel, S, D )
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
        
    case 'Forced'
        % Forced by input file from copse_force_granite
        D.GRAN_AREA = D.GRAN ;
        
    case 'ShaleForced'
        % Forced by weighted contributions of siliceous and shale+coal
        % areas to overall non-basalt silicate weathering flux
        D.GRAN_AREA = (1-pars.k_shalefrac)*D.GRAN + pars.k_shalefrac*D.ORG_AREA ;
        
    case 'OrgEvapForced'
        % Forced by weighted contributions of siliceous and shale+coal
        % areas to overall non-basalt silicate weathering flux
        D.GRAN_AREA = (1-pars.k_orgevapfrac)*D.GRAN + pars.k_orgevapfrac*D.ORGEVAP_AREA ;
        
    case 'G3improved'
        
        %%%% uses same calc as for present day areas
        %%%%  calc for: granite_area = land_area - carbonate_area - total_basalt ;
        granite_area = ( pars.k_present_land_area * D.TOTAL_AREA ) - ( pars.k_present_carbonate_area * D.CARB_AREA ) - ( pars.k_present_basalt_area * D.BA ) ;
        D.GRAN_AREA = granite_area / pars.k_present_granite_area ;
        
    otherwise
        error('unrecognized f_granitearea %s',pars.f_granitearea);
end


end

