function handled=copse_plot_sfbw( wplot, XT, XTlimits,tiplot, plotdata,cdata )
% Additional / modified figures for seafloor weathering inclusion
%
%   wplot           requested plot (string)
%   XT              model output:  x axis (usually time in yr) (vector)
%   XTlimits        requested x-axis limits, yr (eg [-500e8 0] )
%   tiplot          (not used) time indices to plot
%   plotdata        model output with fields S, diag, pars
%   cdata      (optional) COPSE 5_14 output to compare against
%
%   handled         1 if we have a handler for requested plot, 0 otherwise

%do we have output to compare against?
if nargin > 5
    outputcompare = 1;
else
    outputcompare = 0;
end

%%%% load the custom colours
cols = copse_plot_custom_colors ;
    
% Unpack supplied data
diag=plotdata.diag;
S=plotdata.S;

%Assume we can handle this plot unless we discover otherwise
handled = 1;

switch(char(wplot))

    
    case 'Srconc'
        %%%%% plot against G3 output if it exists
        if outputcompare  && isfield(cdata.S,'Sr_ocean') 
            plot(cdata.T, cdata.S.Sr_ocean*10, 'color', cols.light_b)
            hold on
        end
        if outputcompare  && isfield(cdata.S,'Sr_sed') 
            plot(cdata.T, cdata.S.Sr_sed, 'color', cols.light_k)
            hold on
        end  
        %%%% plot this model output
        plot (XT, S.Sr_ocean*10,'b','displayname','Sr ocean')
        hold on
        plot (XT, S.Sr_sed,'k','displayname','Sr sed')
        title('[Sr]*10 ocean (b) and sed (k)','FontWeight','bold')
        xlim(XTlimits)
        ylabel('Mol')
        
        

    case 'Srfluxes'
        %%%%% plot against G3 output if it exists
        if outputcompare  && isfield(cdata, 'T_Sr') && isfield(cdata.diag,'Sr_old_igw')
            plot(cdata.T_Sr, cdata.diag.Sr_old_igw, 'color', cols.light_r)
            hold on
        end
        if outputcompare  && isfield(cdata, 'T_Sr') && isfield(cdata.diag,'Sr_new_igw') 
            plot(cdata.T_Sr, cdata.diag.Sr_new_igw, 'color', cols.light_k)
            hold on
        end
        if outputcompare  && isfield(cdata, 'T_Sr') && isfield(cdata.diag,'Sr_sedw') 
            plot(cdata.T_Sr, cdata.diag.Sr_sedw, 'color', cols.light_c)
            hold on
        end
        if outputcompare && isfield(cdata, 'T_Sr') && isfield(cdata.diag,'Sr_mantle') 
            plot(cdata.T_Sr, cdata.diag.Sr_mantle, 'color', cols.light_m)
            hold on
        end
        if outputcompare && isfield(cdata, 'T_Sr') && isfield(cdata.diag,'Sr_sedb') 
            plot(cdata.T_Sr, cdata.diag.Sr_sedb, 'color', cols.light_b)
            hold on
        end
        if outputcompare && isfield(cdata, 'T_Sr') && isfield(cdata.diag,'Sr_sfw') 
            plot(cdata.T_Sr, cdata.diag.Sr_sfw, 'color', cols.light_g)
            hold on
        end
        if outputcompare && isfield(cdata, 'T_Sr') && isfield(cdata.diag,'Sr_metam') 
            plot(cdata.T_Sr, cdata.diag.Sr_metam, 'color', cols.light_m, 'linestyle', '--')
            hold on
        end

        %%%% plot this model output
        plot (XT, diag.Sr_old_igw,'r','displayname','Sr_old_igw')
        hold on
        plot (XT, diag.Sr_new_igw,'k','displayname','Sr_new_igw')
        plot (XT, diag.Sr_sedw,'c','displayname','Sr_sedw')
        plot (XT, diag.Sr_mantle,'m','displayname','Sr_mantle')
        plot (XT, diag.Sr_sedb,'b','displayname','Sr_sedb')
        plot (XT, diag.Sr_sfw,'g','displayname','Sr_sfw')
        plot (XT, diag.Sr_metam,'m','linestyle','--','displayname','Sr_metam')
        
        title('Sr fluxes: old ig (r), new ig (k), sedw (c), mantle (m), metam (m-), sedb (b), sfw (g)' ,'FontWeight','bold')
        xlim(XTlimits)
        ylabel('Mol/yr')
        
      
        
    case 'Srfrac'
        %%%%% plot against G3 output if it exists
        if outputcompare  && isfield(cdata.diag,'delta_Sr_ocean') 
            plot(cdata.T, cdata.diag.delta_Sr_ocean, 'color', cols.light_b)
            hold on
        end
        if outputcompare && isfield(cdata, 'T_Sr_sed') && isfield(cdata.diag,'delta_Sr_sed') 
            plot(cdata.T_Sr_sed, cdata.diag.delta_Sr_sed, 'color', cols.light_k)
            hold on
        end     
        %%%% plot this model output
        plot (XT, diag.delta_Sr_ocean,'b','displayname','8786Sr ocean')
        hold on
        plot (XT, diag.delta_Sr_sed,'k','displayname','8786Sr sed')
        plot (XT, diag.delta_igw,'r','displayname','8786Sr river')
        plot (XT, diag.delta_old_ig,'r--','displayname','8786Sr old ig')
        plot (XT, diag.delta_new_ig,'r:','displayname','8786Sr new ig')
        plot (XT, diag.delta_mantle,'m','displayname','8786Sr mantle')
        title('8786Sr ocean (b), sed (k), igw (r), old ig (r--), new ig (r:), mantle (m)','FontWeight','bold')
        xlim(XTlimits)
        ylim([0.702 0.716])
        ylabel('8786Sr')       

   case 'SrfracDiff'
        %Difference between this run and comparison output
        %Interpolate onto tcomp grid for comparison
        
        if outputcompare && isfield(cdata.diag, 'delta_Sr_ocean')
            [ tcomp, dSrdiff, dSrrms ] = copse_diff(XTlimits, 'diff', cdata.T, cdata.diag.delta_Sr_ocean, XT, diag.delta_Sr_ocean);
            dSr_comparison = true;
        else
            tcomp = [];
            dSrdiff = [];
            dSrrms = NaN;
            dSr_comparison = false;
        end
        
        plot(tcomp, dSrdiff,'r')
    
        fprintf('RMS error (8786Sr ocean - comparison model) %g\n',dSrrms);
        if dSr_comparison
            title({'8786Sr ocean - comparison model)';sprintf('RMS Error %g',dSrrms)},'FontWeight','bold')
        else
            title('No 8786Sr ocean comparison data','FontWeight','bold')
        end
        
        xlim(XTlimits)
        ylabel('diff 8786Sr');   
        
   case 'Pcrust'
        %%%% plot this model output
        semilogy(XT, S.OrgP,'b','displayname','OrgP')
        hold on
        semilogy(XT, S.CaP,'k','displayname','CaP')
        hold on
        semilogy(XT, S.FeP,'r','displayname','FeP')
        title({'Sedimentary P reservoirs (mol)';'b:OrgP, k:CaP, r:FeP'},'FontWeight','bold')
        xlim(XTlimits)
        ylabel('mol')
 
        
    case 'oxygen'
        if outputcompare && isfield(cdata.diag,'pO2PAL')
            plot(cdata.T, cdata.diag.pO2PAL, 'color', cols.grey)
            hold on
        end
        %%%% plot this model output
        plot(XT,diag.pO2PAL,'k')
        hold on
        title('pO2 (PAL)','FontWeight','bold')
        xlim(XTlimits)
        ylabel('Normalized value');     
        
    case 'CPWeath'
        if outputcompare  && isfield(cdata.diag,'silw') 
            %%%% plot against COPSE output
            plot(cdata.T, cdata.diag.silw, 'color', cols.light_c)
            hold on
        end
        if outputcompare && isfield(cdata.diag,'carbw') 
             plot(cdata.T, cdata.diag.carbw, 'color', cols.light_g)
             hold on
        end
        if outputcompare && isfield(cdata.diag,'oxidw')
            plot(cdata.T, cdata.diag.oxidw, 'color', cols.light_r)
        end
        if outputcompare &&  isfield(cdata.diag,'phosw')
            plot(cdata.T, cdata.diag.phosw*100, 'color', cols.light_b)
        end
        %%%% plot this model output
       
        plot(XT,diag.silw,'c--')
        hold on
        plot(XT,diag.carbw,'g')
        plot(XT,diag.oxidw,'r')
        plot(XT,diag.phosw*100,'b')
        if isfield(diag,'sfw')
            plot(XT,diag.silw+diag.sfw,'c')
            plot(XT,diag.sfw,'m--')
            title({'CP Weathering';'r:oxidw, c:silw+sfw, c-:silw m-:sfw, g:carbw, b:phosw x100'},'FontWeight','bold')
        else
            title({'CP Weathering';'r:oxidw, c-:silw (no sfw), g:carbw, b:phosw x100'},'FontWeight','bold')
        end
        xlim(XTlimits)
        ylabel('Flux mol/yr')

    
    case 'SFW'
        
        %%%% plot the G3 results average to compare (test code)
        if outputcompare
            if isfield(cdata.diag, 'sfw')
            plot(cdata.T,cdata.diag.sfw,'Color',cols.light_b)
            end
        hold on
        plot(cdata.T,cdata.diag.silw,'Color',cols.light_g)
        if isfield(cdata.diag, 'granw')
        plot(cdata.T,cdata.diag.granw,'Color',cols.light_r)
        end
        if isfield(cdata.diag, 'basw')
        plot(cdata.T,cdata.diag.basw,'Color',cols.light_k)
        end
        end
        
        %%%% plot this model output
        plot(XT,diag.sfw,'b','displayname','SFW')
        hold on
        plot(XT,diag.silw,'g','displayname','silw')
        plot(XT,diag.granw,'r','displayname','granw')
        plot(XT,diag.basw,'k','displayname','basw')
        xlim(XTlimits)
        ylabel('weathering (mol/yr)')
        title({'Silicate weathering';'SFW(b) silw(g) granw(r) basw(k)'},'FontWeight','bold')
        
        

    case 'BasaltArea'
        
        %%%% plot the G3 results average to compare (test code)
        if outputcompare && isfield(cdata.diag, 'CFB_area')
            plot(cdata.T,cdata.diag.CFB_area,'Color',cols.light_r)
            hold on
        end
        if outputcompare && isfield(cdata.diag, 'oib_area')
            plot(cdata.T,cdata.diag.oib_area,'Color',cols.light_b)
            hold on
        end        
        
        %%%% plot this model output
        sumba = 0;
        if isfield(diag, 'oib_area')
            plot(XT,diag.oib_area,'b','displayname','oib')
            hold on
            sumba = sumba+diag.oib_area;
        end
        if isfield(diag, 'CFB_area')
            plot(XT,diag.CFB_area,'r','displayname','cfb')
            sumba = sumba + diag.CFB_area;
        end
        plot(XT, sumba,'g','displayname','sum')
        
        xlim(XTlimits)
        ylabel('area (km^2)')
        title({'Basalt area OIB(b) CFB(r) sum(g)'},'FontWeight','bold')
   
    case 'CoalFrac'
        plot(XT,diag.COAL,'k')
        hold on
        title('Coal Forcing','FontWeight','bold')
        xlim(XTlimits)
        ylabel('Normalized value');     
        
    case 'SaltFrac'
        plot(XT,diag.SALT,'k')
        hold on
        title('Gypsum Deposition Forcing','FontWeight','bold')
        xlim(XTlimits)
        ylabel('Normalized value');     
        
    case 'EvapArea'
        plot(XT,diag.EVAP_AREA,'k')
        hold on
        title('Evaporite Forcing','FontWeight','bold')
        xlim(XTlimits)
        ylabel('Normalized value');     
       
    case 'OrgArea'
        plot(XT,diag.ORG_AREA,'k')
        hold on
        title('Shale+Coal Area Forcing','FontWeight','bold')
        xlim(XTlimits)
        ylabel('Normalized value');     
       
    case 'ShaleArea'
        plot(XT,diag.SHALE_AREA,'k')
        hold on
        title('Shale Area Forcing','FontWeight','bold')
        xlim(XTlimits)
        ylabel('Normalized value');     
       
    case 'SilicateArea'
        plot(XT,diag.GRAN_AREA,'k')
        hold on
        title('Weighted Silicate Forcing','FontWeight','bold')
        xlim(XTlimits)
        ylabel('Normalized value');         
       
   case 'LIPCO2'
        %%%% plot this model output
        plot(XT,diag.LIP_CO2,'b','displayname','LIP_CO2')        
        xlim(XTlimits)
        ylabel('flux (mol C yr^{-1})')
        title({'LIP CO2'},'FontWeight','bold')

   case 'PhysForc'  % update (override) base version to add BA forcing
        %%%% also add carbonate land area
        %%%% plot this model output
        lgds = {};
        if isfield(diag, 'SOLAR')
            plot(XT,diag.SOLAR./1368,'r'); lgds{end+1} = 'SOLAR';
            hold on
        end
        plot(XT,diag.CARB_AREA,'c'); lgds{end+1} = 'CARB_AREA';
        hold on
        plot(XT,diag.TOTAL_AREA,'k--'); lgds{end+1} = 'TOTAL_AREA';
        plot(XT,diag.BA,'k'); lgds{end+1} = 'BA';
        plot(XT,diag.GRAN_AREA,'r--'); lgds{end+1} = 'GRAN AREA';
        plot(XT,diag.UPLIFT,'b'); lgds{end+1} = 'UPLIFT';
        plot(XT,diag.DEGASS,'g'); lgds{end+1} = 'DEGASS';
        plot(XT,diag.PG,'b--'); lgds{end+1} = 'PG';
        
        h=legend(lgds);
        set(h,'FontSize',6,'Location','SouthWest');
        legend boxoff;
        title('Phys Forcings','FontWeight','bold')
        xlim(XTlimits)
        ylim([0 2.1]);
        ylabel('Relative strength')
    otherwise
        handled = 0;
end

end

