% compare Mills etal (2014) G3 basalt area forcing from supp info vs xls in COPSE tree

rba_xls = copse_force_revision_ba('BAavg', 'xls');
rba_g3 = copse_force_revision_ba('BAavg', 'g3supp');

rba_diff = rba_xls.data.BAavg - rba_g3.data.BAavg;
figure; plot(rba_xls.data.timeMa, rba_diff);
xlabel('T (Ma)');
title('Basalt area forcing G3 supp - COPSE xls');
ylabel('diff .mat - .xls');