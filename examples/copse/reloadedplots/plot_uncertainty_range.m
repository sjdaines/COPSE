function plot_uncertainty_range(best_guess, range)
% Plot uncertainty range as region and overlay best guess model
%
% Args:
%   best_guess (paleo_run):  best guess model output
%   range (cell array of paleo_run): model runs encompassing uncertainty range

xlims = [-550, 0];

% time grid to interpolate to, to find min/max
% compromise between resolution and figure size
%tgrid = xlims(1)*1e6:1e4:xlims(2)*1e6;
tgrid = xlims(1)*1e6:1e5:xlims(2)*1e6;

% light grey for filled region
fillcol = 0.85*[1, 1, 1];
% line width for overlayed best guess
bglw = 1.0;


figure;

% pCO2
subplot(3, 2, 1);
[pCO2PALmin, pCO2PALmax] = find_uncertainty_range(tgrid, range, 'diag', 'pCO2PAL');
% filled region for range
fill(horzcat(tgrid, fliplr(tgrid))/1e6, ...
    horzcat(pCO2PALmin, fliplr(pCO2PALmax)), ...
    fillcol, 'EdgeColor', 'none');
% overlay best guess
hold all;
plot(best_guess.T/1e6, ...
    best_guess.diag.pCO2PAL, 'k', 'LineWidth', bglw);
addIDlbl('A');
xlabel('Time (Ma)');
ylabel('pCO_2 (PAL)');
xlim(xlims);
ylim([0 20]);

% Temperature
subplot(3, 2, 3);
[TEMPmin, TEMPmax] = find_uncertainty_range(tgrid, range, 'diag', 'TEMP');
% filled region for range
fill(horzcat(tgrid, fliplr(tgrid))/1e6, ...
    horzcat(TEMPmin, fliplr(TEMPmax)) - paleo_const.k_CtoK, ...
    fillcol, 'EdgeColor', 'none');
% overlay best guess
hold all;
plot(best_guess.T/1e6, ...
    best_guess.diag.TEMP - paleo_const.k_CtoK, 'k', 'LineWidth', bglw);
addIDlbl('B');
xlabel('Time (Ma)');
ylabel(sprintf('Temperature (%cC)', char(176)));
xlim(xlims);
ylim([8 24]);

% marine N
subplot(3, 2, 5);
[Nmin, Nmax] = find_uncertainty_range(tgrid, range, 'S', 'N');
% filled region for range
fill(horzcat(tgrid, fliplr(tgrid))/1e6, ...
    1e6*horzcat(Nmin, fliplr(Nmax))/best_guess.tm.pars.k18_oceanmass, ...
    fillcol, 'EdgeColor', 'none');
% overlay best guess
hold all;
plot(best_guess.T/1e6, ...
    1e6*best_guess.S.N/best_guess.tm.pars.k18_oceanmass, 'k', 'LineWidth', bglw);
addIDlbl('C');
xlabel('Time (Ma)');
ylabel('[NO_3] (\mumol/kg)');
xlim(xlims);
ylim([20 45]);

% pO2
% TODO mixing ratio ?
subplot(3, 2, 2);
%[mrO2min, mrO2max] = find_uncertainty_range(tgrid, range, 'diag', 'mrO2');
[pO2PALmin, pO2PALmax] = find_uncertainty_range(tgrid, range, 'diag', 'pO2PAL');
% filled region for range
fill(horzcat(tgrid, fliplr(tgrid))/1e6, ...
    horzcat(pO2PALmin, fliplr(pO2PALmax)), ...  %21.*horzcat(pO2PALmin, fliplr(pO2PALmax)), ...  %    100*horzcat(mrO2min, fliplr(mrO2max)), ... % 
    fillcol, 'EdgeColor', 'none');
% overlay best guess
hold all;
plot(best_guess.T/1e6, ...
    best_guess.diag.pO2PAL, 'k', 'LineWidth', bglw);
    %100*best_guess.diag.mrO2, 'k', 'LineWidth', bglw);
addIDlbl('D');
xlabel('Time (Ma)');
ylabel('pO_2 (PAL)');
%ylabel('O_2 (%)');
xlim(xlims);
ylim([0 1.6]);
%ylim([0 35]);

% anoxic fraction
subplot(3, 2, 4);
[ANOXmin,ANOXmax] = find_uncertainty_range(tgrid, range, 'diag', 'ANOX');
% filled region for range
fill(horzcat(tgrid, fliplr(tgrid))/1e6, ...
    horzcat(ANOXmin, fliplr(ANOXmax)), ...
    fillcol, 'EdgeColor', 'none');
% overlay best guess
hold all;
plot(best_guess.T/1e6, ...
    best_guess.diag.ANOX, 'k', 'LineWidth', bglw);
addIDlbl('E');
xlabel('Time (Ma)');
ylabel('Anoxic Fraction');
xlim(xlims);
ylim([0 1]);

% marine P
subplot(3, 2, 6);
[Pmin, Pmax] = find_uncertainty_range(tgrid, range, 'S', 'P');
% filled region for range
fill(horzcat(tgrid, fliplr(tgrid))/1e6, ...
    1e6*horzcat(Pmin, fliplr(Pmax))/best_guess.tm.pars.k18_oceanmass, ...
    fillcol, 'EdgeColor', 'none');
% overlay best guess
hold all;
plot(best_guess.T/1e6, ...
    1e6*best_guess.S.P/best_guess.tm.pars.k18_oceanmass, 'k', 'LineWidth', bglw);
addIDlbl('F');
xlabel('Time (Ma)');
ylabel('[PO_4] (\mumol/kg)');
xlim(xlims);
ylim([0 8]);

end


function [vmin, vmax] = find_uncertainty_range(tgrid, range, rstruct, rfield)
% Find min, max of time-series variable v, where T = range{i}.T, v = range{i}.(rstruct).(rfield)
%
% Args:
%   tgrid (vector): time grid to interpolate to
%   range (cell array of model output): model output encompassing uncertainty range
%   rstruct (str): name of struct in model output 
%   rfield (str): name of field in model output,  so v = range{i}.(rstruct).(rfield)
% Returns:
%   vmin (vector): min v, interpolated to tgrid
%   vmax (vector): max v, interpolated to tgrid

% initialise to unlikely values
vmin = 1e30*ones(1, length(tgrid));
vmax = -1e30*ones(1, length(tgrid));

% iterate through supplied model output and update vmin, vmax
for i = 1:length(range)
    T = range{i}.T;
    v = range{i}.(rstruct).(rfield);

    vinterp = interp1(T, v, tgrid);

    vmin = min(vmin, vinterp);
    vmax = max(vmax, vinterp);
    
end

end


function addIDlbl(lbl)
% add lbl (eg 'A') to panel
text(0.9, 0.9, lbl, 'Units', 'normalized', 'FontSize', 14, 'FontWeight', 'bold');
end