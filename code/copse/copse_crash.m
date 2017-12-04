function output = copse_crash(value,label,tmodel)
% COPSE_CRASH COPSE 5_14 Enforce +ve reservoir values by limiting fluxes at small reservoir sizes (??)
% output = 1 ie independent of 'value' for 'value' > 0.1 (implicitly the
% usual range), but limited towards zero for 'value' < 0.1

valuelowlimit = 0.1;
if value > valuelowlimit
    output = 1 ;
elseif value > 0
    output = value*1.0/valuelowlimit;
    fprintf('copse_crash %s value %g tmodel %g\n',label,value,tmodel);
else
    output=0;
    fprintf('copse_crash %s value %g tmodel %g\n',label,value,tmodel);
end

end
