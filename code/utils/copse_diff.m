function [ tcomp, diff, diffRMS ] = copse_diff( tlimits, diffRMSmethod, timeA, fieldA, timeB, fieldB, tcstart )

% Calculate RMS difference of two time-series input fields
%   Both fields are interpolated to a common grid at 1e6 yr intervals

if nargin < 7
    tcstart = 2; %first point to include (ie omit first 1e6 yr to avoid startup transients)
end

%set region for error comparison with C514 output
tcomp = tlimits(1):1e6:tlimits(2); %uniform grid


%Interpolate onto tcomp grid for comparison
A_interp = interp1(timeA, fieldA,tcomp);

%Interpolate onto tcomp grid for comparison
B_interp = interp1(timeB, fieldB,tcomp);

diff = B_interp - A_interp;

switch diffRMSmethod
    case 'frac'
        diffRMS = sqrt(sum((diff(tcstart:end)./A_interp(tcstart:end)).^2)/length(diff(tcstart:end)));
    case 'diff'
        diffRMS = sqrt(sum(diff(tcstart:end).^2)/length(diff(tcstart:end)));
    otherwise
        error('unrecognized diffRMSmethod %s', diffRMSmethod);
end

end

