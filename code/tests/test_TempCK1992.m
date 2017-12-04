% Check numerical consistency of copse_TempCK1992 temperature function
% No implication the values used here are within the domain of validity of
% the approximation used
% See also copse_TempCK1992

presentluminosity = 1368;  %present day
tempcorrect = 0.194;
CtoK = 273.15;

%display pre-ind mean T
myfun = @(oldT) copse_TempCK1992(presentluminosity, 280e-6, oldT) + tempcorrect - oldT;
TempPreInd = fzero(myfun, [200 400]);
fprintf('TempPreInd %g C for pCO2 %g ppm\n',TempPreInd-CtoK, 280);

%check doesn't crash for wide range of parameter values
pCO2atmgrid=logspace(log10(20e-6),log10(20000e-6),100);
fraclumgrid=[1.1 1.0 0.8];

for j=1:length(fraclumgrid)
    luminosity = fraclumgrid(j)*presentluminosity;
    for i=1:length(pCO2atmgrid);
        % Example code to find solution iteratively:
        myfun = @(oldT) copse_TempCK1992(luminosity, pCO2atmgrid(i), oldT) + tempcorrect - oldT;
        Temp(i) = fzero(myfun, [200 400]);
        [ dummyuncorrectedT, albedo(i), Tgh(i), Teff(i) ] = copse_TempCK1992(luminosity, pCO2atmgrid(i), Temp(i));
    end
    
    subplot(2,3,j)
    semilogx(pCO2atmgrid,Temp-CtoK,pCO2atmgrid,Tgh,pCO2atmgrid,Teff-CtoK);
    h=legend('Temp','Tgh','Teff');
    legend boxoff;
    xlabel('pCO2 (atm)');
    ylabel('T C');
    title(sprintf('Solar lum %g %g W m^{-2}',fraclumgrid(j),luminosity));
    
    subplot(2,3,j+length(fraclumgrid))
    semilogx(pCO2atmgrid,albedo);
    xlabel('pCO2 (atm)');
    ylabel('albedo');
    title(sprintf('Solar lum %g %g W m^{-2}',fraclumgrid(j),luminosity));
end