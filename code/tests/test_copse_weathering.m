% Test copse weathering functions

CtoK = 273.15;

TgridC=linspace(5,30,100);

powT = 1;

for i=1:length(TgridC)
    f_T(i)=copse_f_T(TgridC(i)+CtoK);
    g_T(i)=copse_g_T(TgridC(i)+CtoK);
    pow_T(i)=power(TgridC(i)/15,powT);
end

figure;

subplot(1,2,1);
plot(TgridC,f_T,TgridC,g_T,TgridC,pow_T);
xlabel('T C');
ylabel('Relative weath rate');
legend('f_T (sil)','g_T (carb)',sprintf('pow T %g',powT));
title('T dependence');

CO2gridPAL=logspace(-1,2,100);

for i=1:length(CO2gridPAL)
    preplant(i) = CO2gridPAL(i)^0.5 ;
    plant(i) = ( 2*CO2gridPAL(i) / (1 + CO2gridPAL(i)) )^0.4  ;
end

plantenhance =0.15;

subplot(1,2,2);
semilogx(CO2gridPAL,plantenhance*preplant,CO2gridPAL,(1-plantenhance)*plant);
xlabel('pCO2 (PAL)');
ylabel('Relative weath rate');
legend(sprintf('preplant*%g',plantenhance),sprintf('plantenhance*%g',(1-plantenhance)));
title('pCO_2 dependence');
