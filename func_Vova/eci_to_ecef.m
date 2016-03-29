function [satpos_ecef] =eci_to_ecef(s0, ti, satpos_eci) 
%��� �������:eci_to_ecef 
%������� �������������� ��������� 
%������� ������: s0 - �������� �������� ����� � ������� ������ ���������� , 
%ti - ������� �����; satpos_eci  
%��������� satpos_eci 
%satpos_eci.x -  ���������� x � ���������� ����������� ������� ��������� (ECI); 
%satpos_eci.y - ����������  y � ���������� ����������� ������� ��������� (ECI); 
%satpos_eci.z - ����������  z � ���������� ����������� ������� ��������� (ECI); 
%satpos_eci.vx - �������� vx � ���������� ����������� ������� ��������� (ECI);  
%satpos_eci.vy - �������� vy � ���������� ����������� ������� ��������� (ECI); 
% satpos_eci.vz - �������� vz � ���������� ����������� ������� ��������� (ECI); 
%�������� ������: 
% ��������� satpos_ecef  
%satpos_ecef.x - ���������� x � ��������� ������� ��������� (ECEF); 
%satpos_ecef.y - ���������� y � ��������� ������� ��������� (ECEF); 
%satpos_ecef.z - ���������� z � ��������� ������� ��������� (ECEF); 
%satpos_ecef.vx - �������� �� ��� x � ��������� ������� ��������� (ECEF); 
%satpos_ecef.vy - �������� �� ��� z � ��������� ������� ��������� (ECEF); 
%satpos_ecef.vz-  �������� �� ��� z � ��������� ������� ��������� (ECEF); 
%������������ 
% SEC_IN_RAD - ����������� �������������� ������ � ������� 
%  s0(radian) = s0 (sek) * SEC_IN_RAD, where 
 % SEC_IN_RAD = 2 * pi / (24 * 3600)  = pi / 43200 
 SEC_IN_RAD = pi / 43200; 
 OMEGA_Z  = 0.7292115e-4;  %( ��������  ��������  ����� (angular speed of rotation of the Earth, ���/cek)  
    s_zv = s0 * SEC_IN_RAD + OMEGA_Z * ti; 
    cos_s = cos(s_zv); 
    sin_s = sin(s_zv); 
 
    satpos_ecef.x =  satpos_eci.x * cos_s + satpos_eci.y * sin_s; 
    satpos_ecef.y = -satpos_eci.x * sin_s + satpos_eci.y * cos_s; 
    satpos_ecef.z =  satpos_eci.z; 
 
    satpos_ecef.vx =  satpos_eci.vx * cos_s + satpos_eci.vy * sin_s + OMEGA_Z * satpos_ecef.y; 
    satpos_ecef.vy = -satpos_eci.vx * sin_s + satpos_eci.vy * cos_s - OMEGA_Z * satpos_ecef.x; 
    satpos_ecef.vz =  satpos_eci.vz; 
