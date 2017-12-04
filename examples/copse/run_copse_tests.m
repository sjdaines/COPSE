function [nfail, npass] = run_copse_tests(run_IDs)
    % Run tests for current code against archived COPSE model output
    % 
    % run_IDs  - [optional] array of test IDs to run (default is [] ie run all tests)
    % 
    % Tests list of configurations and error tolerance as specified in copse_tests.xlsx
    % NB: this spreadsheet needs a very specific format (you can add rows for configurations,
    % add columns for fields to test, but the layout needs to stay fixed).

    if nargin < 1
        run_IDs = [100, 200, 300, 310, 400, 500, 550];
        fprintf('using default minimum set of run_IDs ');
        fprintf('%g ', run_IDs);
        fprintf('\n');
    elseif ischar(run_IDs) && strcmp(run_IDs, 'all')
        run_IDs = []; % every test
    end
    
    nheader_rows = 4;   % number of header rows to skip when looking for model configurations
    % fields-to-test are read from spreadsheet
    irow_fieldnames = nheader_rows-1; % 1-based
    irow_fieldmethod = nheader_rows;
    % columns (1 based indices)
    icol_ID = 1;                    % A
    icol_expts = 2;                 % B
    icol_baseline = 3;              % C
    icol_expt = 4;                  % D
    icol_copse_version = 6;         % F
    icol_copse_configuration = 7;   % G
    icol_first_test_field = 9;      % I
    
    
    LN = 'run_copse_tests'; paleo_log.initialise(); L = paleo_log.getLogger();
    % Optionally set logging to file
    L.setLogFile('run_copse_tests.txt');
    L.setFileLevel(L.INFO)
    % and disable/enable logging to terminal
    % L.setCommandWindowLevel(L.DEBUG);

    % get list of tests, comparison output, and comparison fields from spreadsheet
    [~, xls_txt, xls_raw] = xlsread('copse_tests');

    % check we have expected spreadsheet contents
    if strcmp(xls_txt{nheader_rows-2, icol_ID}, 'Test Run') ~= 1
        error('unexpected spreadsheet contents');
    end

    % gather commands to run tests, stripping blank lines
    % strip any row without ID (allows blank / comment rows)
    test_region = xls_raw((nheader_rows+1):end, icol_ID);
    test_rows = horzcat(false(1, nheader_rows), ~isnan([test_region{:}]));  % indices of non-header, non-blank rows
    % gather commands
    test_IDs = xls_raw(test_rows, icol_ID);
    test_cmds = xls_txt(test_rows, icol_expts);
    test_baseline = xls_txt(test_rows, icol_baseline);
    test_expt = xls_txt(test_rows, icol_expt);

    % gather parameters to read output
    copse_version = xls_txt(test_rows, icol_copse_version);
    copse_configuration = xls_txt(test_rows, icol_copse_configuration);
    
    % gather comparison fields and method
    % find rows containing fields-to-test, stripping blank columns
    fields_region = xls_txt(irow_fieldnames, icol_first_test_field:end);
    field_columns = horzcat(false(1, icol_first_test_field-1), ~strcmp(fields_region, ''));
    comp_fields = xls_txt(irow_fieldnames, field_columns);
    comp_method = xls_txt(irow_fieldmethod, field_columns);
    L.log(L.INFO, LN, sprintf('comparison fields:\n'));
    for j = 1:length(comp_fields)
        L.log(L.INFO, LN, sprintf('\tdiag.%s\t(%s)\n', comp_fields{j}, comp_method{j}));
    end
    
    
    % gather comparison tolerance
    % (blank cells will be read as NaN meaning no comparison on this field)
    comp_tol = xls_raw(test_rows, icol_first_test_field:end);

    % iterate through tests, comparing against archived data

    npass = 0;
    nfail = 0;

    tests_to_run = [];
    for i = 1:length(test_cmds)
        if isempty(run_IDs) || any(test_IDs{i} == run_IDs)
            tests_to_run(end+1) = i;
        end
    end
    
    L.log(L.INFO, LN, sprintf('running %i tests out of total %i\n', length(tests_to_run), length(test_IDs)));
    
    for i = tests_to_run
       L.log(L.INFO, LN, sprintf('-------------------------------------------------------------\n')); 
       L.log(L.INFO, LN, sprintf('Start test_ID %i\n', test_IDs{i}));
       % string to be evaluated to run test model
       test_eval = sprintf('%s(''%s'', ''%s'')', test_cmds{i}, test_baseline{i}, test_expt{i});
       L.log(L.INFO, LN, sprintf('testing run=%s\n', test_eval));
       L.log(L.INFO, LN, ...
           sprintf('against copse_output_load(''%s'', ''%s'')\n', ...
           copse_version{i}, copse_configuration{i}));

       % read comparison output
       compoutput = copse_output_load(copse_version{i}, copse_configuration{i});

       % run model
       testrun = eval(test_eval);
       testrun.initialise()
       testrun.integrate();
       testrun.postprocess();
       tlimits = [testrun.T(1), testrun.T(end)];

       % iterate through fields and check RMS
       testOK = true;   
       for c = 1:length(comp_fields)
           fname = comp_fields{c};
           ftol = comp_tol{i, c};
           if ~isnan(ftol)
               [ tcomp, fdiff, frms ] = copse_diff(tlimits, comp_method{c}, ...
                                               compoutput.T, compoutput.diag.(fname), ...
                                               testrun.T, testrun.diag.(fname));
                if (frms <= ftol)
                    L.log(L.INFO, LN, sprintf('RMS diag.%s %g <= tol %g,  OK\n', fname, frms, ftol)); 
                else
                    L.log(L.INFO, LN, sprintf('RMS diag.%s %g > tol %g, FAIL\n', fname, frms, ftol));
                    testOK = false;
                end
           else
               L.log(L.INFO, LN, sprintf('no test on field diag.%s\n', fname));
           end
       end

       if testOK
           L.log(L.INFO, LN, sprintf('PASS\n'));
           npass = npass + 1;
       else
           L.log(L.WARN, LN, sprintf('FAIL\n'));
           nfail = nfail + 1;
       end
       L.log(L.INFO, LN, sprintf('-------------------------------------------------------------\n')); 
    end

    ntests = npass + nfail;
    L.log(L.INFO, LN, sprintf('%g tests %g pass %g fail\n', ntests, npass, nfail));

    fprintf('see log file %s\n', L.fullpath);
end

