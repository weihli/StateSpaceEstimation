function [satpos_eci] = ecef_to_eci(S, satpos_ecef) 
%��� �������:eci_to_ecef 
%������� �������������� ��������� 
%������� ������: 
%S - ������� ��������� �������������� �� ������������ ������������
%��������� satpos_eci 
%satpos_ecef.x -  ���������� x � ��������� ������� ��������� (ECEF); 
%satpos_ecef.y - ����������  y � ��������� ������� ��������� (ECEF); 
%satpos_ecef.z - ����������  z � ��������� ������� ��������� (ECEF); 
%satpos_ecef.vx - �������� vx � ��������� ������� ��������� (ECEF); 
%satpos_ecef.vy - �������� vy � ��������� ������� ��������� (ECEF); 
% satpos_ecef.vz - �������� vz � ��������� ������� ��������� (ECEF);

%�������� ������: 
% ��������� satpos_eci  
%satpos_eci.x - ���������� x � ���������� ����������� ������� ��������� (ECI); 
%satpos_eci.y - ���������� y � ���������� ����������� ������� ��������� (ECI);
%satpos_eci.z - ���������� z � ���������� ����������� ������� ��������� (ECI);
%satpos_eci.vx - �������� �� ��� x � ���������� ����������� ������� ��������� (ECI); 
%satpos_eci.vy - �������� �� ��� z � ���������� ����������� ������� ��������� (ECI);
%satpos_eci.vz-  �������� �� ��� z � ���������� ����������� ������� ��������� (ECI); 
%������������ 
global GL_W_rot_Earth
    A_trans=[cos(S) -sin(S) 0;...
                    sin(S)  cos(S) 0;...
                       0          0     1];% ������� ��������
              
    W=[0 -GL_W_rot_Earth 0;GL_W_rot_Earth 0 0;0 0 0];%������� ������� ���������
    
    
    oxyz = [satpos_ecef.x; satpos_ecef.y; satpos_ecef.z];
    voxyz = [satpos_ecef.vx; satpos_ecef.vy; satpos_ecef.vz];
    
    
    outxyz=A_trans*oxyz;
    voutxyz=A_trans*voxyz+W*outxyz;
       
    satpos_eci.x =  outxyz(1); 
    satpos_eci.y =  outxyz(2); 
    satpos_eci.z =  outxyz(3);
    %���������� �� ����������
    satpos_eci.vx = voutxyz(1);
    satpos_eci.vy = voutxyz(2);
    satpos_eci.vz = voutxyz(3);
