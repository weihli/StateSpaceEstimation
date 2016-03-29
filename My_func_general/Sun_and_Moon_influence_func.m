%% ������� ������� ��������� �� ���� � ������ �� �������� ����� �������� ��������
% �� ��� ������� �.3.1.1
%aster==asterisk==* - � ������ ����������
function [Sun, Moon]=Sun_and_Moon_influence_func(T_in,Coord)
%% ������� ������:
%T_in - ������� �����, �� ������� ���������� ��������� ����������� ������ � ����
%Coord - ������ ���������. Coord(1) - x; Coord(2) - y; Coord(3) - z
%�������� ������
%Sun - ������ ��������� �� ������, 1-x; 2-y; 3-z;
%Moon - ������ ��������� �� ����, 1-x; 2-y; 3-z;
%% 
% Constant
Mu_sun = 0.1325263e12; %[��^3/�^2] - ��������� ��������������� ���� ������
Mu_moon = 4902.835; %[��^3/�^2] - ��������� ��������������� ���� ����

A_sun = 1.49598e8;%������� ������� �������� ������
A_moon = 3.84385243e5;%������� ������� ������ ����

e_sun = 0.016719;%�������������� ��������� ��������
e_moon = 0.054900489;%�������������� ������ ������,

i_moon = 0.0898041080;%[���] - ������� ���������� ������ ���� � ��������� ���������

q_moon = 2.3555557435 + 8328.6914257190*T_in + 0.0001545547*T_in^2;%[���] - ������� �������� ����
q_sun = 6.2400601269 + 628.3019551714*T_in - 0.0000026820*T_in^2;%[���] - ������� �������� ������

Omega_moon = 2.1824391966 - 33.7570459536*T_in + 0.0000362262*T_in^2;%[���] - ������� ������� ����������� ���� ����

G_moon = 1.4547885346 + 71.0176852437*T_in - 0.0001801481*T_in^2;%[���] - ������� ������� ������� ������ ����

W_sun = -7.6281824375 + 0.0300101976*T_in + 0.0000079741*T_in^2;%[���] - ������� ����������� ������� ������� ������ ������,

Epsilon = 0.4090926006 - 0.0002270711*T_in;%[���] - ������� ������ ��������� � ��������

F_aster = cos(Omega_moon)*sin(i_moon);
Etta_aster = sin(Omega_moon)*sin(i_moon);
E_aster = ( cos(i_moon) );

E11=sin(Omega_moon)*cos(Omega_moon)*(1-cos(i_moon));
E12=1-( sin(Omega_moon) )^2*(1-cos(i_moon));

Etta11=E_aster*cos(Epsilon) - F_aster*sin(Epsilon);
Etta12=E11*cos(Epsilon) + Etta_aster*sin(Epsilon);

F11=E_aster*sin(Epsilon) + F_aster*cos(Epsilon);
F12=E11*sin(Epsilon) +  Etta_aster*cos(Epsilon);

%% Kepler's equation for Sun
Excentr_anom_sun = q_sun;
i = 2;
while abs( q_sun+e_sun*sin( Excentr_anom_sun ) - Excentr_anom_sun ) >= 1e-8
    Excentr_anom_sun = q_sun+e_sun*sin( Excentr_anom_sun );    
    i=i+1;
end;

%% Kepler's equation for Moon
Excentr_anom_moon = q_moon;
while abs( q_moon+e_moon*sin( Excentr_anom_moon ) - Excentr_anom_moon ) >= 1e-8
    Excentr_anom_moon = q_moon+e_moon*sin( Excentr_anom_moon );
    i=i+1;
end;

%% Other constants

Sin_Fi_sun=( sqrt(1-e_sun^2)*sin(Excentr_anom_sun) )/( 1-e_sun*cos(Excentr_anom_sun) );
Cos_Fi_sun=( cos(Excentr_anom_sun) - e_sun )/( 1-e_sun*cos(Excentr_anom_sun) );

Sin_Fi_moon=( sqrt(1-e_moon^2)*sin(Excentr_anom_moon) )/( 1-e_moon*cos(Excentr_anom_moon) );
Cos_Fi_moon=( cos(Excentr_anom_moon) - e_moon )/( 1-e_moon*cos(Excentr_anom_moon) );

E_moon=(Sin_Fi_moon*cos(G_moon)+Cos_Fi_moon*sin(G_moon) )*E11+( Cos_Fi_moon*cos(G_moon) - Sin_Fi_moon*sin(G_moon) )*E12;
Etta_moon=( Sin_Fi_moon*cos(G_moon) + Cos_Fi_moon*sin(G_moon) )*Etta11+( Cos_Fi_moon*cos(G_moon) - Sin_Fi_moon*sin(G_moon) )*Etta12;
F_moon=( Sin_Fi_moon*cos(G_moon) + Cos_Fi_moon*sin(G_moon) )*F11+( Cos_Fi_moon*cos(G_moon) - Sin_Fi_moon*sin(G_moon) )*F12;
r_moon=A_moon*( 1-e_moon*cos(Excentr_anom_moon) );

E_sun=Cos_Fi_sun*cos(W_sun) - Sin_Fi_sun*sin(W_sun);
Etta_sun=( Sin_Fi_sun*cos(W_sun) + Cos_Fi_sun*sin(W_sun) )*cos(Epsilon);
F_sun=( Sin_Fi_sun*cos(W_sun) + Cos_Fi_sun*sin(W_sun) )*sin(Epsilon);
r_sun=A_sun*( 1-e_sun*cos(Excentr_anom_sun) );
%-----------------------------------------------------------
%% Calculation of accelerations

X_norm_sun = Coord( 1 ) / r_sun;
Y_norm_sun = Coord( 2 ) / r_sun;
Z_norm_sun = Coord( 3 ) / r_sun;
Mu_norm_sun = Mu_sun / r_sun^2;
delta_sun = sqrt( ( E_sun - X_norm_sun)^2 + ( Etta_sun - Y_norm_sun )^2 + ( F_sun - Z_norm_sun )^2 );

Sun(1) = Mu_norm_sun*( ( E_sun - X_norm_sun )/delta_sun^3 - E_sun );
Sun(2) = Mu_norm_sun*( ( Etta_sun - Y_norm_sun )/delta_sun^3 - Etta_sun );
Sun(3) = Mu_norm_sun*( ( F_sun - Z_norm_sun )/delta_sun^3 - F_sun );

X_norm_moon = Coord( 1 ) / r_moon;
Y_norm_moon = Coord( 2 ) / r_moon;
Z_norm_moon = Coord( 3 ) / r_moon;
Mu_norm_moon = Mu_moon / r_moon^2;
delta_moon = sqrt( ( E_moon - X_norm_moon )^2 + ( Etta_moon - Y_norm_moon )^2 + ( F_moon - Z_norm_moon )^2 );

Moon(1) = Mu_norm_moon*( ( E_moon - X_norm_moon )/delta_moon^3 - E_moon );
Moon(2) = Mu_norm_moon*( ( Etta_moon - Y_norm_moon )/delta_moon^3 - Etta_moon );
Moon(3) = Mu_norm_moon*( ( F_moon - Z_norm_moon )/delta_moon^3 - F_moon );
