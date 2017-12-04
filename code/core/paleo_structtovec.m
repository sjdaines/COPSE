classdef paleo_structtovec < handle
    %  Map state variables and diagnostics from y linear vector (used by ODE integrators) to/from named fields in struct
    
    properties(SetAccess = private)
        name = '';            % convenience - label this instance
        
        packorder;            % 'field' (y packing f1 cell1-f2 .. celln-f2 .. fn), 'cell' (y packing cell1-f1, cell1-f2, ..., cell2-f1  etc)
     
        IM        = struct;   % Datastructure mapping  S.(field) <==>  Y(IM.(field))
        
        istart    = 1;        % first Y index for our mapping
        ilength   = 0;        % total number of elements in our mapping
        
    end
    
    properties(Access=private)
       % cache top-level field names and type as the test for structure is a slowish op
       strnm     = {};       %  strnm = fields(IM) 
       strfld    = [];       % logical strfld(i) = isstruct(IM.(strnm{i})) 
                            
    end

    
    methods
        function obj = paleo_structtovec(S, istart, packorder)
            % Initialise 'IM' mapping
            % S should be a struct with the correct variable dimensions (scalars, vectors)
            
            if ~strcmp(packorder,'field')
                error('packorder %s not supported',packorder)
            end
            
            obj.istart = istart;
            
            obj.packorder = packorder;
            
            % recursively iterate through S and define mapping
            
            [obj.IM, iend] = obj.addFields(obj.IM, S,istart,1);
            obj.ilength = iend  - istart;
        end
        
       
            
        function S=vector2struct(obj, Y)
            % Convert row vector Y to struct S 
            
            if length(Y) ~= obj.ilength
                error('paleo_structtovec.vector2struct length(Y) %g ~= ilength %g', length(Y), obj.ilength);
            end
            
            S = struct;
            
            imt = obj.IM;
           
            sf = obj.strnm;
            for i=1:length(sf)
                if obj.strfld(i)
                    ims = imt.(sf{i});
                    Ssub = struct;
                    ssf = fields(ims);
                    for j=1:length(ssf)
                        Ssub.(ssf{j}) = Y(ims.(ssf{j}));
                    end
                    S.(sf{i}) = Ssub;
                else
                    S.(sf{i})=Y(imt.(sf{i}));
                end
            end

        end
        
        function S=matrix2struct(obj, Y)
            % Convert matrix Y to struct S 
            
            if size(Y,2) ~= obj.ilength
                error('paleo_structtovec.matrix2struct size(Y,2) %g ~= ilength %g', size(Y,2), obj.ilength);
            end
            
            S = struct;
                   
            sf = obj.strnm;
            
            for i=1:length(sf)
                if obj.strfld(i)
                    ims = obj.IM.(sf{i});
                    Ssub = struct;
                    ssf = fields(ims);
                    for j=1:length(ssf)
                        Ssub.(ssf{j}) = Y(:,ims.(ssf{j}));
                    end
                    S.(sf{i}) = Ssub;
                else
                    S.(sf{i})=Y(:,obj.IM.(sf{i}));
                end
            end

        end
        
        function Y=struct2vector(obj, S, sidx)
            % CConvert struct S to column vector y
            % check S against fieldnames in Sfieldnames for any extra fields inadvertently added as a result of typos...
            % Optional argument sidx select record sidx from S (cf default case for single record in S)
            if nargin < 3
                sidx = 1;
            end
        
            % preallocate column vector y for speed
            Y=zeros(obj.ilength,1);
            imt = obj.IM;
           
            sf = obj.strnm;
            
            if length(sf) ~= length(fieldnames(S))
                imt
                S
                error('paleo_structtovec.struct2vector Sfieldnames %g != S %g',length(sf),length(fieldnames(S)));
            end
            
            for i=1:length(sf)
                if obj.strfld(i)
                    ims = imt.(sf{i});
                    Ssub = S.(sf{i});                    
                    ssf = fieldnames(ims);
                    if length(ssf) ~= length(fieldnames(Ssub))
                        ims
                        Ssub
                        error('paleo_structtovec.struct2vector %s.Sfieldnames %g != S %g',sf{i},length(ssf),length(fieldnames(Ssub)));
                    end
                    for j=1:length(ssf)
                       Y(ims.(ssf{j})) = Ssub.(ssf{j})(sidx,:);
                    end                    
                else
                    Y(imt.(sf{i}))= S.(sf{i})(sidx,:);
                end
            end
        end
        
        function yidx = ridx(obj, Sname, obidx)
            % index into y vector of top-level field name Sname
            if nargin > 2
                yidx = obj.idx('',Sname,obidx);
            else
                yidx = obj.idx('',Sname);
            end
        end
        
        function yidx = idx(obj, groupname, Sname, obidx)
            % index into y vector of (optional subset obidx) of (vector) tracer field name Sname
            % Convenience function equivalent to:
            %    IM.(Sname)(obidx)            
            %    IM.(groupname).(Sname)(obidx)  if field present
            %    []   (empty array)             if field absent
            %
            % groupname - '' for top level, otherwise obj.IM.(groupname)
            % sidx   --   index of field S in list of fields
            % obidx  --   list of indices of subset of ocean boxes
           
            yidx = [];
            
            if isempty(groupname)
                if isfield(obj.IM,Sname)
                    yidx = obj.IM.(Sname);
                end
            else
                if isfield(obj.IM.(groupname),Sname)
                    yidx = obj.IM.(groupname).(Sname);
                end
            end
            
            if nargin > 3 && ~isempty(yidx)
                yidx = yidx(obidx);
            end
        end
        
         function [imap, icurrent] = addFields(obj, imap, S, icurrent, lvl)
            % add fields recursively to imap from S
            
            if lvl > 2
                error('only single level of substructure supported');
            end
            
            sftmp = fields(S);
            % put scalar (top-level) fields at beginning of list to help Jacobian inverse memory consumption
            sfscalar = {};
            sfvector = {};
            for i = 1:length(sftmp)
                isstr = isstruct(S.(sftmp{i}));
                if lvl == 1
                    % optimisation - cache top-level field names and type for future speed
                    obj.strnm{i}  = sftmp{i};
                    obj.strfld(i) = isstr;
                end
                if isstr
                    sfvector{end+1} = sftmp{i};
                else
                    sfscalar{end+1} = sftmp{i};
                end
            end
            
            % add scalars
            for i = 1:length(sfscalar)
                imap.(sfscalar{i}) = icurrent -1 + (1:length(S.(sfscalar{i})));
                icurrent = icurrent + length(S.(sfscalar{i}));
                
            end
            % recurse into vectors
            for i = 1:length(sfvector)
                % recurse into substruct
                [imap.(sfvector{i}), icurrent] = obj.addFields(struct, S.(sfvector{i}),icurrent,lvl+1);
            end
        end
            

        
    end
    
    methods(Static)
        function diag = addRecord(diag, idiag,  D)
            % Accumulate records in struct (with one level of nesting) to end of struct-of-vectors
            %Store diagnostic variables in global struct diag for future analysis:
            % add record D as entry idiag in accumulated struct diag

            Dfields=fieldnames(D);
            for i=1:length(Dfields)
                if isstruct(D.(Dfields{i}))
                    DDfields = fieldnames(D.(Dfields{i}));
                    for j = 1:length(DDfields)
                        diag.(Dfields{i}).(DDfields{j})(idiag,:) = D.(Dfields{i}).(DDfields{j});
                    end
                else
                    diag.(Dfields{i})(idiag,:)=D.(Dfields{i});
                end
            end
        end
        
        function diag = addNumRecord(diag, idiag,  fromdiag, ifromdiag)
            % As addRecord, with choice of specified record idx from input fromdiag 
            % add record fromdiag(ifromdiag) as entry idiag in accumulated struct diag

            Dfields=fieldnames(fromdiag);
            for i=1:length(Dfields)
                if isstruct(fromdiag.(Dfields{i}))
                    DDfields = fieldnames(fromdiag.(Dfields{i}));
                    for j = 1:length(DDfields)
                        diag.(Dfields{i}).(DDfields{j})(idiag,:) = fromdiag.(Dfields{i}).(DDfields{j})(ifromdiag,:);
                    end
                else
                    diag.(Dfields{i})(idiag,:)=fromdiag.(Dfields{i})(ifromdiag,:);
                end
            end
        end
        
        function [S, foundnan] = adddeltat(S, deltat,  dSdt, checknan)
            % S = S + deltat * dSdt 
            % where S, dSdt are structs with up to one level of nesting

            foundnan = false;
            Sfields=fieldnames(S);
            for i=1:length(Sfields)
                if isstruct(S.(Sfields{i}))
                    SSfields = fieldnames(S.(Sfields{i}));
                    for j = 1:length(SSfields)
                        S.(Sfields{i}).(SSfields{j}) = S.(Sfields{i}).(SSfields{j}) + deltat*dSdt.(Sfields{i}).(SSfields{j});
                        if checknan && any(isnan(S.(Sfields{i}).(SSfields{j})))
                            warning('nan in S.%s.%s',Sfields{i},SSfields{j});
                            foundnan = true;
                        end
                    end
                else
                    S.(Sfields{i}) = S.(Sfields{i}) + deltat*dSdt.(Sfields{i}); 
                    if checknan && any(isnan(S.(Sfields{i})))
                            warning('nan in S.%s',Sfields{i});
                            foundnan = true;
                    end
                end
            end
        end
        
        function Sinterp = interpt(Sinterp, Soffline, tidx, interpfac)                        
            % linearly interpolate S or D vector
            if length(tidx) > 2
                error('interpolation max 2 records');
            end
            
            Sfields=fieldnames(Soffline);
            for i=1:length(Sfields)
                if isstruct(Soffline.(Sfields{i}))
                    SSfields = fieldnames(Soffline.(Sfields{i}));
                    for j = 1:length(SSfields)
                        Sinterp.(Sfields{i}).(SSfields{j}) = interpfac(1)*Soffline.(Sfields{i}).(SSfields{j})(tidx(1),:);
                        if length(interpfac) > 1
                            Sinterp.(Sfields{i}).(SSfields{j}) = Sinterp.(Sfields{i}).(SSfields{j}) + interpfac(2)*Soffline.(Sfields{i}).(SSfields{j})(tidx(2),:);
                        end
                    end
                else
                    Sinterp.(Sfields{i}) = interpfac(1)*Soffline.(Sfields{i})(tidx(1),:);
                    if length(interpfac) > 1
                        Sinterp.(Sfields{i}) = Sinterp.(Sfields{i}) + interpfac(2)*Soffline.(Sfields{i})(tidx(2),:);
                    end
                end
            end
            
        end
        
        function Swsum = weightsum(Swsum, Soffline, tidx, whtfac)                        
            % construct weighted sum for records tidx, weight factors whtfac
            
            % convert input from (possibly) row vectors to column vectors
            tidx = reshape(tidx,[],1);
            whtfac = reshape(whtfac,[],1);
          
            
            Sfields=fieldnames(Soffline);
            for i=1:length(Sfields)
                if isstruct(Soffline.(Sfields{i}))
                    SSfields = fieldnames(Soffline.(Sfields{i}));
                    for j = 1:length(SSfields)
                        lgthrec = size(Soffline.(Sfields{i}).(SSfields{j}),2);
                        whtrep = repmat(whtfac, 1, lgthrec);
                        Swsum.(Sfields{i}).(SSfields{j}) = sum(whtrep.*Soffline.(Sfields{i}).(SSfields{j})(tidx,:),1);                       
                    end
                else
                    lgthrec = size(Soffline.(Sfields{i}),2);
                    whtrep = repmat(whtfac,1, lgthrec);
                    Swsum.(Sfields{i}) = sum(whtrep.*Soffline.(Sfields{i})(tidx,:),1);                       
                end
            end
            
        end
    end
end

