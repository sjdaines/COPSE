% COPSE 0-D examples

%%%% Start logger 
timestamp = paleo_log.getTimestamp();
LN = 'COPSE_reloaded_bergman2004'; paleo_log.initialise(); L = paleo_log.getLogger();
% Optionally set logging to file
%L.setLogFile(paleo_log.getOutputPathTimeStamped('COPSE_reloaded_bergman2004', timestamp));
% and disable/enable logging to terminal
% L.setCommandWindowLevel(L.DEBUG);

comparisondata = false;

%%%% run bergman 2004 exact model 
run=copse_reloaded_bergman2004_expts('bergman2004','baseline',comparisondata); 
%%%% experiments in the original paper 
%run=copse_reloaded_bergman2004_expts('bergman2004','run2',comparisondata); 
%run=copse_reloaded_bergman2004_expts('bergman2004','run3',comparisondata); 
%run=copse_reloaded_bergman2004_expts('bergman2004','run6',comparisondata); 
%run=copse_reloaded_bergman2004_expts('bergman2004','run7',comparisondata); 
%run=copse_reloaded_bergman2004_expts('bergman2004','run8',comparisondata); 
%run=copse_reloaded_bergman2004_expts('bergman2004','run9',comparisondata); %%% S plots fail
%run=copse_reloaded_bergman2004_expts('bergman2004','run11',comparisondata); 
%run=copse_reloaded_bergman2004_expts('bergman2004','run12',comparisondata); 
%run=copse_reloaded_bergman2004_expts('bergman2004','run3VCI',comparisondata); 

%%%% run lenton et al 2012 Ordovician model but for full Phanerozoic
%run=copse_reloaded_bergman2004_expts('bergman2004','ordovician',comparisondata); 

%%%% run lenton 2013 book chapter model
%run=copse_reloaded_bergman2004_expts('bergman2004','bookchapter',comparisondata); 

%%%% run lenton et al 2016 PNAS paleozoic model runs
%run=copse_reloaded_bergman2004_expts('bergman2004','paleozoic_base',comparisondata); 
%run=copse_reloaded_bergman2004_expts('bergman2004','paleozoic_blue',comparisondata); 
%run=copse_reloaded_bergman2004_expts('bergman2004','paleozoic_cyan',comparisondata); 
%run=copse_reloaded_bergman2004_expts('bergman2004','paleozoic_magenta',comparisondata); 
%run=copse_reloaded_bergman2004_expts('bergman2004','paleozoic_green',comparisondata); 
%run=copse_reloaded_bergman2004_expts('bergman2004','paleozoic_yellow',comparisondata); 
%run=copse_reloaded_bergman2004_expts('bergman2004','paleozoic_red',comparisondata); 
%run=copse_reloaded_bergman2004_expts('bergman2004','paleozoic_black',comparisondata); 


% load comparison model output COPSE 514
comparisonmodel =copse_output_load('bergman2004');

run.initialise;
run.integrate;
run.postprocess;
run.saveoutput;
run.plot('','',comparisonmodel);

