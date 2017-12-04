
The COPSE (Carbon, Oxygen, Phosphorus, Sulphur and Evolution) biogeochemical model predicts the coupled histories and controls on atmospheric O2, CO2 and ocean composition over Phanerozoic time.

The model is described in the following publications:

Bergman, N. M., Lenton, T. M., & Watson, A. J. (2004). COPSE: A new model of biogeochemical cycling over Phanerozoic time. American Journal of Science, 304(5), 397–437. http://doi.org/10.2475/ajs.304.5.397

Mills, B., Daines, S. J., & Lenton, T. M. (2014). Changing tectonic controls on the long-term carbon cycle from Mesozoic to present. Geochemistry, Geophysics, Geosystems, 15(12), 4866–4884. http://doi.org/10.1002/2014GC005530

Lenton, T. M., Dahl, T. W., Daines, S. J., Mills, B. J. W., Ozaki, K., Saltzman, M. R., & Porada, P. (2016). Earliest land plants created modern levels of atmospheric oxygen. Proceedings of the National Academy of Sciences, 113(35), 9704–9709. http://doi.org/10.1073/pnas.1604787113

Lenton, T. M., Daines, S.J., Mills, B. J. W. (2017). COPSE reloaded: An improved model of biogeochemical cycling over Phanerozoic time. Earth Science Reviews, in revision.


Running the model (requires Matlab version 2012 or higher):
-----------------

>> COPSE_setup                   % sets Matlab paths
>> cd examples/copse
>> run_copse_tests               % test against archived output (output is included for only the default set of 7 tests)
>>
>> COPSE_reloaded_reloaded       % runs model, plots output for Lenton etal (2017)
>> COPSE_bergman2004_bergman2004 % Bergman etal (2004) version
>> COPSE_millsg3_millsg3         % Mills etal (2014) version
>> COPSE_reloaded_bergman2004    % includes results from Lenton etal (2016) - see comments in file


Evaluation data:
---------------

Datasets are not part of the public release but are available on request from the authors.

Known issues:
------------

Please see KnownIssues.txt