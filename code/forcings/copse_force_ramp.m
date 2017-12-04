classdef copse_force_ramp < copse_force
    %Generic ramp forcing, for specified field
    %
    % Examples: 'SHELFAREA'
    
    properties
        dfield;
        valfromto;
        tinterval;
        oper;
    end
    
    methods
        % Constructor. This enforces input of parameters when object is created
        function f = copse_force_ramp(dfield, fromto, tinterval, oper)
            f.dfield = dfield;
            f.valfromto = fromto;
            f.tinterval = tinterval;
            f.oper = oper;
        end
        function D = force(obj, tforce, D )
            val = interp1([-1e11 obj.tinterval(1) obj.tinterval(2) 1e11],...
                [obj.valfromto(1) obj.valfromto(1) obj.valfromto(2) obj.valfromto(2)],...
                tforce);
            switch obj.oper
                case '+'
                    D.(obj.dfield)           = D.(obj.dfield) + val;
                case '*'
                    D.(obj.dfield)           = D.(obj.dfield) * val;
                case '='
                    D.(obj.dfield)           =  val;
                otherwise
                    error('unknown oper %s',obj.oper);
            end
        end
    end
    
end