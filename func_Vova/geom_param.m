function [H,a1,a2,D,cH] = geom_param(rec, trans)
%������� ��������� ������ ������� ��������� �� ������ ������ �������.
%������� ������:
%rec   - ���������� ��
%trans - ���������� ���
%�������� ������:
%resut - ������ ������ � ����������� ������� ��������� (0 - �������, 1 - �����)
%H     - ������ �������������� ���������� �� ������ ����� �� ������ �����������
%a1    - ���� ����� �������� ����������� � ������� ������������� �� ����� ��� ��
%�2    - ���� ����� �������� ����������� � ������� ������������� �� ����� ��� ���
%D     - ������ ������� �����������

N_total=length(rec.x);

% result =ones(1,N_total); %������� ���������
D = zeros(1,N_total);      %���������
X12=zeros(3,N_total);
X21=zeros(3,N_total);

SP1    = zeros(1,N_total);
SP2    = zeros(1,N_total);
% c      = 299792.458;

KA    = [rec.x;rec.y;rec.z];    
NKA   = [trans.x;trans.y;trans.z];

% vKA   = [rec.vx, rec.vy, rec.vz];
% vNKA  = [trans.vx, trans.vy, trans.vz];

%���������� ���������� �������

for i = 1:3
    DD = KA(i,:) - NKA(i,:);
    D  = D + DD.*DD;
    X12(i,:) = DD;            %������ � ������������ �� ��� � ��
    X21(i,:) = -DD;           %������ � ������������ �� �� � ���
end;

D = sqrt(D);                %���������� ����� ���������

R1 = sqrt(KA(1,:).^2+KA(2,:).^2+KA(3,:).^2);       %���������� �� 0 �� ��
R2 = sqrt(NKA(1,:).^2+NKA(2,:).^2+NKA(3,:).^2);    %���������� �� 0 �� ��� %???????


    
    for i = 1:3
        SP1 = SP1+X12(i,:).*KA(i,:);   %��������� ������������ ������� ����������� � ������� 0 - ��������
    end
    a1 = acos(SP1./(D.*R1));%���� �/� ������ ����������� � ����������� �� �� �� ������ �����
    
    for i = 1:3
        SP2 = SP2+X21(i,:).*NKA(i,:);  %��������� ������������ ������� ����������� � ������� 0 - ����������
    end
    a2 = acos(SP2./(D.*R2));%���� �/� ������ ����������� � ����������� �� ��� �� ������ �����
    
    clear SP2 SP1 DD X12 X21 i R2
%-----------
%?????????????????????????????????????????????????
    H=zeros(1,N_total);
    
    pos_num_a=find(a1>pi/2);
    if not( isempty(pos_num_a) )
       H(pos_num_a) = R1(pos_num_a);       
    end;
      
    pos_num_a=find( a1<pi/2); 
    if not( isempty(pos_num_a) )
        H(pos_num_a) = sin( a1(pos_num_a) ).*R1(pos_num_a);
    end;
    
    %{
    pos_num_a=find((a1+a2)>pi/2);
    if not( isempty(pos_num_a) )
       pos_num_R=find( R1(pos_num_a)>=R2(pos_num_a) );
       
       if not( isempty(pos_num_R) )
           pos_num_R=pos_num_a(pos_num_R);
           H(pos_num_R) = R2(pos_num_R);
       end; 
       pos_num_R=[];
       
       pos_num_R=find( R1(pos_num_a)<R2(pos_num_a) ); 
       
       if not( isempty(pos_num_R) )
           pos_num_R=pos_num_a(pos_num_R);
           H(pos_num_R) = R1(pos_num_R);
       end; 
       
    end;
    
    
    pos_num_a=[];
    pos_num_a=find((a1+a2)<pi/2);
    
    if not( isempty(pos_num_a) )
        H(pos_num_a) = sin( a1(pos_num_a) ).*R1(pos_num_a);
    end;
   %}
    
    clear pos_num_a N_total R1
%-----------------
    
 %{   
    if ((a1+a2)>pi/2)  %90�������� � �������� %???????????1.570796326794897
        
      if (R1>R2)
          H = R2;
      else
          H = R1;
      end;
      
    else
        H = sin(a1)*R1;
    end;
%}    


%������ ��������� ��� ���������� ��������������� �������
        
cH(1,:) = ( NKA(1,:) - KA(1,:) )./D;
cH(2,:) = ( NKA(2,:) - KA(2,:) )./D;
cH(3,:) = ( NKA(3,:) - KA(3,:) )./D;

%{
        cH.cos_a = ( NKA(1,:) - KA(1,:) )./D;
        cH.cos_b = ( NKA(2,:) - KA(2,:) )./D;
        cH.cos_y = ( NKA(3,:) - KA(3,:) )./D;
%}   
