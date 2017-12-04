function strct = copse_modify_struct( strct, fld, newval )
%Modify a struct, error if field doesn't already exist

if ~isfield(strct,fld)
    error ('struct "%s" no field "%s"',inputname(1),fld); 
end

strct.(fld)=newval;

end

