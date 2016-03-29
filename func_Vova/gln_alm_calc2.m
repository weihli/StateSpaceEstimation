function [calc] = gln_alm_calc2(ns,  n0, tmdv, time_s0, alm_gln);          
%������� ���������� ����� ��������� �� ��� ��� ��������� L3

MU = 398600.4418;
imid = 63;                  %������� �������� ���������� ������
Rz = 6378.136;
WZ = 7.2921150*10^-5;

%�������� ������� � ������� ����������� ��� 1�� ����������� ����
deltat = (n0 - alm_gln.Na(ns)) *  86400 + tmdv - alm_gln.tc(ns);
%���������� ������
i = (imid/180 + alm_gln.dI(ns))*pi;
%����������������� ��������
n = 2*pi / (43200+alm_gln.dT(ns)+alm_gln.dTT(ns)*deltat/(43200+alm_gln.dT(ns)));
%���������� ������� ������� �������
a = (MU/(n*n))^(1/3);
%���������� �������� ��������� ����������� ������� ����������� ����
OMEGAv = -10*sqrt((Rz/a)^7)*cos(i)/86400/180;
%�������� ������� ������ ���
w = 5*sqrt((Rz/a)^7)*(5*(cos(i)*cos(i))-1)/86400/180;
%��������������� ��������
se = (sin(-( alm_gln.omegan(ns)+w*deltat)*pi))*sqrt(1-alm_gln.E(ns)*alm_gln.E(ns));
ce = alm_gln.E(ns) + cos(-( alm_gln.omegan(ns) +w*deltat)*pi);

Ew=atan2(se,ce);
% if ( ce > 0)
%     Ew = atan2(se,ce);
% elseif ((se>=0) && (ce<0))
%     Ew = pi+atan2(se,ce);
% elseif ((se<0) && (ce<0))
%     Ew = -pi+atan2(se,ce);
% elseif ((se>0) && (ce == 0))
%     Ew = pi/2;
% elseif ((se<0) && (ce == 0))
%     Ew = -pi/2;
% elseif ((se==0) && (ce == 0))
%     Ew = 0;
% end;

%���������� ������� �������� �� ������ ������
deltati = (Ew - alm_gln.E(ns)*sin(Ew))/n;
E_0 = n*(deltat+deltati);

E_pp = E_0;
E_npp = E_pp+1;
   
while (abs( E_npp - E_pp )>=10^-9)
    E_pp = E_npp;    
    E_npp = E_0 - alm_gln.E(ns)*sin(Ew);
end;
E = E_npp;
sSig = sqrt(1 - alm_gln.E(ns)*alm_gln.E(ns))*sin(E);
cSig = cos(E) - alm_gln.E(ns);
Sig  = atan2(sSig,cSig);
%�������� ������ 
u = Sig + (alm_gln.omegan(ns)+w*deltat)*pi;
%������ ������ �������
r  = a*(1 - alm_gln.E(ns)*cos(E));
OMEGA = alm_gln.Lam(ns)*pi + (OMEGAv-WZ)*deltat;

ax = cos(u)*cos(OMEGA)-sin(u)*sin(OMEGA)*cos(i);
ay = cos(u)*sin(OMEGA)+sin(u)*cos(OMEGA)*cos(i);
az = sin(u)*sin(i);

calc.x = r*ax;
calc.y = r*ay;
calc.z = r*az;

calc.vx = 1;
calc.vy = 1;
calc.vz = 1;

   
    