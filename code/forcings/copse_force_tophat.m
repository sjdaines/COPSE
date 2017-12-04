function tophat = copse_force_tophat(t, tstart, tend)
% handy top hat function for constructing perturbations to forcings etc
% tophat = copse_force_tophat(t, tstart, tend)
% 
% tophat = 1 for tstart < t < tend,  0 elsewhere

if (t > tstart) && (t < tend)
            tophat            = 1;
        else
            tophat            = 0;
end

end

