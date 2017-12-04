% Generate plots for COPSE reloaded Lenton etal (2017).
% Edit ops= below to choose whether to rerun the model, or load saved output

%%%% Start logger 
timestamp = paleo_log.getTimestamp();
LN = 'run_plot_reloaded'; paleo_log.initialise(); L = paleo_log.getLogger();
% Optionally set logging to file
%L.setLogFile(paleo_log.getOutputPathTimeStamped('run_plot_reloaded', timestamp));
% and disable/enable logging to terminal
% L.setCommandWindowLevel(L.DEBUG);

% Edit ops= below to choose whether to rerun or load saved output
% rerun everything
%ops = {'runall', 'loadall', 'Fig5', 'Fig6', 'Fig7', 'Fig8', 'Fig9', 'Fig10', 'Fig11', 'Fig12', 'Fig13'};
% load and plot saved output
% NB: load is from current output folder, not the archived comparison output.
% ops = {'loadall', 'Fig5', 'Fig6', 'Fig7', 'Fig8', 'Fig9', 'Fig10', 'Fig11', 'Fig12', 'Fig13'};
 ops = {'loadall', 'Fig12'};

% define runs
RL_runs = { ...
    'original', 'baseline'; ... % "original" reconstructs the original COPSE for whole Phanerozoic
    % Variants in Fig. 5
    'original', 'DB'; ...
    'original', 'U'; ...
    'original', 'EWCP'; ...
    'original', 'DUEWBCP'; ...
    % Variants in Fig. 6
    'original', 'sfw'; ...
    'original', 'basnoU'; ...
    'original', 'Easplit'; ...
    'original', 'vegweath'; ...
    'original', 'bernerT'; ...
    'original', 'newweath'; ...
    % Variants in Fig. 7
    'original', 'CAL'; ...
    'original', 'ignit'; ...
    'original', 'pyrweath'; ...
    'original', 'newweathredox'; ...
    'original', 'newbase'; ...
    %%%% "newbase" runs the new COPSE structure with old fluxes and without additional forcings for whole Phanerozoic
    'newbase', 'baseline'; ...
    %%%% Variants in Fig. 8
    'newbase', 'highS'; ...
    'newbase', 'highCin'; ...
    'newbase', 'lowCorg'; ...
    'newbase', 'Pweath'; ...
    'newbase', 'newfluxes'; ...
    %%%% Variants in Fig. 9
    'newbase', 'basalt'; ...
    'newbase', 'granite'; ...
    'newbase', 'PG'; ...
    'newbase', 'bcoal'; ...
     %%%% "reloaded" runs the new COPSE reloaded for whole Phanerozoic
    'reloaded', 'baseline'; ...
    %%%% Variants in Fig. 10
    'reloaded', 'k15025'; ...
    'reloaded', 'k1501'; ...
    'reloaded', 'newnpp'; ...
    'reloaded', 'sfwstrong'; ...
    'reloaded', 'sfwnoT'; ...
    %%%% Variants in Fig. 11
    'reloaded', 'climsens15'; ...
    'reloaded', 'climsens225'; ...
    'reloaded', 'climsens45'; ...
    'reloaded', 'climsens6'; ...
    %%%% Variants in Fig. 12
    'reloaded', 'locbU'; ...
    'reloaded', 'mocbU'; ...
    'reloaded', 'locbUmocbU'; ...
    'reloaded', 'mocbO2'; ...
    'reloaded', 'VCI'; ...
    };

for i = 1:length(ops)
    op = ops{i};
    switch op
        case 'runall'
            fprintf('about to rerun all model runs (edit this script and change ''opts=...'' to use previously saved output)\n');
            checkuser = input('continue ? [y/n]', 's');
            if strncmpi(checkuser, 'Y', 1)
                % iterate through list, execute and save all runs
                for j = 1:size(RL_runs, 1)
                    baseline = RL_runs{j, 1};
                    expt = RL_runs{j, 2};
                    runname = sprintf('%s_%s', baseline, expt);
                    % execute run, results will be in workspace 
                    eval(sprintf('%s=copse_reloaded_reloaded_expts(''%s'', ''%s'', true)', ...
                        runname, baseline, expt));
                    eval(sprintf('%s.initialise', runname));
                    eval(sprintf('%s.integrate', runname));
                    eval(sprintf('%s.postprocess', runname));
                    % save run
                    eval(sprintf('%s.saveoutput(''%s'')', runname, runname));
                end
            else
                fprintf('exiting\n');
                return;
            end
            
        case 'loadall'
            % iterate through list loading all runs into workspace
            for j = 1:size(RL_runs, 1)
                baseline = RL_runs{j, 1};
                expt = RL_runs{j, 2};
                runname = sprintf('%s_%s', baseline, expt);
                % load run, results will be in workspace 
                eval(sprintf('%s=paleo_run.loadoutput(''%s'')', ...
                    runname, runname));
            end 
        case 'Fig5' 
            fh = reloaded_plot_full_col(original_DB, 'b');
            reloaded_plot_full_col(original_U, 'r', fh);
            reloaded_plot_full_col(original_EWCP, 'g', fh);
            reloaded_plot_full_col(original_DUEWBCP, 'k', fh);
            % dashed line last although first in caption
            reloaded_plot_full_col(original_baseline, 'k--', fh);
            % then 'copy options' check 'preserve information', 'match figure screen size'
            %      'copy figure'
            % paste into Word
        case 'Fig6' 
            fh = reloaded_plot_full_col(original_sfw, 'b');
            reloaded_plot_full_col(original_basnoU, 'r', fh);
            reloaded_plot_full_col(original_Easplit, 'c', fh);
            reloaded_plot_full_col(original_vegweath, 'g', fh);
            reloaded_plot_full_col(original_Easplit, 'c', fh);
            reloaded_plot_full_col(original_bernerT, 'm', fh);
            reloaded_plot_full_col(original_newweath, 'k', fh);
            % dashed line last although first in caption
            reloaded_plot_full_col(original_DUEWBCP, 'k--', fh);
        case 'Fig7' 
            fh = reloaded_plot_full_col(original_CAL, 'b');
            reloaded_plot_full_col(original_ignit, 'r', fh);
            reloaded_plot_full_col(original_pyrweath, 'c', fh);
            reloaded_plot_full_col(original_newweathredox, 'g', fh);
            reloaded_plot_full_col(original_newbase, 'k', fh);
            % dashed line last although first in caption
            reloaded_plot_full_col(original_DUEWBCP, 'k--', fh);
        case 'Fig8'
            fh = reloaded_plot_full_col(newbase_highS, 'b');
            reloaded_plot_full_col(newbase_highCin, 'r', fh);
            reloaded_plot_full_col(newbase_lowCorg, 'g', fh);
            reloaded_plot_full_col(newbase_Pweath, 'c', fh);
            reloaded_plot_full_col(newbase_newfluxes, 'k', fh);
            % dashed line last although first in caption
            reloaded_plot_full_col(newbase_baseline, 'k--', fh);
        case 'Fig9'
            fh = reloaded_plot_full_col(newbase_basalt, 'b');
            reloaded_plot_full_col(newbase_granite, 'r', fh);
            reloaded_plot_full_col(newbase_PG, 'c', fh);
            reloaded_plot_full_col(newbase_bcoal, 'g', fh);
            reloaded_plot_full_col(reloaded_baseline, 'k', fh);
            % dashed line last although first in caption
            reloaded_plot_full_col(newbase_newfluxes, 'k--', fh);
        case 'Fig10'
            fh = reloaded_plot_full_col(reloaded_k15025, 'b');
            reloaded_plot_full_col(reloaded_k1501, 'r', fh);
            reloaded_plot_full_col(reloaded_newnpp, 'g', fh);
            reloaded_plot_full_col(reloaded_sfwstrong, 'c', fh);
            reloaded_plot_full_col(reloaded_sfwnoT, 'm', fh);
            % dashed line last although first in caption
            reloaded_plot_full_col(reloaded_baseline, 'k--', fh);
        case 'Fig11'
            fh = reloaded_plot_full_col(reloaded_climsens15, 'b');
            reloaded_plot_full_col(reloaded_climsens225, 'g', fh);
            reloaded_plot_full_col(reloaded_climsens45, 'c', fh);
            reloaded_plot_full_col(reloaded_climsens6, 'r', fh);
            % dashed line last although first in caption
            reloaded_plot_full_col(reloaded_baseline, 'k--', fh);
        case 'Fig12'
            fh = reloaded_plot_full_col(reloaded_locbU, 'b');
            reloaded_plot_full_col(reloaded_mocbU, 'r', fh);
            reloaded_plot_full_col(reloaded_locbUmocbU, 'g', fh);
            reloaded_plot_full_col(reloaded_mocbO2, 'c', fh);
            reloaded_plot_full_col(reloaded_VCI, 'm', fh);
            % dashed line last although first in caption
            reloaded_plot_full_col(reloaded_baseline, 'k--', fh);
        case 'Fig13'         
            fig13runs = { ...
                reloaded_baseline; ...
                reloaded_k15025; ...
                reloaded_k1501; ...
                reloaded_newnpp; ...
                reloaded_sfwstrong; ...
                reloaded_sfwnoT; ...
                reloaded_climsens225; ...
                reloaded_climsens45; ...
                reloaded_locbU; ...
                reloaded_mocbU; ...
                reloaded_mocbO2; ...
                reloaded_VCI; ...
                };
            plot_uncertainty_range(reloaded_baseline, fig13runs);
            % SD with 1e5 yr interpolation steps, fig->copy_figure OK
            % SD with 1e4 yr interpolation steps.
            % at least on my laptop, fig->copy_figure fails (Matlab error)
            % workaround - print to pdf and then copy from that (makes a _huge_ pdf ~16MB)
            % copse_fig.printpdf(9, 'Fig_13.pdf')
        otherwise
            L.log(L.ERROR, LN, sprintf('unrecognized op %s\n', op));
    end
end



