function D = copse_weathering_fluxes_reloaded(pars, tmodel, S, D )

           
            %%% silicate and carbonate weathering
                                 
            %%% granite and basalt weathering
            
            %%% granite weathering
            switch pars.f_gran_link_u
                case 'original'
                    D.granw = pars.k_granw*D.UPLIFT*D.PG*D.RHO * D.GRAN_AREA * D.f_gran ;
                case 'weak'
                    D.granw = pars.k_granw*(D.UPLIFT^0.33)*D.PG*D.RHO * D.GRAN_AREA * D.f_gran ;
                case 'none'
                    D.granw = pars.k_granw*D.PG*D.RHO * D.GRAN_AREA * D.f_gran ;
                otherwise
                    error('unrecognized f_gran_link_u %s', pars.f_gran_link_u);
            end
            %%% apatite associated with granite
            %D.granw_ap = pars.k_granw*D.UPLIFT*D.PG*D.RHO * D.GRAN_AREA * D.f_ap ;
            
            %%%% basw NOT linked to uplift in G3 model
            switch pars.f_bas_link_u
                case 'no'
                    D.basw = pars.k_basw*D.BA*D.PG*D.RHO* D.f_bas ;
                    %%% apatite associated with basalt
                    %D.basw_ap = pars.k_basw*D.BA*D.PG*D.RHO* D.f_ap ;
                case 'yes'
                    %%%% for bergman run link basw to uplift
                    D.basw = pars.k_basw*D.BA*D.UPLIFT*D.PG*D.RHO* D.f_bas ;
                    %%% apatite associated with basalt
                    %D.basw_ap = pars.k_basw*D.BA*D.UPLIFT*D.PG*D.RHO* D.f_ap ;
                case 'weak'
                    D.basw = pars.k_basw*D.BA*(D.UPLIFT^0.33)*D.PG*D.RHO* D.f_bas ;
                otherwise
                    error('unrecognized f_bas_link_u %s', pars.f_bas_link_u);
            end

            D.silw = D.granw + D.basw;

            %%% apatite associated with silicate weathering
            % does it follow its own kinetics? (or that of the host rock)
            switch pars.f_p_kinetics
                case 'no'
                    D.granw_ap = D.granw;
                    D.basw_ap = D.basw;
                case 'yes'
                    D.granw_ap = D.granw * (D.f_ap / D.f_gran);
                    D.basw_ap = D.basw * (D.f_ap / D.f_bas);
                otherwise
                    error('unrecognized f_p_kinetics %s', pars.f_p_kinetics);
            end
            
            % is the P content assumed to vary between granite and basalt?
            switch pars.f_p_apportion
                case 'no'
                    D.silw_ap = D.granw_ap + D.basw_ap;
                case 'yes'
                    D.silw_ap = (pars.k_P*D.granw_ap + D.basw_ap)/(pars.k_P*(1-pars.k_basfrac)+pars.k_basfrac);
                otherwise
                    error('unrecognized f_p_apportion %s', pars.f_p_apportion);
            end
            
            D.phosw_s = D.F_EPSILON*pars.k10_phosw*pars.k_Psilw*(D.silw_ap/(pars.k_silw + realmin)) ; % trap 0/0 if k_silw = 0
            
            %%% carbonate weathering        
            switch pars.f_carb_link_u
                case 'yes'
                    D.carbw_fac = D.UPLIFT*D.PG*D.RHO* D.CARB_AREA * D.f_carb ;
                case 'no'
                    D.carbw_fac = D.PG*D.RHO* D.CARB_AREA * D.f_carb ;
                otherwise
                    error('Unknown f_carb_link_u %s', pars.f_carb_link_u);
            end
            
            switch(pars.f_carbwC)
                case 'Cindep'   % Copse 5_14
                    D.carbw = pars.k14_carbw*D.carbw_fac;
                case 'Cprop'    % A generalization for varying-size C reservoir
                    D.carbw = pars.k14_carbw*D.carbw_fac*D.normC;
                otherwise
                    error('Unknown f_carbw %s',pars.f_carbwC);
            end
            
            %%%% Oxidative weathering
            
            % C oxidative weathering

            %%% not affected by PG in G3 paper...
            switch(pars.f_oxwG)
                case 'O2indep'
                    D.oxidw = pars.k17_oxidw*D.UPLIFT *D.normG ;
                case 'Gindep'
                    D.oxidw = pars.k17_oxidw*D.UPLIFT *D.oxw_fac ;
                case 'Gprop'
                    D.oxidw = pars.k17_oxidw*D.UPLIFT * D.normG*D.oxw_fac ;
                case 'forced'
                    D.oxidw = pars.k17_oxidw*D.UPLIFT*D.ORG_AREA * D.normG*D.oxw_fac ;
                otherwise
                    error('Unknown f_oxwG %s',pars.f_oxwG);
            end
                    
            % Sulphur weathering
            switch(pars.Scycle)
                case 'Enabled'
                    switch(pars.f_gypweather)
                        case 'original' % Gypsum weathering tied to carbonate weathering
                            D.gypw = pars.k22_gypw*D.normGYP*D.carbw_fac ;
                        case 'alternative' %independent of carbonate area
                            D.gypw = pars.k22_gypw*D.normGYP*D.UPLIFT*D.PG*D.RHO*D.f_carb ;
                        case 'forced' %dependent on evaporite area
                            D.gypw = pars.k22_gypw*D.normGYP*D.EVAP_AREA*D.UPLIFT*D.PG*D.RHO*D.f_carb ;
                        otherwise
                            error('unknown f_gypweather %s',obj.pars.f_gypweather);
                    end
                    % Pyrite oxidative weathering 
                    switch(pars.f_pyrweather)
                        % with same functional form as carbon
                        case 'copse_O2' %not tied to PG in G3 paper...
                            D.pyrw = pars.k21_pyrw*D.UPLIFT*D.normPYR*D.oxw_fac  ;
                        case 'copse_noO2'    % independent of O2
                            D.pyrw = pars.k21_pyrw*D.UPLIFT*D.normPYR  ;
                        case 'forced' %forced by exposed shale area
                            D.pyrw = pars.k21_pyrw*D.UPLIFT*D.SHALE_AREA*D.normPYR  ;
                        otherwise
                            error('unknown f_pyrweather %s',obj.pars.f_pyrweather);
                    end
                case 'None'
                    D.gypw = 0;
                    D.pyrw = 0;
                otherwise
                    error('unrecogized pars.Scycle %s',pars.Scycle);
            end
            
            
            
            %%%%%%% P weathering 
            % D.phosw_s is defined above

            % Introduction of P weathering flux from sandstones etc
            D.sedw = D.UPLIFT*D.PG*D.RHO*D.VEG;
            D.phosw_x = D.F_EPSILON*pars.k10_phosw*pars.k_Psedw*D.sedw;
            
            D.phosw_c = D.F_EPSILON*pars.k10_phosw*pars.k_Pcarbw*(D.carbw/(pars.k14_carbw + realmin));
            D.phosw_o = D.F_EPSILON*pars.k10_phosw*pars.k_Poxidw*(D.oxidw/(pars.k17_oxidw + realmin))  ; % trap 0/0 if k17_oxidw = 0
            D.phosw   = D.phosw_s + D.phosw_c + D.phosw_o + D.phosw_x;

end
