classdef copse_force_composite < copse_force
    % Container for multiple forcings.
    % Option to pre-calculate interpolation to a supplied time grid.
    %
    %
    properties
        fastinterp=0  % if using tgrid, set to 1 to enable fast interpolation (no error checking !)
    end
    properties(SetAccess=private)  % can be read, but not written to
        forcings;     % cell array of forcings 
        tgrid=[];     % optional grid to precalculate forcings on for speed
        dfields;      % is using tgrid, supply list of fields used {'field1', 'field2', ...}
        dfieldstoset  % if using tgrid, supply flags to define set=1 or add=0  [1 0 1 ...]  
        Dgrid;        % gridded forcings;
    end
    
    methods
        
        function f = copse_force_composite(forcings, tgrid, dfields, dfieldstoset)
            % Constructor.
            %
            % Args:
            %   forcings (cell array):  list of copse_force_XXX instances
            %   tgrid (vector, optional): time grid to pre-calculate interpolation
            %   dfields (cell array, optional): list of fields to expect for pre-calulated interpolation
            %   dfieldstoset (vector, optional): per-field flag, true to set this field, false to add to this field
            
            f.forcings = forcings;          
            if nargin > 1     
                f.tgrid = tgrid;
                f.dfields = dfields;
                f.dfieldstoset = dfieldstoset;
                f.calcgrid();
            end
            
        end
        
        function D = force(obj, tforce_or_tmodel, D)
            % dispatch to appropriate handler
            if isempty(obj.tgrid)
                % apply list of forcings
                D = force_individual(obj, tforce_or_tmodel, D);
            else
                % use pre-calculated interpolation
                D =       force_grid(obj, tforce_or_tmodel, D);
            end
        end
        
        function D = force_individual(obj, tforce_or_tmodel, D)
            % iterate through the list of forcings, accumulating into D
            for i = 1:length(obj.forcings)
                D = obj.forcings{i}.force(tforce_or_tmodel, D);
            end
        end
                     
        function calcgrid(obj)
            % calculate gridded forcings
            D = struct;
            for i=1:length(obj.dfields)
                D.(obj.dfields{i}) = 0;
            end
            
            obj.Dgrid = obj.force_individual(obj.tgrid,D);                        
        end
        
        function D = force_grid(obj, tforce_or_tmodel, D)
            % calculate forcing by interpolating from grid
            for i=1:length(obj.dfields)
                if obj.fastinterp % fast interp1, requires column vectors
                    interpval = interp1qr(obj.tgrid',obj.Dgrid.(obj.dfields{i})',tforce_or_tmodel')';
                else
                    interpval = interp1(obj.tgrid,obj.Dgrid.(obj.dfields{i}),tforce_or_tmodel);
                end
                if obj.dfieldstoset(i)
                    D.(obj.dfields{i}) = interpval;
                else
                    D.(obj.dfields{i}) = D.(obj.dfields{i}) + interpval;
                end
            end
        end
    end
end

