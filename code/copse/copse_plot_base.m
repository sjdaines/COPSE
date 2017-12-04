function handled=copse_plot_base( wplot, XT, XTlimits,tiplot, plotdata,cdata )
% Plot a single results figure (COPSE 'classic' model)
%
% handled=copse_plot_base( wplot,XT, XTname, XTlimits, plotdata, compareC514 )
%
%   wplot           requested plot (string)
%   XT              model output:  x axis (usually time in yr) (vector)
%   XTlimits        requested x-axis limits, yr (eg [-500e8 0] )
%   tiplot          (not used) time indices to plot
%   plotdata        model output with fields S, diag, pars
%   cdata      (optional) COPSE 5_14 output to compare against
%
%   handled         1 if we have a handler for requested plot, 0 otherwise
%
% See also COPSE_plotlist COPSE_frontend

%do we have output to compare against?
if nargin > 5
    outputcompare = 1;
else
    outputcompare = 0;
end

% Unpack supplied data
diag        = plotdata.diag;
S           = plotdata.S;
pars        = plotdata.tm.pars;

cols = copse_plot_custom_colors ;

%Assume we can handle this plot unless we discover otherwise
handled = 1;

switch(char(wplot))
%   case 'MyNewPlot'
%       %%%% My new plot that explains everything
%       plot(XT,diag.mynewvariable,'r');
%       hold on
%       plot(XT,diag.myothervariable,'g');
%       title({'New plot';'line1 (r), line2 (g)'},'Fontweight','bold');
%       xlim(XTlimits);
        
    case 'PhysForc'
        %%%% plot this model output
        legends={};
        
        plot(XT,diag.SOLAR./1368,'r');
        legends{end+1} = 'SOLAR';
        hold on
        plot(XT,diag.CONTAREA,'k')
        legends{end+1} = 'CONTAREA';
        plot(XT,diag.UPLIFT,'b')
        legends{end+1} = 'UPLIFT';
        
        plot(XT,diag.RHO,'c')  % additional weatherability enhancement
        legends{end+1} = 'RHO';
        if isfield(diag,'RHOSIL')
            plot(XT,diag.RHOSIL,'m')  % additional silicate terrestrial weatherability enhancement
            legends{end+1} = 'RHOSIL';
        end
        if isfield(diag,'RHOSFW')
            plot(XT,diag.RHOSFW,'m--')  % additional sfw weathering enhancement
            legends{end+1} = 'RHOSFW';
        end
        plot(XT,diag.F_EPSILON,'c--') % additional nutrient weathering enhancement
        legends{end+1} = 'F_EPSILON';
        
        if isfield(diag,'DEGASSmet')  % division into met/arc volc and ridge-island-plume
            plot(XT,diag.DEGASSmet,'g')
            legends{end+1} = 'DEGASSmet';
            plot(XT,diag.DEGASSrip,'g--')
            legends{end+1} = 'DEGASSrip';              
        else  % COPSE 'classic'
            plot(XT,diag.DEGASS,'g')
            legends{end+1} = 'DEGASS';
        end
        h=legend(legends);
        set(h,'FontSize',6,'Location','SouthEast');
        legend boxoff;
        title('Phys Forcings','FontWeight','bold')
        xlim(XTlimits)
        ylim([0 2.1]);
        ylabel('Relative strength')
   case 'PerturbForc'
        %%%% plot this model output
        plot(XT,diag.co2pert,'g')
        hold on
        if isfield(diag,'carbwpert')
            plot(XT,diag.carbwpert,'b');
        end
        if isfield(diag,'silwpert')
            plot(XT,diag.silwpert,'m');
        end
        if isfield(diag,'O_Ppert')
            plot(XT,diag.O_Ppert*100,'c');
        end
        if isfield(diag,'mpsbpert')
            plot(XT,diag.mpsbpert,'k');
        end
        if isfield(diag,'O_SO2pert')
            plot(XT,diag.O_SO2pert,'y');
        end
        title({'Perturb Fluxes: REDOX(r), CO_2(g),carbw(b)';'silw(m) phos(c) mpsb(k) SO_2(y)'},'FontWeight','bold')
        xlim(XTlimits)
        ylabel('mol/yr (phos x100)')
    case 'EvolForc'
        %%%% plot this model output
        plot(XT,diag.EVO,'r')  %  land plant evolution
        hold on
        plot(XT,diag.W,'g')  %land plant enhancement of weathering
        plot(XT,diag.Bforcing,'b')  %deep carbonate burial
        
        h=legend('EVO','W','B');
        set(h,'FontSize',6,'Location','NorthWest');
        legend boxoff;
        title('Evol Forcings','FontWeight','bold')
        xlim(XTlimits)
        ylim([0 2.1]);
        ylabel('Relative strength')
        
    case 'O2'
        if outputcompare && isfield(cdata.diag,'pO2PAL')
            plot(cdata.T, cdata.diag.pO2PAL, 'color', cols.grey)
            hold on
        end
        if outputcompare && isfield(cdata.diag,'ANOX')
            plot(cdata.T, cdata.diag.ANOX, 'color', cols.light_g)
            hold on
        end
        %%%% plot this model output
        %%%% SD update to BM Matlab - PAL is proportional to S.O
        %%%% This fixes slightly high plotted pO2
        %plot(XT,diag.mrO2./(0.21),'k')
        plot(XT,diag.pO2PAL,'k')
        hold on
        if isfield(diag,'ANOX')
            plot(XT,diag.ANOX,'g')
        end
        title('pO2 PAL(k), anox (g)','FontWeight','bold')
        xlim(XTlimits)
        %xlabel ('Age (yr)')
        %ylim([1.0 1.6]);
        ylabel('Normalized value');
        %ylabel('pO2 (PAL)');
   case 'CH4'       
        plot(XT,diag.pCH4atm,'k')       
        title('pCH4 atm(k)','FontWeight','bold')
        xlim(XTlimits)
        ylabel('pCH4 (atm)');
   case 'H2S'       
        plot(XT,diag.pH2Satm,'k')       
        title('pH2S atm(k)','FontWeight','bold')
        xlim(XTlimits)
        ylabel('pH2S (atm)');
   case 'O2Diff'
        %Difference between this run and comparison output
        %Interpolate onto tcomp grid for comparison
        if outputcompare
            [ tcomp, pO2diff, rmsfepO2 ] = copse_diff(XTlimits, 'frac', cdata.T, cdata.diag.pO2PAL, XT, diag.pO2PAL);
        else
            tcomp = [];
            pO2diff = [];
            rmsfepO2 = NaN;
        end
    
        plot(tcomp, pO2diff,'r')
    
        fprintf('RMS frac error (pO2 - comparison model) %g\n', rmsfepO2);
        title({'pO2 PAL - comp';sprintf('RMS frac error %g',rmsfepO2)},'FontWeight','bold')
        xlim(XTlimits)
        ylabel('PAL');
        
    case 'CO2'
        if outputcompare && isfield(cdata.diag,'pCO2PAL') 
            %%%% plot against COPSE output
            plot(cdata.T, cdata.diag.pCO2PAL, 'color', cols.grey)
            hold on
        end
        %%%% plot this model output
        plot(XT,diag.pCO2PAL,'k')
        hold on
        title('CO_2','FontWeight','bold')
        xlim(XTlimits)
        ylabel('pCO_2 PAL')
        
    case 'CO2Diff'
        %Interpolate onto tcomp grid for comparison
        if outputcompare
            [ tcomp, pCO2diff, rmsfepCO2 ] = copse_diff(XTlimits, 'frac', cdata.T, cdata.diag.pCO2PAL, XT, diag.pCO2PAL);
        else
            tcomp = [];
            pCO2diff = [];
            rmsfepCO2 = NaN;
        end
        
        plot(tcomp, pCO2diff,'r')
    
        fprintf('RMS frac error (pCO2 - comparison model) %g\n', rmsfepCO2);
        
        title({'pCO2 - comparison model';sprintf('RMS frac error %g',rmsfepCO2)},'FontWeight','bold')
        xlim(XTlimits)
        ylabel('PAL');
        
        
    case 'Temp'
        if outputcompare && isfield(cdata.diag,'TEMP') 
            %%%% plot against COPSE output
            plot(cdata.T, cdata.diag.TEMP-paleo_const.k_CtoK, 'color', cols.grey)
            hold on
        end
        %%%% plot this model output
        plot (XT, diag.TEMP-paleo_const.k_CtoK,'k','displayname','temp')
        hold on
        title('Temperature (C)','FontWeight','bold')
        xlim(XTlimits)
        ylabel('Temp (C)')
        
    case 'OceanNP'
        if outputcompare && isfield(cdata.S,'P') && isfield(cdata.S,'N')
            %%%% plot against COPSE output
            plot(cdata.T, cdata.S.P/pars.P0,'color', cols.light_b);
            hold on
            plot(cdata.T, cdata.S.N/pars.N0, 'color', cols.light_g);
        end
        %%%% plot this model output
        plot(XT,S.P/pars.P0, 'color', 'b');
        hold on
        plot(XT,S.N/pars.N0, 'color', 'g');
        title('Ocean P (b) and N (g) conc','FontWeight','bold')
        xlim(XTlimits)
        ylabel('conc P/(2.2\mum/kg) N/(30.9\mum/kg)');
        %ylim([0.5 1.5]);
        
    case 'Biota'
        if outputcompare  && isfield(cdata.diag,'VEG')
            %%%% plot against COPSE output
            plot(cdata.T, cdata.diag.VEG, 'color', cols.grey)
            hold on
        end
        %%%% plot this model output
        plot(XT,diag.VEG,'k')  % mass of terrestrial biosphere
        hold on
        plot(XT,diag.newp./pars.newp0,'b')  % marine new prod
        
        title('Biota k:VEG b:marine newp','FontWeight','bold')
        xlim(XTlimits)
        ylabel('Relative')
        
    case 'LandBiota'
        if outputcompare  && isfield(cdata.diag,'VEG')
            %%%% plot against COPSE output
            plot(cdata.T, cdata.diag.VEG, 'color', cols.grey)
            hold on
        end
        %%%% plot this model output
        plot(XT,diag.VEG,'k')  % mass of terrestrial biosphere
        hold on
        plot(XT,diag.V_T,'r')
        plot(XT,diag.V_co2,'g')
        plot(XT,diag.V_o2,'b')
        plot(XT,diag.V_npp,'c')
        plot(XT,diag.firef,'m')
        title({'Land OCT';'r:V_T, g:V_co2, b:V_o2, c:V_npp, m:firef, k:VEG'},'FontWeight','bold','Interpreter','none');
        xlim(XTlimits)
        ylabel('Relative')
        
    case 'FireIgnit'
        %%%% plot this model output
        plot(XT,diag.ignit,'k')  % ignition probability
        title('Ignition prob','FontWeight','bold');
        xlim(XTlimits)
        ylabel('percent')
        
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
        if outputcompare && isfield(cdata.diag,'oxidw') && isfield(cdata.diag,'phosw')
            plot(cdata.T, cdata.diag.oxidw, 'color', cols.light_r)
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
        
    case 'PWeath'
        if outputcompare && isfield(cdata.diag,'phosw')
            %%%% plot against COPSE output
            plot(cdata.T, cdata.diag.phosw, 'color', cols.light_b)
            hold on
        end
        %%%% plot this model output
        plot(XT,diag.phosw_s,'c')
        hold on
        plot(XT,diag.phosw_c,'g')
        plot(XT,diag.phosw_o,'r')
        plot(XT,diag.phosw,'b')
        title({'P Weathering';'r:phosw_o, c:phosw_s, g:phosw_c, b:phosw'},'FontWeight','bold','Interpreter','none')
        xlim(XTlimits)
        ylabel('Flux mol/yr')
    case 'WeathFac'  % pre-land surface G3 update
        
        %%%% plot this model output
        plot(XT,diag.f_preplant,'b')
        hold on
        plot(XT,diag.f_plant,'g')
        plot(XT,diag.f_co2,'r')
        plot(XT,diag.g_preplant,'b--')
        plot(XT,diag.g_plant,'g--')
        plot(XT,diag.g_co2,'r--')
        plot(XT,diag.w_plantenhance,'c')
        
        title({'Plant Weath  (- f sil -- g carb)';'b:_preplant g:_plant r:_co2 c:w_plantenhance'},'FontWeight','bold','Interpreter','None')
        xlim(XTlimits)
        ylabel('relative')
        
    case 'WeathFacNorm' % pre-land surface G3 update
        
        %%%% plot this model output
        plot(XT,diag.f_preplant.*(1-diag.VWmin).*diag.w_plantenhance,'b')
        hold on
        plot(XT,diag.f_plant.*diag.VWmin.*diag.w_plantenhance,'g')
        plot(XT,diag.f_co2.*diag.w_plantenhance,'r')
        plot(XT,diag.g_preplant.*(1-diag.VWmin).*diag.w_plantenhance,'b--')
        plot(XT,diag.g_plant.*diag.VWmin.*diag.w_plantenhance,'g--')
        plot(XT,diag.g_co2.*diag.w_plantenhance,'r--')
        plot(XT,diag.w_plantenhance,'c')
        plot(XT,diag.VWmin,'k')
        
        title({'Plant Weath Norm (- f sil -- g carb)';'(b:_preplant g:_plant r:_co2)norm c:w_plantenhance k:VWmin'},'FontWeight','bold','Interpreter','None')
        xlim(XTlimits)
        ylabel('relative')
    case 'WeathFac2' % updated for post-G3 land surface scheme
           
        %%%% plot this model output
        plot(XT,diag.f_gran,'b')
        hold on
        plot(XT,diag.f_bas,'g')
        plot(XT,diag.f_ap,'r')
        plot(XT,diag.f_carb,'m')
        if isfield(diag, 'w_plantenhance')
            plot(XT,diag.w_plantenhance,'c')
        end
        
        title({'Weath fac b:f_gran g:f_bas r:f_ap m:f_carb, c:w_plantenhance'},'FontWeight','bold','Interpreter','None')
        xlim(XTlimits)
        ylabel('relative')        
    case 'CDegass'
        
        %%%%% plot COPSE model output
        if outputcompare && isfield(cdata.diag,'ocdeg')
            %%%% plot against COPSE output
            plot(cdata.T, cdata.diag.ocdeg, 'color', cols.light_k)
            hold on
        end
        if outputcompare && isfield(cdata.diag,'ccdeg')
            %%%% plot against COPSE output
            plot(cdata.T, cdata.diag.ccdeg, 'color', cols.light_c)
            hold on
        end
        
        %%%% plot this model output
        plot(XT,diag.ccdeg,'c')
        hold on
        plot(XT,diag.ocdeg,'k')
        plot(XT,diag.ocdeg+diag.ccdeg,'b')
        %plot(XT,diag.mccb+diag.locb+diag.mocb,'m')
        title({'C Degassing';'k:ocdeg, c:ccdeg b:totdeg'},'FontWeight','bold')
        xlim(XTlimits)
        ylabel('Flux mol/yr')
        
    case 'SDegass'
        %%%% No COPSE output
        %%%% plot this model output
        plot(XT,diag.pyrdeg,'r')
        hold on
        plot(XT,diag.gypdeg,'g')
        title({'S Degassing';'r:pyrdeg, g:gypdeg'},'FontWeight','bold')
        xlim(XTlimits)
        ylabel('Flux mol/yr')
        
    case 'GYPPYR'
        if outputcompare && isfield(cdata.S,'PYR') && isfield(cdata.S,'GYP')
            %%%% plot against COPSE output
            plot(cdata.T, cdata.S.PYR, 'color', cols.light_r)
            hold on
            plot(cdata.T, cdata.S.GYP, 'color', cols.light_g)
        end
        %%%% plot this model output
        title({'S abundances (mol)';'r:PYR, g:GYP'},'FontWeight','bold')
        semilogy(XT,S.PYR,'r','displayname','PYR')
        hold on
        semilogy(XT,S.GYP,'g','displayname','GYP')
        xlim(XTlimits)
        ylabel('mol')
        
    case 'CAL'
        %%%% plot this model output
        if isfield(S,'CAL')
            plot(XT,S.CAL./pars.k18_oceanmass*1e3,'k','displayname','CAL')
        elseif isfield(diag,'Ocean') && isfield(diag.Ocean,'conc_Ca')
            plot(XT,diag.Ocean.tot_Ca./plotdata.tm.modules.ocean.mpars.k18_oceanmass*1e3,'k','displayname','Ca')
        elseif isfield(S,'Ca');
            plot(XT,S.Ca./pars.k18_oceanmass*1e3,'k','displayname','Ca')        
        else
            error('no CAL or Ca reservoir');
        end
        xlim(XTlimits)
        ylabel('mmol/kg')
        ylim([0 40]);
        title('Marine  calcium','FontWeight','bold');
    case 'SCAL'
        if outputcompare && isfield(cdata.S,'S') && isfield(cdata.S,'CAL')
            %%%% plot against COPSE output
            plot(cdata.T, cdata.S.S./pars.k18_oceanmass*1e3, 'color', cols.light_b)
            hold on
            plot(cdata.T, cdata.S.CAL./pars.k18_oceanmass*1e3, 'color', cols.light_c)
        end
        %%%% plot this model output
        plot(XT,S.S./pars.k18_oceanmass*1e3,'b','displayname','S')
        hold on
        if isfield(S, 'CAL')
            plot(XT,S.CAL./pars.k18_oceanmass*1e3,'c','displayname','CAL')
            title({'Marine sulphate calcium';'b:SO4, c:CAL'},'FontWeight','bold')
        else
            title({'Marine sulphate';'b:SO4'},'FontWeight','bold')
        end
        xlim(XTlimits)
        ylabel('mmol/kg')
        ylim([0 40]);
        
    case 'CRes'
        if outputcompare && isfield(cdata.S,'G') && isfield(cdata.S,'C') && isfield(cdata.S,'A')
            %%%% plot against COPSE output
            semilogy(cdata.T, cdata.S.G/pars.G0, 'color', cols.light_r)
            hold on
            semilogy(cdata.T, cdata.S.C/pars.C0, 'color', cols.light_g)
            semilogy(cdata.T, cdata.S.A/pars.A0, 'color', cols.light_b)
        end
        %%%% plot this model output
        semilogy(XT,S.G./pars.G0,'r','displayname','G')
        hold on
        semilogy(XT,S.C./pars.C0,'g','displayname','C')
        semilogy(XT,S.A./pars.A0,'b','displayname','A')
        xlim(XTlimits)
        ylabel('Relative abundance')
        title({'Relative C abundances (log)';'b:A, r:G, g:C'},'FontWeight','bold')
   case 'CGA'
        if outputcompare && isfield(cdata.S,'G') && isfield(cdata.S,'C') && isfield(cdata.S,'A')
            %%%% plot against COPSE output
            plot(cdata.T, cdata.S.G, 'color', cols.light_r)
            hold on
            plot(cdata.T, cdata.S.C, 'color', cols.light_g)
            plot(cdata.T, cdata.S.A/pars.A0, 'color', cols.light_b)
        end
        %%%% plot this model output
        plot(XT,S.G,'r','displayname','G')
        hold on
        plot(XT,S.C,'g','displayname','C')
        plot(XT,S.A,'b','displayname','A')
        xlim(XTlimits)
        ylabel('mol')
        title({'C abundances';'b:A, r:G, g:C'},'FontWeight','bold')
        
    case 'CResChange'
        if outputcompare && isfield(cdata.S,'G') && isfield(cdata.S,'C') && isfield(cdata.S,'A')
            %%%% plot against COPSE output
            plot(cdata.T, (cdata.S.G - cdata.S.G(1)), 'color', cols.light_r)
            hold on
            plot(cdata.T, (cdata.S.C - cdata.S.C(1)), 'color', cols.light_g)
            plot(cdata.T,  (cdata.S.A - cdata.S.A(1)), 'color', cols.light_b)
            plot(cdata.T, (cdata.S.G - cdata.S.G(1)) + (cdata.S.C - cdata.S.C(1))+ (cdata.S.A - cdata.S.A(1)), 'color', cols.grey)
        end
        %%%% plot this model output
        plot(XT,S.G - S.G(1),'r','displayname','G')
        hold on
        plot(XT,S.C - S.C(1),'g','displayname','C')
        plot(XT,S.A - S.A(1),'b','displayname','A')
        plot(XT,S.G - S.G(1) + S.C - S.C(1) + S.A - S.A(1),'k','displayname','net')
        xlim(XTlimits)
        ylabel('current - initial (mol)')
        title({'Change C abundance (mol)';'b:A, r:G, g:C k:net'},'FontWeight','bold')

    case 'SResChange'
        if outputcompare && isfield(cdata.S,'S') && isfield(cdata.S,'PYR') && isfield(cdata.S,'GYP')
            %%%% plot against COPSE output
            plot(cdata.T, cdata.S.S - cdata.S.S(1), 'color', cols.light_b)
            hold on
            plot(cdata.T, cdata.S.PYR - cdata.S.PYR(1), 'color', cols.light_r)
            plot(cdata.T, cdata.S.GYP - cdata.S.GYP(1), 'color', cols.light_g)
            plot(cdata.T, cdata.S.S - cdata.S.S(1) + cdata.S.PYR - cdata.S.PYR(1) +  cdata.S.GYP - cdata.S.GYP(1) , 'color', cols.grey)
        end
        %%%% plot this model output
        plot(XT,(S.S - S.S(1)),'b','displayname','S')
        hold on
        plot(XT,(S.PYR - S.PYR(1)),'r','displayname','PYR')
        plot(XT,(S.GYP - S.GYP(1)),'g','displayname','GYP')
        plot(XT,(S.S - S.S(1))+(S.PYR - S.PYR(1))+(S.GYP - S.GYP(1)) ,'k','displayname','net')
        title({'Change S abundance (mol)';'b:SO4, r:PYR, g:GYP, k:net'},'FontWeight','bold')
        xlim(XTlimits)
        ylabel('Current - initial (mol)')
        
        
    case 'CaResChange'
        if outputcompare && isfield(cdata.S,'C') && isfield(cdata.S,'GYP') && isfield(cdata.S,'CAL')
            %%%% plot against COPSE output
            %c514output.clc_CaNet = 1.397e19*cdata.S.CAL + cdata.S.GYP + 1e21 * cdata.S.C + (no degas !) - (silicate weath);
            
            plot(cdata.T, cdata.S.CAL - cdata.S.CAL(1), 'color', cols.light_r)
            hold on
            plot(cdata.T, cdata.S.GYP - cdata.S.GYP(1), 'color', cols.light_g)
            plot(cdata.T, cdata.S.C - cdata.S.C(1) , 'color', cols.light_b)
            % plot(cdata.T, c514output.clc_CaNet - c514output.clc_CaNet(1) , 'color', cols.grey)
        end
        %%%% plot this model output
        
        if isfield(S,'CAL')
            plot(XT,(S.CAL - S.CAL(1)),'r','displayname','CAL')
            hold on
        elseif isfield(S,'Ca')
             plot(XT,(S.Ca - S.Ca(1)),'r','displayname','Ca')
        end
        if isfield(S,'GYP')
            plot(XT,(S.GYP - S.GYP(1)),'g','displayname','GYP')
        end
        
        if isfield(S,'C')
            plot(XT,(S.C - S.C(1)),'b','displayname','C')
        end
        plot(XT,(diag.clc_deltaCaSil - diag.clc_deltaCaSil(1)),'c','displayname','sil')
        plot(XT,(diag.clc_CaNet - diag.clc_CaNet(1)) ,'k','displayname','net')
        
        title({'Change Ca abundance (mol)';'r:CAL/Ca g:GYP b:C c:sil k:net'},'FontWeight','bold')
        xlim(XTlimits)
        ylabel('Current - initial (mol)')
        
    case 'RedoxChange'
        if outputcompare && isfield(cdata.diag,'clc_RedoxC') && isfield(cdata.diag,'clc_RedoxS') && isfield(cdata.diag,'clc_RedoxNet')
            %%%% plot against COPSE output            
            
            plot(cdata.T, cdata.diag.clc_RedoxC - cdata.diag.clc_RedoxC(1), 'color', cols.light_b)
            hold on
            plot(cdata.T, cdata.S.O - cdata.S.O(1), 'color', cols.light_r)
            plot(cdata.T, cdata.diag.clc_RedoxS - cdata.diag.clc_RedoxS(1), 'color', cols.light_g)
            plot(cdata.T, cdata.diag.clc_RedoxNet - cdata.diag.clc_RedoxNet(1) , 'color', cols.grey)
        end
        %%%% plot this model output
  
        plot(XT,(diag.clc_RedoxC - diag.clc_RedoxC(1)),'b','displayname','C')
        hold on
        plot(XT,S.O - S.O(1),'r','displayname','O')
        plot(XT,(diag.clc_RedoxS - diag.clc_RedoxS(1)),'g','displayname','S')
        plot(XT,(diag.clc_RedoxNet - diag.clc_RedoxNet(1)) ,'k','displayname','net')
        title({'Change ox-red (mol O_2 equiv)';'b:C+A, r:O, g:2*(GYP+S), k:net'},'FontWeight','bold')
        xlim(XTlimits)
        ylabel('Current - initial (mol O_2 equiv)')
        
    case 'CCrustRes'
        if outputcompare && isfield(cdata.S,'G') && isfield(cdata.S,'C') 
            %%%% plot against COPSE output
            plot(cdata.T, cdata.S.G/pars.G0, 'color', cols.light_r)
            hold on
            plot(cdata.T,  cdata.S.C/pars.C0, 'color', cols.light_g)
            plot(cdata.T, (cdata.S.C + cdata.S.G)/(pars.C0+pars.G0), 'color', cols.light_c)
        end
        %%%% plot this model output
        plot(XT,S.G./pars.G0,'r','displayname','G')
        hold on
        title({'relative crustal C abundances';'r:G, g:C, c:total'},'FontWeight','bold')
        plot(XT,S.C./pars.C0,'g','displayname','C')
        plot(XT, ( S.G+S.C )./ (pars.G0 + pars.C0) , 'c')
        xlim(XTlimits)
        ylabel('Relative abundance')
    case 'CPBurialratio'
        %%%% plot this model output
        plot(XT,diag.CPland_relative,'k',XT,diag.CPsea/pars.CPsea0,'b')
        title({'CP burial ratio';'b: marine, k:land'},'FontWeight','bold')
        xlim(XTlimits)
        ylabel(sprintf('ratio marine/%g land/TBD',pars.CPsea0));
    case 'orgCBurial'
        if outputcompare && isfield(cdata.diag,'mocb') && isfield(cdata.diag,'locb') 
            %%%% plot against COPSE output
            plot(cdata.T, cdata.diag.mocb, 'color', cols.light_b)
            hold on
            plot(cdata.T, cdata.diag.locb, 'color', cols.light_k)
            plot(cdata.T, cdata.diag.mocb + cdata.diag.locb, 'color', cols.light_r)
        end
        %%%% plot this model output
        tot = zeros(length(XT),1);
        if isfield(diag,'mocb')
            plot(XT,diag.mocb,'b')
            tot=tot+diag.mocb;
        end
        hold on
        if isfield(diag,'locb')
            plot(XT,diag.locb,'k')
            tot = tot+diag.locb;
        end
        plot(XT,tot,'r')
        title({'org-C burial (mol/yr)';'b:marine, k:land, r:total'},'FontWeight','bold')
        xlim(XTlimits)
        ylabel('Burial rate')
   case 'CSburial'
        if outputcompare && isfield(cdata.diag,'mocb') && isfield(cdata.diag,'locb') && isfield(cdata.diag,'mpsb')
            %%%% plot against COPSE output
            cscomp = (cdata.diag.mocb + cdata.diag.locb)*12./(cdata.diag.mpsb*32);
            plot(cdata.T, cscomp, 'color', cols.light_b)
            hold on          
        end
        csmodel = (diag.mocb + diag.locb)*12./(diag.mpsb*32);
        plot(XT, csmodel, 'b')
        hold on;
        % Berner (1982) C:S
        plot([XT(1) XT(end)],3.22*[1 1],'k--');  
        
        title({'C:S burial ratio'},'FontWeight','bold')
        xlim(XTlimits)
        ylabel('C:S (g/g)')

    case 'FRatio'
        if outputcompare && isfield(cdata.diag,'mocb') && isfield(cdata.diag,'locb') && isfield(cdata.diag,'mccb') && isfield(cdata.diag,'sfw')
            %%%% plot against COPSE output
            plot(cdata.T, (cdata.diag.mocb + cdata.diag.locb)./(cdata.diag.mocb + cdata.diag.locb + cdata.diag.mccb + cdata.diag.sfw) , 'color', cols.grey)
            hold on
        end
        %%%% plot this model output
        if isfield(diag,'sfw')
            plot(XT,( diag.mocb+diag.locb )./ ( diag.mocb + diag.locb +  diag.mccb + diag.sfw ),'g')
        else
            plot(XT,( diag.mocb+diag.locb )./ ( diag.mocb + diag.locb +  diag.mccb),'g')
        end
        hold on
        plot(XT,( diag.mocb+diag.locb-diag.oxidw )./(diag.ocdeg + diag.ccdeg),'r');
        % derive isotope-proxy-inversion estimate
        if ~isfield(pars,'f_cisotopeCG')
            pars.f_cisotopeCG = 'CGdyn';   % COPSE 5_14 behaviour
        end
        switch pars.f_cisotopeCG
            case 'CGdyn'        % dynamic C, G sedimentary reserovirs - not observed so assume at present (end-of-run) values
                delta_C0=diag.delta_C(end);
                delta_G0=diag.delta_G(end);            
            case 'CGfixed'      % fixed isotope composition of degassing and weathering
                delta_G0 =diag.delta_G(1);
                delta_C0=diag.delta_C(1);
            otherwise
                error('unknown f_cisotopeCG %s',pars.f_cisotopeCG);
        end
        if isfield(pars,'k12_ccdegmet') % new split of 'degassing'
            d13cvolc0 = ((pars.k12_ccdegmet+pars.k12_ccdegrip)*delta_C0+(pars.k13_ocdegmet+pars.k13_ocdegrip)*delta_G0)...
                            /(pars.k12_ccdegmet+pars.k12_ccdegrip+pars.k13_ocdegmet + pars.k13_ocdegrip);
        else    % classic COPSE
            d13cvolc0 = (pars.k12_ccdeg*delta_C0+pars.k13_ocdeg*delta_G0)/(pars.k12_ccdeg+pars.k13_ocdeg);
        end
        eta = 27;  % orgc fractionation
        fisotope = ((diag.delta_mccb)-d13cvolc0)/eta;
        plot(XT,fisotope,'k');
        if isfield(diag,'sfw')
            title({'f-ratios';'k:inferred, g:CO2DIC(incl sfw), r:net'},'FontWeight','bold')
        else
            title({'f-ratios';'k:inferred, g:CO2DIC(no sfw), r:net'},'FontWeight','bold')
        end
        xlim(XTlimits);
        ylim([0 1]);
       
    case 'SWeath'
        if outputcompare && isfield(cdata.diag,'pyrw') && isfield(cdata.diag,'gypw')
            %%%% plot against COPSE output
            plot(cdata.T, cdata.diag.pyrw, 'color', cols.light_r)
            hold on
            plot(cdata.T, cdata.diag.gypw, 'color', cols.light_g)
        end
        %%%% plot this model output
        plot(XT,diag.pyrw,'r')
        hold on
        plot(XT,diag.gypw,'g')
        
        title({'S Weathering';'r:pyrw, g:gypw'},'FontWeight','bold')
        xlim(XTlimits)
        ylabel('Flux mol/yr')
        
    case 'SBurial'
        if outputcompare && isfield(cdata.diag,'mpsb')
            %%%% plot against COPSE output
            plot(cdata.T, cdata.diag.mpsb, 'color', cols.light_r)
            hold on
        end
            %%%% plot against COPSE output
        if outputcompare &&  isfield(cdata.diag,'mgsb')
            plot(cdata.T, cdata.diag.mgsb, 'color', cols.light_g)
            hold on
        end
        %%%% plot this model output
        plot(XT,diag.mpsb,'r');
        hold on
        plot(XT,diag.mgsb,'g')
        xlim(XTlimits)
        % ylim([0 3e12])
        title({'S burial (mol/yr)';'r:pyr,g:gyp'},'FontWeight','bold')
        ylabel('Burial mol/yr')
        
    case 'CIsotopes'
        if outputcompare && isfield(cdata.diag,'d13C')
            %%%% plot against original COPSE output
            plot(cdata.T, cdata.diag.d13C, 'color', cols.light_b)
            hold on
        end
        if outputcompare && isfield(cdata.diag,'delta_A')
            %%%% plot against a recent comparison model output
            plot(cdata.T,cdata.diag.delta_A,'color',cols.light_k);
            hold on
            plot(cdata.T,cdata.diag.delta_mccb,'color',cols.light_b);
            plot(cdata.T,cdata.diag.delta_A+cdata.diag.d_mocb,'color',cols.light_c);
            plot(cdata.T,cdata.diag.delta_A+cdata.diag.d_locb,'color',cols.light_m);
        end
        %%%% plot this model output
        %plot(XT,diag.delta_A,'b')
        if isfield(diag,'delta_A')
            plot(XT,diag.delta_A,'k');
            hold on
            plot(XT,diag.delta_mccb,'b');
            plot(XT,diag.delta_A+diag.d_mocb,'c');
            plot(XT,diag.delta_A+diag.d_locb,'m');
        end
        plot(XT,diag.delta_C,'g')
        hold on;
        plot(XT,diag.delta_G,'r')
        xlim(XTlimits)
        ylim([-1 10])
        title('d13C (single res.) k:A b:mccb,c:mocb,m:locb,r:G,g:C','FontWeight','bold')
        ylabel('per mil')
    case 'CIsotopesIO'
        % additional detail on d13C of inputs/outputs to DIC pool        
        %%%% plot this model output
        %plot(XT,diag.delta_A,'b')
        plot(XT,diag.delta_mccb,'k');
        hold on;
        plot(XT,diag.delta_A+diag.d_mocb,'c');
        plot(XT,diag.delta_A+diag.d_locb,'m');
        plot(XT, diag.d13Cin, 'b');
        plot(XT, diag.d13Cout, 'b');
        plot(XT, diag.D_B, 'c');
        plot(XT, diag.D_P, 'm');
        %plot(XT,diag.d13Cdegass,'r');
        %plot(XT,diag.d13CDICin,'b');
        %plot(XT,diag.d13CDICout,'c');
        plot(XT,diag.delta_C,'g');
        plot(XT,diag.delta_G,'r')
        xlim(XTlimits)
        %ylim([-30 -20]);
        title('\delta^{13}C: r:G c:mocb m:locb k:mccb g:C b:d13Cin/out','FontWeight','bold')
        ylabel('per mil')        
    case 'CIsotopesDiff'
        %Difference between this run and comparison output
        %Interpolate onto tcomp grid for comparison
        
        if outputcompare && isfield(cdata.diag, 'delta_mccb')
            [ tcomp, d13Cdiff, d13Crms ] = copse_diff(XTlimits, 'diff', cdata.T, cdata.diag.delta_mccb, XT, diag.delta_mccb);
            d13C_comparison = true;
        else
            tcomp = [];
            d13Cdiff = [];
            d13Crms = NaN;
            d13C_comparison = false;
        end
        
        plot(tcomp, d13Cdiff,'r')
    
        fprintf('RMS error (mccb d13C - comparison model) %g\n',d13Crms);
        if d13C_comparison
            title({'mccb d13C - comparison model)';sprintf('RMS Error %g',d13Crms)},'FontWeight','bold')
        else
            title('No d13C comparison data','FontWeight','bold')
        end
        
        xlim(XTlimits)
        ylabel('per mil');
    case 'SIsotopes'
        if outputcompare && isfield(cdata.diag,'delta_S')
            %%%% plot against COPSE output
            plot(cdata.T, cdata.diag.delta_S, 'color', cols.light_b)
            hold on
        end
        %%%% plot this model output
        if isfield(S,'moldelta_S')
            plot(XT,S.moldelta_S./S.S,'b')
            hold on
        end
        plot(XT,S.moldelta_GYP./S.GYP,'g')
        hold on
        plot(XT,S.moldelta_PYR./S.PYR,'r')
        xlim(XTlimits)
        title('d34S. b:SO4,r:PYR,g:GYP','FontWeight','bold')
        ylabel('per mil')
    case 'SIsotopesDiff'
        %Difference between this run and C514 output
        %Interpolate onto tcomp grid for comparison
        if outputcompare && isfield(cdata.diag, 'delta_S')
            [ tcomp, d34Sdiff, d34Srms ] = copse_diff(XTlimits, 'diff', cdata.T, cdata.diag.delta_S, XT, diag.delta_S);
            d34Scomparison = true;
        else
            tcomp = [];
            d34Sdiff = [];
            d34Srms = NaN;
            d34Scomparison = false;
        end
       
        plot(tcomp, d34Sdiff,'r')
       
        fprintf('RMS error (d34S - comparison model) %g\n',d34Srms);
        if d34Scomparison
            title({'d34S - comparison model';sprintf('RMS Error %g',d34Srms)},'FontWeight','bold')
        else
            title('No d34S comparison data','FontWeight','bold')
        end
        xlim(XTlimits)
        ylabel('per mil');
    case 'CaIsotopes'        
        %%%% plot this model output
        plot(XT,diag.Ocean.deltaCa44,'b')
        xlim(XTlimits)
        %ylim([-1 5])
        title('\delta^{44}Ca','FontWeight','bold')
        ylabel('per mil')
    case 'PBurial'
        if outputcompare && isfield(cdata.diag,'capb')
            %%%%%%%%%%%%%%%%%%%%% debug figure for P burial fluxes           
            plot(cdata.T,cdata.diag.capb,'color',cols.light_g)
            hold on
            plot(cdata.T,cdata.diag.fepb,'color',cols.light_c)
            plot(cdata.T,cdata.diag.mopb,'color',cols.light_r)
            plot(cdata.T,cdata.diag.psea,'color',cols.light_b)
        end
        %Plot this model output
        plot(XT,diag.capb,'g')
        hold on
        plot(XT,diag.fepb,'c')
        plot(XT,diag.mopb,'r')
        if isfield(diag,'psea');
            plot(XT,diag.psea,'b')
        end
        if isfield(diag,'pland');
            plot(XT,diag.pland,'k')
        end
        title({'P Burial flux';'psea (b), pland(k), capb(g), fepb (c), mopb (r)'},'Fontweight','bold');
        xlim(XTlimits);
        ylabel('mol/yr');
        
        
    otherwise
        handled = 0;
%        error('Unknown plot %s',char(wplot));
end

end
