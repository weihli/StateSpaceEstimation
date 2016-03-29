function [G] = G_angle(DN, angle)
%������� G_angle
%��������� �������� ������������ �������� ������� � ����������� angle
%������� ������: 
%������ �� ������� ��
%���� ����� �������� ����������� �� ����� � ����������/������������
%�������� ������:
%�� ������� �� � ���� angle.
G=zeros( 1,size(angle,2) );
for i = 1:size(DN,1)-1 
    A1=find(angle>DN(i));
    if not( isempty( A1 ) )
        A2=find(angle(A1)<DN(i+1));
       
        if not( isempty( A2 ) )
            A2=A1(A2);
            Koef_a     = DN(i+1) - DN(i);      %������� �������� ���� � ��������
            delta_a    = angle(A2) - DN(i);                %������� ����� ������� ����� � �2                                   
            Koef_P     = DN(i+1,2) - DN(i,2);       %����������� ��������
            Koef       = Koef_P/Koef_a;               %������������� ����������� ��������/����
            G(A2)          = delta_a*Koef+DN(i,2);        %�� ������� ��� ���� �2            
        end;
        delta_a=[];
       
    end;    
    A1=[];
    A2=[];
end;




