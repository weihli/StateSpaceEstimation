function [days] = calc_days(DnMon , date , days_year);
%��� ������� ���������� �������� ������ �����.
%����:
%DnMon     - ������ � ���-��� ���� � �������
%date      - ����� ���
%days_year - ���-�� ���� ��������� � ���������� ����������� ����
%�����:
%days      - ����� ������� ����� �� ���������� ����������� ����

days = 0;
%days_year = 0;

for i=1:(date.mon-1)
    
    days = days+DnMon(i);

end

days =days_year + days + date.day;