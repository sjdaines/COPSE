classdef paleo_local_paths_example
    % Global path defaults
    %
    % Copy and modify to define local output directory
    % 
    % paleo_local_paths.m   -- defines paths for all computers 
    % ['paleo_local_paths_' paleo_paths.getHostname() '.m'] -- defines paths for this computer only
    
    properties(Constant)
        %outputdir  = '..\..\..\..\PALEOoutput';
        %outputdir  = 'E:\Dropbox\PALEOoutput';
        %outputdir  = 'E:\PALEOoutput';
        outputdir = '/data/sd336/PALEOoutput';
        %outputdir  = 'I:\sd336\PALEOoutput';             
    end
    
   
end

