classdef paleo_modelbuilder
    % Create and configure a model from configuration file.
    %
    %
    methods(Static)
        function tm  = createModel(configfile, configname)
        
            LN = 'paleo_modelbuilder.createModel';  L = paleo_log.getLogger();
            
            % Read configuration from yaml file
            cfgset = paleo_parameterset(configfile, configname);

            % Create model:     
            % locate the relevant section in the cfg structure
            modelcfg = paleo_parameterset.findElem(cfgset.configdata, 'model');                   
            % create the model
            L.log(L.DEBUG, LN, sprintf('creating tm ctorstr=''%s''\n', modelcfg.class));                
            tm                                          = eval(modelcfg.class);
            
            %%%%%%%% Set forcing functions for this run
            tm.force = {};            
            forcecfg = paleo_parameterset.findElem(cfgset.configdata, 'model.force');           
            for i = 1:length(forcecfg)
                ctorstr = forcecfg{i};
                newforce = eval(ctorstr);
                tm.force{end+1} = newforce;
            end
            
            tm.perturb = {};
            perturbcfg = paleo_parameterset.findElem(cfgset.configdata, 'model.perturb');
            for i = 1:length(perturbcfg)
                ctorstr = perturbcfg{i};
                newperturb = eval(ctorstr);
                tm.perturb{end+1} = newperturb;
            end
            
            %%%%%%%%%% Set top-level parameters 
            tm.pars = cfgset.configureobject(tm.pars, 'model.pars', 'pars');
                                 
        end
        
    end
end


