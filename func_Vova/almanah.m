function [alm_gln]=almanah(PathToTheFileAlmanach)
%������� almanah ������������� ��� ��������� ������ .agl - ���������
%��������� �������
%���� - ���� � �����
%����� - ��������� alm_gln

fad = fopen(PathToTheFileAlmanach, 'r');    %Almanach
Data2 = textscan(fad, '%f');                %������ ���� ��� ����� ���� float
fclose(fad);

alm_gln.date.day = zeros(24,1);
alm_gln.date.mon = zeros(24,1);
alm_gln.date.year= zeros(24,1);
alm_gln.Lam      = zeros(24,1);
alm_gln.dI       = zeros(24,1);
alm_gln.omegan   = zeros(24,1);
alm_gln.E        = zeros(24,1);
alm_gln.dT       = zeros(24,1);
alm_gln.dTT      = zeros(24,1);
alm_gln.Tutc     = zeros(24,1);
alm_gln.Nn       = zeros(24,1);
alm_gln.Cn       = zeros(24,1);
alm_gln.tc       = zeros(24,1);
alm_gln.Tglutc   = zeros(24,1);
alm_gln.Tgpgl    = zeros(24,1);
alm_gln.Tka      = zeros(24,1);

alm_gln.date.day = Data2{1}(8);    %����
alm_gln.date.mon = Data2{1}(9);    %�����
alm_gln.date.year= Data2{1}(10);   %���

for n=1:24
    
    alm_gln.Lam(n)    = Data2{1}(15+(n-1)*20);     %������� ����
    alm_gln.dI(n)     = Data2{1}(16+(n-1)*20);     %��������� ����������
    alm_gln.omegan(n) = Data2{1}(17+(n-1)*20);     %�������� �������
    alm_gln.E(n)      = Data2{1}(18+(n-1)*20);     %��������������
    alm_gln.dT(n)     = Data2{1}(19+(n-1)*20);     %�������� � �������������� �������, �
    alm_gln.dTT(n)    = Data2{1}(20+(n-1)*20);     %�������� � �������������� �������, �/�����
    alm_gln.Tutc(n)   = Data2{1}(4+(n-1)*20);      %����� ��������� ��������� �� ����� �����, � UTC
    alm_gln.Nn(n)     = Data2{1}(6+(n-1)*20);      %����� ���������� ������
    alm_gln.Cn(n)     = Data2{1}(7+(n-1)*20);      %������� �������� ���
    alm_gln.tc(n)     = Data2{1}(11+(n-1)*20);     %����� ����������� ������� ����, �
    alm_gln.Tglutc(n) = Data2{1}(12+(n-1)*20);     %�������� �������-USC, �
    alm_gln.Tgpgl(n)  = Data2{1}(13+(n-1)*20);     %�������� GPS-�������, �
    alm_gln.Tka(n)    = Data2{1}(14+(n-1)*20);     %�������� ������� �� ������� ������������ ���������� �������, �
    alm_gln.Na(n)     = calc_Na(alm_gln.date);     %���� �� � 4� ������ ���������
    alm_gln.n(n)     = n;                          %����� ��������
    
end