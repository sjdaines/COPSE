% COPSE CLASSIC Single ocean-atmosphere box example

%%%% Start logger 
timestamp = paleo_log.getTimestamp();
LN = 'COPSE_bergman2004_bergman2004'; paleo_log.initialise(); L = paleo_log.getLogger();
% Optionally set logging to file
%L.setLogFile(paleo_log.getOutputPathTimeStamped('COPSE_bergman2004_bergman2004', timestamp));
% and disable logging to terminal
% L.setCommandWindowLevel(L.OFF);

run=copse_bergman2004_bergman2004_expts('', 'baseline');
%run=copse_bergman2004_bergman2004_expts('run9');  % no S cycle
%run=copse_bergman2004_bergman2004_expts('run3VCI');
  

run.initialise;     % modify pars.Ainit etc to change initial values
run.integrate;
run.postprocess;
run.saveoutput;

% load comparison model output
copse5_14_modeloutput=copse_output_load('bergman2004');
run.plot('','',copse5_14_modeloutput);



