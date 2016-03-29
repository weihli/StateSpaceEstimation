function [oxyz] = convert_coord(geogr_coord);
%������� �������������� �������������� ��������� � ���������� ox0y0z0
%������� ������:
%��������� geogr_coord
%geogr_coord.lat - ������  (�������)
%geogr_coord.lon - ������� (�������)
%geogr_coord.h   - ������
%
%�������� ������:
%��������� oxyz
%oxyz.x 
%oxyz.y
%oxyz.z

eEarth = 0.01671123;        %������������� �����
a = 6378245.0;              %������� ������� ����� (�����)

e_2 = eEarth^2;
sin_lat2 = sin(geogr_coord.lat)*sin(geogr_coord.lat);
N = a/sqrt(1-e_2*sin_lat2); %������ �������� ������� ���������

oxyz.x = (N+geogr_coord.h)*cos(geogr_coord.lat)*cos(geogr_coord.lon);
oxyz.y = (N+geogr_coord.h)*cos(geogr_coord.lat)*sin(geogr_coord.lon);
oxyz.z = ((1-e_2)*N+geogr_coord.h)*sin(geogr_coord.lat);