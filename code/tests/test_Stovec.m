classdef test_Stovec
    % Test paleo_Stovec mapper
    
  
    methods(Static)
        function [stov, Sinit] = create()
            % test mapping S -> vec
            
            Sinit.A = 1;
            Sinit.B = 2;
            Sinit.C = 10:13;
            Sinit.D.dA = 100;
            Sinit.D.dB = 200;
            Sinit.D.dC = 1000:1003;
            Sinit.E.dA = 10000;
            Sinit.E.dB = 20000;
            Sinit.E.dC = 100000:100003;
            Sinit.E.dE = 100010:100013;
            
            Sinit
            Sinit.D
            Sinit.E
            
            %stov = paleo_Stovec(Sinit, 'field');
            stov = paleo_structtovec(Sinit, 1, 'field');
        end
        
        function [stov, Sinit] = StovtoS()
            [stov, Sinit] = test_Stovec.create();
            
            y = stov.struct2vector(Sinit);
            
            for i=1:length(y)
                fprintf('y(%g) = %g ',i,y(i));
            end
            fprintf('\n');
            
            Smap = stov.vector2struct(y');
            
            Smap
            
            ymap = stov.struct2vector(Smap);

            ndiff = 0;
            for i=1:length(y)
                fprintf('y(%g) = %g, ymap(%g) = %g, diff %g ',i,y(i),i,ymap(i));
                if ymap(i) ~= y(i)
                    ndiff = ndiff + 1;
                end
            end
            fprintf('\n');
            fprintf('ndiff %g\n',ndiff);
        end
    end
    
end

