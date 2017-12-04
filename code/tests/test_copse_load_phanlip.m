function test_copse_load_phanlip(lipvers)

% Test LIP and Vandermeer degassing forcings
% Updated for revised G3 paper

%version = 'G3sub'; 
%version = 'G3rev';




% present day CFB area
present_day_CFB_area = 4.8e6; % km2

switch lipvers
    case 'mills2014g3'
    
        smoothempl = false;
        LIPtrange = [-Inf Inf]; % include all lips
        
        % time grid for plotting CO2 release etc
        Tstart = -500e6;
        Tend = 0;
        tgrid = Tstart:1e4:Tend;
        
        % OIB area from degassing forcing
        % set extrapolation for oib_area to first/last datapoint 
        forcedegass = copse_force_vandermeer('Davg', 3);      
        % calculate forcings on tgrid 
        D=struct;
        Ddegasav = forcedegass.force(tgrid , D);
        forcedegass.estimate = 'Dmin';
        Ddegasmin = forcedegass.force(tgrid , D);
        forcedegass.estimate = 'Dmax';
        Ddegasmax = forcedegass.force(tgrid , D);

        
        % Compare OIB and LIP basalt area to precalculated composite datafile
        % time range to calculate RMS for basalt area
        t_area_comp_range = [-300e6 Inf];
        % select indices to include in RMS error calculation
        it = (tgrid > t_area_comp_range(1)) & (tgrid < t_area_comp_range(2));
        % error tolerance
        maxRMS = 1e-2;
        % Read precalculated composite basalt area
        forceba = copse_force_revision_ba('BAavg', 'g3supp');
        Dfield = 'BA';
        D = struct;
        Dbaavg = forceba.force(tgrid , D);
        forceba.estimate = 'BAmin';
        Dbamin = forceba.force(tgrid , D);
        forceba.estimate = 'BAmax';
        Dbamax = forceba.force(tgrid , D);
                       
    case 'copseRL'

        smoothempl = false;
        LIPtrange = [-Inf Inf]; % include all lips
        
        % time grid for plotting CO2 release etc
        Tstart = -800e6;
        Tend = 0;
        tgrid = Tstart:1e4:Tend;
        
        % OIB area from degassing forcing   
        forcedegass = copse_force_haq_D();      
        % calculate forcings on tgrid 
        D=struct;
        Ddegasav = forcedegass.force(tgrid , D);        
        Ddegasmin = Ddegasav;
        Ddegasmax = Ddegasav;
       
        % Compare OIB and LIP basalt area to precalculated composite datafile        
        % No precalculated total basalt area, so use G3
        fprintf('No precalculated total basalt area, comparing to G3 (2014)\n');
        % time range to calculate RMS for basalt area
        t_area_comp_range = [-300e6 Inf];
        % select indices to include in RMS error calculation
        it = (tgrid > t_area_comp_range(1)) & (tgrid < t_area_comp_range(2));
        % set error tolerance high to disable check
        maxRMS = 1;
        % Read precalculated composite basalt area
        forceba = copse_force_revision_ba('BAavg', 'g3supp');
        Dfield = 'BA';
        D = struct;
        Dbaavg = forceba.force(tgrid , D);
        forceba.estimate = 'BAmin';
        Dbamin = forceba.force(tgrid , D);
        forceba.estimate = 'BAmax';
        Dbamax = forceba.force(tgrid , D);
        
    case {'copseRL_jw', 'copseRL_jw_revisedAreas'}
        % work in progress extending LIP table
        smoothempl = false;
        LIPtrange = [-Inf Inf]; % include all lips
        
        % time grid for plotting CO2 release etc
        Tstart = -900e6;
        Tend = 0;
        tgrid = Tstart:1e4:Tend;
        
        % OIB area from degassing forcing   
        forcedegass = copse_force_haq_D();      
        % calculate forcings on tgrid 
        D=struct;
        Ddegasav = forcedegass.force(tgrid , D);        
        Ddegasmin = Ddegasav;
        Ddegasmax = Ddegasav;
       
        % Compare OIB and LIP basalt area to precalculated composite datafile               
        fprintf('comparing to copse_force_BA_jw\n');
        % time range to calculate RMS for basalt area
        t_area_comp_range = [-900e6 Inf];
        % select indices to include in RMS error calculation
        it = (tgrid > t_area_comp_range(1)) & (tgrid < t_area_comp_range(2));
        % set error tolerance high to disable check
        maxRMS = 1;
        % Read precalculated composite basalt area
        forceba = copse_force_BA_jw('BAavg');
        Dfield = 'BA';
        D = struct;
        Dbaavg = forceba.force(tgrid , D);
        forceba.estimate = 'BAmin';
        Dbamin = forceba.force(tgrid , D);
        forceba.estimate = 'BAmax';
        Dbamax = forceba.force(tgrid , D);    
          
    otherwise
        error('unrecognized lipvers %s', lipvers);
end


% Load the LIP database 
phanlip = copse_load_phanlip(lipvers);

% Create list of LIPs, no CO2
[forcegridlipsNoCO2, default_lambda, lipsNoCO2] = phanlip.create_LIP_forcing(Tstart, Tend, 'NoCO2', present_day_CFB_area, LIPtrange, smoothempl);
fprintf('default_lambda = %g yr-1 to match present day CFB area %g km2\n', default_lambda, present_day_CFB_area);
% composite forcing, no interpolation to grid
forcelipsNoCO2 = copse_force_composite(lipsNoCO2);

% Create list of all LIPs, with min and max CO2 release
% This should be two near-identical lists, differing only in 'co2_potential'
lipsCO2min = phanlip.create_LIPs('CO2min', default_lambda, LIPtrange, smoothempl);
lipsCO2max = phanlip.create_LIPs('CO2max', default_lambda, LIPtrange, smoothempl);
% composite forcing, no interpolation to grid
forcelipsCO2max = copse_force_composite(lipsCO2max);

% test 'high' value for basalt area, combination of x1.5 on area and delayed exponential weathering,
bahigh_areafac = 1.5;     % multiplier for LIP area 
bahigh_decayoffset = 1e7; %%% wait before erosion begins.
[forcegridlipsNoCO2highBA, bahigh_lamb, lipsNoCO2highBA] = phanlip.create_LIP_forcing(Tstart, Tend, 'NoCO2', present_day_CFB_area, LIPtrange, smoothempl, ...
                                                                              bahigh_areafac, bahigh_decayoffset);
fprintf('bahigh_lamb = %g yr-1 to match present day CFB area %g km2\n', bahigh_lamb, present_day_CFB_area);

% Build lists of LIP properties
[CFBNoCO2time, CFBNoCO2Area, ~] = merge_LIPs(lipsNoCO2);
[CFBtime, ~, CFB_CO2min] = merge_LIPs(lipsCO2min);
[CFBtime, ~, CFB_CO2max] = merge_LIPs(lipsCO2max);

%%%% plot bar chart of Phanerozoic CFB area
figure;

subplot(2,3,1);
bar(CFBNoCO2time,CFBNoCO2Area)
ylabel('Area (km^{2})')
xlabel('Time (Ma)')
title('Phanerozoic CFB area');

%%%% plot bar chart of CFB CO2 release

subplot(2,3,2)
bar(CFBtime,CFB_CO2min,'b')
ylabel('CO2 potential (min) (mol)')
xlabel('Time (Ma)')
title('CO2 potential (min)');

%%%% plot bar chart of total CO2 release
subplot(2,3,3)
bar(CFBtime,CFB_CO2max,'r') 
ylabel('CO2 potential (max) (mol)')
xlabel('Time (Ma)')
title('CO2 potential (max)');

%%% cumulative CO2 release
subplot(2,3,4);
D.CFB_area= zeros(1,length(tgrid));
D.LIP_CO2 = zeros(1,length(tgrid));
D.LIP_CO2moldelta = zeros(1,length(tgrid));
DAllCO2max = forcelipsCO2max.force(tgrid, D);
plot(tgrid,DAllCO2max.LIP_CO2);
title('CO2 release rate (max)')
ylabel('CO2 release (mol yr^{-1})');
xlabel('Time (Ma)')


%%% plot each individual CO2 release curve
subplot(2,3,5);
lgds = {};
for n = 1:length(lipsCO2max)
      D.CFB_area= zeros(1,length(tgrid));
      D.LIP_CO2 = zeros(1,length(tgrid));
      D.LIP_CO2moldelta = zeros(1,length(tgrid));
      D = lipsCO2max{n}.force(tgrid, D);

      plot(tgrid,D.LIP_CO2);
      lgds{end+1} = lipsCO2max{n}.Name;
    hold on
end
title('CO2 release rate (max, individual LIPS)')
ylabel('CO2 release (mol yr^{-1})');
xlabel('Time (Ma)')
legend(lgds);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Test CFB area forcing
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

figure;

% Plot CFB area for individual LIPs
subplot(2,3,1)
for n = 1:length(lipsNoCO2)
      D.CFB_area= zeros(1,length(tgrid));
      D.LIP_CO2 = zeros(1,length(tgrid));
      D.LIP_CO2moldelta = zeros(1,length(tgrid));
      D = lipsNoCO2{n}.force(tgrid, D);
      plot(tgrid,D.CFB_area);
      hold on
end

title('Area (continental LIPs) (km^2)')
ylabel('area km^2');
xlabel('Time (Ma)')

% Plot cumulative CFB area and OIB area
subplot(2,3,4)
% standard CFB area forcing
D.CFB_area= zeros(1,length(tgrid));
D.LIP_CO2 = zeros(1,length(tgrid));
D.LIP_CO2moldelta = zeros(1,length(tgrid));
DstandardCFB = forcelipsNoCO2.force(tgrid, D);
plot(tgrid,DstandardCFB.CFB_area,'g');
hold on
% overlay gridded version (should be identical)
D.CFB_area= zeros(1,length(tgrid));
D.LIP_CO2 = zeros(1,length(tgrid));
D.LIP_CO2moldelta = zeros(1,length(tgrid));
DgridCFB = forcegridlipsNoCO2.force(tgrid, D);
plot(tgrid,DgridCFB.CFB_area,'b');
hold on
% 'high' CFB area forcing
D.CFB_area= zeros(1,length(tgrid));
D.LIP_CO2 = zeros(1,length(tgrid));
D.LIP_CO2moldelta = zeros(1,length(tgrid));
DhighCFB = forcegridlipsNoCO2highBA.force(tgrid, D);
plot(tgrid,DhighCFB.CFB_area,'c');
hold on

%overlay OIB estimated from degassing forcing
plot(tgrid,Ddegasav.oib_area,'r')
plot(tgrid,Ddegasmin.oib_area,'r--')
plot(tgrid,Ddegasmax.oib_area,'r--')
title('Area: Cont LIPS (g,b, c high), OIB (r) (km^2)')
ylabel('area km^2');
xlabel('Time (Ma)')

presentdaybasaltarea = DstandardCFB.CFB_area(end) + Ddegasav.oib_area(end);
presentdaybasaltareahigh = DhighCFB.CFB_area(end) + Ddegasav.oib_area(end);
fprintf('present day (t=%g yr) basalt areas km2: CFB %g CFBhigh %g OIB (av) %g total %g total_high %g\n',...
    tgrid(end), DstandardCFB.CFB_area(end),DhighCFB.CFB_area(end), Ddegasav.oib_area(end), presentdaybasaltarea,presentdaybasaltareahigh);



% 'standard' LIP area
subplot(2, 3, 2);
plot(tgrid,(Ddegasav.oib_area + DstandardCFB.CFB_area)/presentdaybasaltarea ,'r')
hold on
plot(tgrid,(Ddegasmin.oib_area + DstandardCFB.CFB_area)/presentdaybasaltarea ,'r--')
plot(tgrid,(Ddegasmax.oib_area + DstandardCFB.CFB_area)/presentdaybasaltarea ,'r--')
if ~isempty(forceba)
    plot(tgrid,Dbaavg.(Dfield) ,'g')
    plot(tgrid,Dbamin.(Dfield) ,'g--')
    plot(tgrid,Dbamax.(Dfield) ,'g--')
end
title('OIB(av,min,max)+CFB(r), BA avg(g),min/max(g--)')
ylabel('Relative area')
xlabel('Time (Ma)')

subplot(2, 3, 5);
if ~isempty(forceba)
    barel_diff = (Ddegasav.oib_area + DstandardCFB.CFB_area)/presentdaybasaltarea-Dbaavg.(Dfield);
    % calculate mean sq error between precalculated basalt area and LIP-based calculation
    meansqerr_standard = (sum(barel_diff(it).^2)/length(tgrid(it)))^0.5;
    fprintf('mean sq error in total basalt area (%g < t < %g):  "standard" %g\n', ...
                                    t_area_comp_range(1), t_area_comp_range(2), meansqerr_standard);
    if meansqerr_standard > 1e-2
        warning('area comparison fails - error %g > %g', meansqerr_standard, maxRMS);
    end
    plot(tgrid, barel_diff);
    title('(OIB(av)+CFB(r))/(present day area) - BA (avg)')
    ylabel('diff normalized area')
    xlabel('Time (Ma)')
else
    title('No comparison total basalt area forcing');
end
    
% 'high' LIP area
subplot(2, 3, 3);
plot(tgrid,(Ddegasav.oib_area + DhighCFB.CFB_area)/presentdaybasaltareahigh ,'b')
hold on;
plot(tgrid,(Ddegasmin.oib_area + DhighCFB.CFB_area)/presentdaybasaltareahigh ,'b--')
plot(tgrid,(Ddegasmax.oib_area + DhighCFB.CFB_area)/presentdaybasaltareahigh ,'b--')
if ~isempty(forceba)
    plot(tgrid,Dbaavg.(Dfield) ,'g')
    plot(tgrid,Dbamin.(Dfield) ,'g--')
    plot(tgrid,Dbamax.(Dfield) ,'g--')
end
title('OIB(av,min,max)+CFB high(b), BA avg(g),min/max(g--)')
ylabel('Relative area')
xlabel('Time (Ma)')

subplot(2, 3, 6);
if ~isempty(forceba)
    % calculate mean sq error between precalculated basalt area and LIP-based calculation
    barelhigh_diff = (Ddegasav.oib_area + DhighCFB.CFB_area)/presentdaybasaltareahigh-Dbamax.(Dfield);
    meansqerr_high = (sum((barelhigh_diff(it)).^2)/length(tgrid(it)))^0.5;
    fprintf('mean sq error in total basalt area (%g < t < %g):  "high" %g\n', ...
                                    t_area_comp_range(1), t_area_comp_range(2), meansqerr_high);
    if meansqerr_high > 1e-2
        warning('area comparison fails - error %g > %g', meansqerr_high, maxRMS);
    end                            
    plot(tgrid, barelhigh_diff);
    title('(OIB(av)+CFB high(r))/(present day area) - BA (max)')
    ylabel('diff normalized area')
    xlabel('Time (Ma)')
else
    title('No comparison total basalt area forcing');
end

end

function [time, CFBArea, CO2] = merge_LIPs(lips)
    % merge lips occuring at same time
    % Args:
    %   lips (cell array of copse_force_LIP): lip forcings, possibly several events at same time
    % Returns:
    %   time (vector):  emplacement time
    %   CFBArea (vector): initial emplaced area
    %   CO2 (vector):   CO2

    time = []; CFBArea = []; CO2= [];
    
    % merge duplicate ages into one list
    curr_time = lips{1}.liptime;
    curr_area = lips{1}.peakCFBarea;
    curr_CO2 = lips{1}.co2_potential;

    for i=2:length(lips)
        if lips{i}.liptime ~= curr_time
            time(end+1) = curr_time;
            CFBArea(end+1) = curr_area;
            CO2(end+1) = curr_CO2;
            curr_time = lips{i}.liptime;
            curr_area = lips{i}.peakCFBarea;
            curr_CO2 = lips{i}.co2_potential;
        else
            curr_area = curr_area + lips{i}.peakCFBarea;
            curr_CO2 = curr_CO2 + lips{i}.co2_potential;
        end
    end
    time(end+1) = curr_time;
    CFBArea(end+1) = curr_area;
    CO2(end+1) = curr_CO2;
end
  