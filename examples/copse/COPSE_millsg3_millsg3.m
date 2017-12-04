% COPSE 0-D examples

%%%% Start logger 
timestamp = paleo_log.getTimestamp();
LN = 'COPSE_reloaded_millsg3'; paleo_log.initialise(); L = paleo_log.getLogger();
% Optionally set logging to file
%L.setLogFile(paleo_log.getOutputPathTimeStamped('COPSE_reloaded_millsg3', timestamp));
% and disable/enable logging to terminal
% L.setCommandWindowLevel(L.DEBUG);

comparisondata = false;

%%%% "g3mills2014withbugs" implements the exact G3 model, with bugs, for last 250Myr
% run=copse_millsg3_millsg3_expts('g3mills2014withbugs', 'baseline',comparisondata);
%run=copse_millsg3_millsg3_expts('g3mills2014nobugs', 'baseline');
%run=copse_millsg3_millsg3_expts('g3mills2014nobugs', 'weather');
% use spreadsheet-based LIP forcing
run=copse_millsg3_millsg3_expts('g3mills2014withbugs', 'LipNoCO2', comparisondata); 
%run=copse_reloaded_millsg3_expts('g3mills2014withbugs', 'LipAllCO2max'); 

% load comparison model output
comparisonmodel =copse_output_load('millsg3');

run.initialise;
run.integrate;
run.postprocess;
run.saveoutput;
run.plot('','',comparisonmodel);

