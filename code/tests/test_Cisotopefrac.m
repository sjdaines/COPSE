% test_Cisotopefrac Plot copse_Cisotopefrac for testing
%
% See also: copse_Cisotopefrac

pCO2PAL=[1 10 1 10];
pO2PAL=[1 1 0.1 0.1];

TC=linspace(-10,30,100);

for j=1:4
for i=1:length(TC)
    [d_locb(i), D_P(i), d_mocb(i), D_B(i), d_mccb(i), d_ocean(i), d_atmos(i)]=copse_Cisotopefrac(TC(i)+273,pCO2PAL(j),pO2PAL(j));
end

subplot(2,2,j);

plot(TC,d_mccb,TC,d_mocb, TC,d_locb,TC,d_ocean,TC,d_atmos,TC,D_B,'--',TC,D_P,'--');
xlabel('T C');
ylabel('\delta^{13}C per mille');
title(sprintf('pCO2PAL %g pO2PAL %g',pCO2PAL(j),pO2PAL(j)));

h=legend('d_mccb','d_mocb','d_locb','d_ocean','d_atmos','D_B','D_P');
legend boxoff;
set(h,'Interpreter','none');

ylim([-40 40]);
end