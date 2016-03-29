function [fdop, tz, N_int_Chip,N_int_Navig,fi, t_chip_resid,N_int_Fdop_cells,T_navig_resid] = signal_param(rec, trans, fs)    
%������� ��������� ������������ �����, ����� �������� � ���� �������
%����:
%rec - ��������� ��������� ��
%tranc - ��������� ��������� ���
%fs - �������� ������� ��� ������� ���
%�����:
%fdop - ������������ ����� �������
%tz - ����� ��������
%fi - ���� �������

global GL_T_chip GL_T_Navig_message GL_Fdop_cell

N_total=length(rec.x);

D     = zeros(1,N_total);      %���������
S1    =  zeros(1,N_total);
S2    =  zeros(1,N_total);
c      = 299792.458;%[��/c] - �������� ����� � ��


KA     = [rec.x;rec.y;rec.z];    
NKA    = [trans.x;trans.y;trans.z];

vKA    = [rec.vx; rec.vy; rec.vz];
vNKA   = [trans.vx; trans.vy; trans.vz];

%���������� ���������� �������
X12=zeros(3,N_total);
X21=zeros(3,N_total);

for i = 1:3
    DD = KA(i,:) - NKA(i,:);
    D  = D + DD.*DD;
    X12(i,:) = DD;            %������ � ������������ �� ��� � ��
    X21(i,:) = -DD;           %������ � ������������ �� �� � ���
end;

D = sqrt(D);                %���������� ����� ���������

    summ1 = sqrt(vKA(1,:).^2 + vKA(2,:).^2 + vKA(3,:).^2);     %������ ������� �������� ��
    summ2 = sqrt(vNKA(1,:).^2 + vNKA(2,:).^2 + vNKA(3,:).^2);  %������ ������� �������� ���
    
    for i = 1:3
        S1 = S1+X12(i,:).*vNKA(i,:);  %��������� ������������ ������� ����������� � ������� �������� ���������
    end;
    arg1 = acos(S1./(D.*summ2));  %���������� ���� ��������
    v1   = cos(arg1).*summ2;     %������� ������� �� ������ ����
    
    for i = 1:3
        S2 = S2+X21(i,:).*vKA(i,:); %��������� ������������ ������� ����������� � ������� �������� �����������
    end;
    arg2 = acos(S2./(D.*summ1));  %���������� ���� ��������
    v2   = cos(arg2).*summ1;     %������� ������� �� ������ ����

fdop = fs.*(v2 + v1)./c;          %������������ ����� �������

%=============================�������� �������=============================
clear v2 v1 arg1 arg 2 S1 S2 summ1 summ2 X12 X21 KA NKA vKA vNKA

tz = D./c;

clear D
%==========================���� ���������������� �������=====================
%{
Tp = 1/fs;

fi.int   = fix(tz/Tp);          %����� ����� ��������
t_resid       = mod(tz,Tp);          %���������� ����� � ��������� 2 Pi
fi.res   = t_resid*2*180/Tp;               %�� ��, � ��������
%}    
% T_hf=1/fs; %������ ��
%==========================���� �������������� ����=====================

N_int_Navig = fix(tz/GL_T_Navig_message); %����� ����� �������� �������������� ���������
N_int_Chip   = fix( (tz-N_int_Navig*GL_T_Navig_message)/GL_T_chip);          %����� ����� ����� ������������� ���� � ������ ��� ��������� �� 1 ��!!!
T_navig_resid=mod(tz,GL_T_Navig_message);%����� �������� �� ���������� ������ �������������� ���� (<1 ��)
N_int_Fdop_cells=fix(fdop/GL_Fdop_cell);%����� ����� ����� �� 500 �� F���
t_chip_resid   = mod(tz,GL_T_chip);          %[���] - ���������� ����� ����� ������������ ������ ����� ����� 
fi   = tz.*(fs+fdop)*2*pi;   %[���] - ������ ���� �������������� ���������


