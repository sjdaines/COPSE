% COPSE 0-D examples

%%%% Start logger 
timestamp = paleo_log.getTimestamp();
LN = 'COPSE_reloaded_reloaded'; paleo_log.initialise(); L = paleo_log.getLogger();
% Optionally set logging to file
%L.setLogFile(paleo_log.getOutputPathTimeStamped('COPSE_reloaded_reloaded', timestamp));
% and disable/enable logging to terminal
% L.setCommandWindowLevel(L.DEBUG);

comparisondata = false;

%%%% "reloaded" runs the new COPSE reloaded for whole Phanerozoic
run=copse_reloaded_reloaded_expts('reloaded', 'baseline', comparisondata);

%%%% "original" reconstructs the original COPSE for whole Phanerozoic
%run=copse_reloaded_reloaded_expts('original', 'baseline', comparisondata);
%%%% Variants in Fig. 5
%run=copse_reloaded_reloaded_expts('original', 'DB', comparisondata);
%run=copse_reloaded_reloaded_expts('original', 'U', comparisondata);
%run=copse_reloaded_reloaded_expts('original', 'EWCP', comparisondata);
%run=copse_reloaded_reloaded_expts('original', 'DUEWBCP', comparisondata);
%%%% Variants in Fig. 6
%run=copse_reloaded_reloaded_expts('original', 'sfw', comparisondata);
%run=copse_reloaded_reloaded_expts('original', 'basnoU', comparisondata);
%run=copse_reloaded_reloaded_expts('original', 'Easplit', comparisondata);
%run=copse_reloaded_reloaded_expts('original', 'vegweath', comparisondata);
%run=copse_reloaded_reloaded_expts('original', 'bernerT', comparisondata);
%run=copse_reloaded_reloaded_expts('original', 'newweath', comparisondata);
%%%% Variants in Fig. 7
%run=copse_reloaded_reloaded_expts('original', 'CAL', comparisondata);
%run=copse_reloaded_reloaded_expts('original', 'ignit', comparisondata);
%run=copse_reloaded_reloaded_expts('original', 'pyrweath', comparisondata);
%run=copse_reloaded_reloaded_expts('original', 'newweathredox', comparisondata);
%run=copse_reloaded_reloaded_expts('original', 'newbase', comparisondata);

%%%% "newbase" runs the new COPSE structure with old fluxes and without additional forcings for whole Phanerozoic
%run=copse_reloaded_reloaded_expts('newbase', 'baseline', comparisondata);
%%%% Variants in Fig. 8
%run=copse_reloaded_reloaded_expts('newbase', 'highS', comparisondata);
%run=copse_reloaded_reloaded_expts('newbase', 'highCin', comparisondata);
%run=copse_reloaded_reloaded_expts('newbase', 'lowCorg', comparisondata);
%run=copse_reloaded_reloaded_expts('newbase', 'Pweath', comparisondata);
%run=copse_reloaded_reloaded_expts('newbase', 'newfluxes', comparisondata);
%%%% Variants in Fig. 9
%run=copse_reloaded_reloaded_expts('newbase', 'basalt', comparisondata);
%run=copse_reloaded_reloaded_expts('newbase', 'granite', comparisondata);
%run=copse_reloaded_reloaded_expts('newbase', 'PG', comparisondata);
%run=copse_reloaded_reloaded_expts('newbase', 'bcoal', comparisondata);
%run=copse_reloaded_reloaded_expts('reloaded', 'baseline', comparisondata);

%%%% "reloaded" runs the new COPSE reloaded for whole Phanerozoic
%run=copse_reloaded_reloaded_expts('reloaded', 'baseline', comparisondata);
%%%% Variants in Fig. 10
%run=copse_reloaded_reloaded_expts('reloaded', 'k15025', comparisondata);
%run=copse_reloaded_reloaded_expts('reloaded', 'k1501', comparisondata);
%run=copse_reloaded_reloaded_expts('reloaded', 'newnpp', comparisondata);
%run=copse_reloaded_reloaded_expts('reloaded', 'sfwstrong', comparisondata);
%run=copse_reloaded_reloaded_expts('reloaded', 'sfwnoT', comparisondata);
%%%% Variants in Fig. 11
%run=copse_reloaded_reloaded_expts('reloaded', 'climsens15', comparisondata);
%run=copse_reloaded_reloaded_expts('reloaded', 'climsens225', comparisondata);
%run=copse_reloaded_reloaded_expts('reloaded', 'climsens45', comparisondata);
%run=copse_reloaded_reloaded_expts('reloaded', 'climsens6', comparisondata);
%%%% Variants in Fig. 12
%run=copse_reloaded_reloaded_expts('reloaded', 'locbU', comparisondata);
%run=copse_reloaded_reloaded_expts('reloaded', 'mocbU', comparisondata);
%run=copse_reloaded_reloaded_expts('reloaded', 'locbUmocbU', comparisondata);
%run=copse_reloaded_reloaded_expts('reloaded', 'mocbO2', comparisondata);
%run=copse_reloaded_reloaded_expts('reloaded', 'VCI', comparisondata);


% load comparison model output new baseline in COPSE reloaded paper
comparisonmodel =copse_output_load('reloaded', 'reloaded_baseline');
% comparisonmodel =copse_output_load('reloaded', 'reloaded_VCI');

run.initialise;
run.integrate;
run.postprocess;
run.saveoutput;
run.plot('','',comparisonmodel);

