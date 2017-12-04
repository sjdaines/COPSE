function [ yi ] = copse_interp1( x, Y, xi )
% COPSE_INTERP1  Wrapper for alternative 1-d interpolation functions
%
%   Matlab interp1 is remarkably slow but safe. Fast routines do no error checking.
%   This wrapper allows easy switching so if speed becomes an issue, 
%   we can temporarily switch to fast interpolation.
%   Default setting should be interp1 so we catch errors.

%yi = interp1(x,Y,xi);
yi = interp1qr(x,Y,xi);  % this imposes an additional requirement for x , xi to be _column_ vectors


end

