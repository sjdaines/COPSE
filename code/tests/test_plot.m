%%%%% run this file to test the proxydata plot
plotter = paleo_plotlist ;
plotter.listplots = {'dataO2'; 'dataCO2'; 'dataSO4'; 'datad13C'; 'datad34S'; 'data8786Sr'; 'datad7Li'; 'datad44Ca'; 'data187188Os' } ;
% plotter.listplots = {'O2'; 'CO2'; 'SO4'; 'd34S'; 'd7Li'; 'd44Ca'; '187188Os'} ;
plotter.plotters = {@copse_plot_proxydata} ;
% plotter.plotlist('',[3.9e9 4.5e9],'','') ;
plotter.plotlist('',[run.T(1) run.T(end)],'',run) ;