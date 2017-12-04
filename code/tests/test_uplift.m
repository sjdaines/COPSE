% plot erosion / uplift forcings

tgrid = -600e6:1e6:0;
D.UPLIFT=zeros(1,length(tgrid));

% Bergman (2004) COPSE forcings
udwe_bergman2004 = copse_force_UDWEbergman2004(0);
udwe_bergman2004.doD = 0;
udwe_bergman2004.doW = 0;
udwe_bergman2004.doE = 0;

Dberg2004 = udwe_bergman2004.force(tgrid,D);

% Berner / Ronov GEOCARB III (2001) uplift
u_br = copse_force_U_berner_ronov(0);
Dbr       = u_br.force(tgrid,D);

figure;
plot(tgrid,Dberg2004.UPLIFT);
hold all
plot(tgrid,Dbr.UPLIFT);
legend('Berg2004','GEOCARBIII');
xlabel('time yr');
ylabel('Uplift/erosion (rel)');

% Godderis (2014) Paleogeog weathering enhancement

pg = copse_force_PG_godderis(0);
D.PG = zeros(1,length(tgrid));
Dpg = pg.force(tgrid,D);

figure;
plot(tgrid,Dpg.PG);
xlabel('time yr');
ylabel('Paleogeog (rel)');





