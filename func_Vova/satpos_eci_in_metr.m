function [satpos_eci, satpos_gln] = satpos_eci_in_metr(satpos_eci); 
 %��� �������: satpos_eci_in_metr 
 %������� ����������� ���������� satpos_eci (���������), �������� � ���������� � ���������� 
 %satpos_eci, satpos_gln  � ������ 
  satpos_eci.x = satpos_eci.x * 1000.0; 
  satpos_eci.y = satpos_eci.y * 1000.0; 
  satpos_eci.z = satpos_eci.z * 1000.0; 
  satpos_eci.vx = satpos_eci.vx * 1000.0; 
  satpos_eci.vy = satpos_eci.vy * 1000.0; 
  satpos_eci.vz = satpos_eci.vz * 1000.0; 
   satpos_gln.x = satpos_eci.x; 
   satpos_gln.y = satpos_eci.y; 
   satpos_gln.z = satpos_eci.z; 