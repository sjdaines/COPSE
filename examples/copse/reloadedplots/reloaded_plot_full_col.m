function fighandle = reloaded_plot_full_col(modeldata, linecolstyle, fighandle)

% Plot PALEO/COPSE output against geologic data after model run
% call from command window once you have results in workspace
%
% run          - model run
% lincolstyle  - character string specifying color and style
%                 (see 'help plot')
%
% Examples:
% 
% reloaded_plot_full_col(run, 'b--')     % dashed blue line
% reloaded_plot_full_col(run, 'r')       % solid red line

if nargin < 3
    %%%% call empty figure
    % Load precalculated figure background
    fighandle = openfig('empty_datafig_revised2_notick.fig','new') ;
    % Create figure 'background' from datasets
    % fighandle = create_datafig();
end

text('Interpreter','latex')

%%%% find subplots
subs=get(fighandle,'children');

%%%% open existing subplots and plot PALEO outputs
% 
subplot(subs(1)) ;
box on
%plot(modeldata.T./1e6, 21.* modeldata.diag.pO2PAL, linecolstyle ) ;
plot(modeldata.T./1e6, 100*modeldata.diag.mrO2, linecolstyle) ;  % mixing ratio
%ylabel('pO_{2} (vol%)')
%
subplot(subs(5)) ;
box on
plot(modeldata.T./1e6, 280.*modeldata.diag.pCO2PAL, linecolstyle);
%ylabel('pCO_{2} (ppmv)')
% 
subplot(subs(2)) ;
box on
plot(modeldata.T./1e6, 28.* ( modeldata.S.S/modeldata.tm.pars.S0 ), linecolstyle  );
%ylabel('SO_{4} (mmol/kg)')
% 
subplot(subs(4)) ;
box on
plot(modeldata.T./1e6, modeldata.diag.delta_A+modeldata.diag.d_mccb, linecolstyle);
%ylabel('\delta^{13}C (^{\fontsize{7}o}/{\fontsize{7}oo})')
% 
subplot(subs(3)) ;
box on
plot(modeldata.T./1e6,modeldata.S.moldelta_S./modeldata.S.S, linecolstyle)
%ylabel('\delta^{34}S (^{\fontsize{7}o}/{\fontsize{7}oo})')
% 
subplot(subs(6)) ;
box on
plot(modeldata.T./1e6,modeldata.diag.delta_Sr_ocean, linecolstyle)
%ylabel('^{87}Sr/^{86}Sr')

end