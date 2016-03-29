function [JD, day_year] = JD_data(timeUTC) 
%���:JD_data 
% ������� JD_data(timeUTC)  ��������� : 
%JD - ����� ���������� ���, day_year - ����� ��� ����. 
%������� ������: 
%��������� timeUTC  
%timeUTC.year - ���, 
% timeUTC.mon - �����, 
% timeUTC.day - ����. 
%�������� ������:  
%JD - ��������� ����; 
%day_year- ���� �� ������ ����. 
%���������� ���� � ������� 
  DnMon = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]; 
%���������� ������ ���������� ��� ������� ����� 
  jd0 = JD_epohi(timeUTC.year); 
%���� ����������� ���� 
nfebr = 0; 
if mod(timeUTC.year,4) == 0 
    nfebr = 1; 
end; 
%������������ ��� ���� 
   k = 0; 
   for i = 2 : timeUTC.mon 
        k = k + DnMon(i - 1); 
      if (i == 2)  
            k = k + nfebr; 
        end;   
   end; 
    day_year = k + timeUTC.day; 
%������ ������ ���������� ��� 
    JD = jd0 + day_year; 
