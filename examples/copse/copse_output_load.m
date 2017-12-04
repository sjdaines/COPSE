function test_output = copse_output_load(copse_version, copse_configuration)
% Load test model output, and convert format

    % Core tests output, available as part of repository / release package
    COPSE_test_output_dir = fullfile(paleo_paths.paleo_root(), 'examples/copse/COPSE_test_output');
    
    % Extra tests, available as a separate optional download
    COPSE_test_output_dir_full = fullfile(paleo_paths.paleo_root(), 'examples/copse/COPSE_test_output_full');


    
    switch copse_version
        case 'bergman2004'
            test_output = copse_output_load_bergman2004(COPSE_test_output_dir);        
        case 'millsg3'
            % load comparison dataset G3 model
            load(fullfile(COPSE_test_output_dir, 'g3_outputs_avg_paleo.mat'));
            test_output = g3;

        case 'lenton2016paleozoic'
            fname = sprintf('Lenton2016%s', copse_configuration);
            output_dirs = {COPSE_test_output_dir, COPSE_test_output_dir_full};
            folderpath = find_copse_output(output_dirs, fname);
            test_output = paleo_run.loadoutput(fname, folderpath);            
            % add field for delta_mccb
            test_output.diag.delta_mccb = test_output.diag.delta_A + test_output.diag.d_mccb;            
        case 'reloaded'
            output_dirs = {fullfile(COPSE_test_output_dir, 'reloaded'), fullfile(COPSE_test_output_dir_full, 'reloaded')};
            folderpath = find_copse_output(output_dirs, copse_configuration);
            test_output = paleo_run.loadoutput(copse_configuration, folderpath);
        
            % add field for delta_mccb
            test_output.diag.delta_mccb = test_output.diag.delta_A + test_output.diag.d_mccb;

        otherwise
            error('unrecognized copse_version %s', copse_version)
    end
    
end


function folderpath = find_copse_output(dirs, fname)
% Check a list of folder paths for specified fname.mat

    folderpath = '';
    for i =1:length(dirs)
        testpath = fullfile(dirs{i}, [fname '.mat']);
        if exist(testpath, 'file')
            folderpath = dirs{i};
            break;
        end
    end

    if isempty(folderpath)
        error('test output file %s not found', fname);
    end
end

function C_514=copse_output_load_bergman2004(COPSE_test_output_dir)
% COPSE_OUTPUT_LOAD Load data from Noam's COPSE run (header changed to remove brackets) 
%

% Convert to PALEO format

C_514=struct;
C_514.outputfile = fullfile(COPSE_test_output_dir, 'base_514_namechange.txt');
COPSE_514 = importdata(C_514.outputfile) ;
% Add a copy of the original data
C_514.COPSE_514 = COPSE_514;

% Define normalisation values f
C_514.tm.pars.P0    = 3.1000e+15;
C_514.tm.pars.N0    = 4.3500e+16;
C_514.tm.pars.O0    = 3.7000e+19;
C_514.tm.pars.C0    = 1e+21;
C_514.tm.pars.G0    = 1e+21;
C_514.tm.pars.A0    = 3.1930e+18;
C_514.tm.pars.PYR0  = 1e+20;
C_514.tm.pars.GYP0  = 1e+20;
C_514.tm.pars.S0    = 4.0000e+19;
C_514.tm.pars.CAL0  = 1.3970e+19;

C_514.tm.pars.k1_oxfrac     = 0.8600;
C_514.tm.pars.k6_fepb       = 6.0000e+09;
C_514.tm.pars.k7_capb       = 1.5000e+10;
C_514.tm.pars.k11_landfrac  = 0.1035;
          
%%%% loop over columns and convert to named fields in output struct
for u = 1:length(COPSE_514.colheaders)
    fieldname=char(COPSE_514.colheaders(u));
    switch fieldname
        case 'time_My_'
            %%%% convert time to forwards in years
            C_514.T = paleo_const.time_present_yr - 1e6 *COPSE_514.data(:,u) ;
        case 'O2'
            C_514.S.O           = COPSE_514.data(:,u)*C_514.tm.pars.O0;
            C_514.diag.pO2PAL   =  COPSE_514.data(:,u);
        case {'A','P','N','S','C','G','PYR','GYP','CAL'}
            norm0 = C_514.tm.pars.([fieldname '0']);
            C_514.S.(fieldname)           = COPSE_514.data(:,u)*norm0;
        case 'CO2'
            C_514.diag.pCO2PAL  = COPSE_514.data(:,u);
        case 'T'
            C_514.diag.TEMP     = COPSE_514.data(:,u) + paleo_const.k_CtoK;
            
        case 'anox'
            C_514.diag.ANOX =  COPSE_514.data(:,u);
        case 'V'
            C_514.diag.VEG =  COPSE_514.data(:,u);
        case {'silw','carbw','pyrw','gypw','mocb','locb','mccb'}
            C_514.diag.(fieldname) =  COPSE_514.data(:,u)*1e12;
        case 'pyrb'
            C_514.diag.mpsb =  COPSE_514.data(:,u)*1e12;
        case 'gypb'
            C_514.diag.mgsb =  COPSE_514.data(:,u)*1e12;
        case 'phsw'
            C_514.diag.phosw =  COPSE_514.data(:,u)*1e10;
        case 'oxdw'
            C_514.diag.oxidw =  COPSE_514.data(:,u)*1e12;
        case 'd13C'  % d13 of mccb
            C_514.diag.delta_mccb =  COPSE_514.data(:,u);
        case 'd34S'  % d34S of S reservoir
            C_514.diag.delta_S =  COPSE_514.data(:,u);
        case 'Alk'
            % ignore as not used
    end
end

% Add some derived P burial fractions
C_514.diag.capb = C_514.tm.pars.k7_capb .* (C_514.diag.mocb/4.5e12) ;
C_514.diag.fepb = (C_514.tm.pars.k6_fepb./C_514.tm.pars.k1_oxfrac).*(1-C_514.diag.ANOX) ;
C_514.diag.mopb = C_514.diag.mocb / 250 ;
C_514.diag.psea = C_514.diag.phosw .* ( 1 - C_514.tm.pars.k11_landfrac.*C_514.diag.VEG) ;

% Add budget checks

C_514.diag.clc_RedoxS = 2*(C_514.S.GYP + C_514.S.S);
C_514.diag.clc_RedoxC = C_514.S.C + C_514.S.A;
C_514.diag.clc_RedoxNet = C_514.diag.clc_RedoxC + C_514.diag.clc_RedoxS + C_514.S.O;


    
end