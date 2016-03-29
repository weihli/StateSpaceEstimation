function [K] = GDOP_new(in_struct,dT,visual)
%������� ��������� ������ ��������������� �������
%���� - ��������� out
%out.vis - ������� ���������
%out.cH  - ��������
%����� - � - �������������� ������

[nsmax] = size(in_struct,1);%���������� ���������
N_t_max=size(in_struct(1).vis,2);%����������� �� �������

vision=zeros(nsmax,N_t_max);
% cH=zeros(nsmax*3,N_t_max);

for ns = 1:nsmax
    vision(ns,:) = in_struct(ns).vis(:);
%     cH( (ns-1)*3+1:ns*3, : )     = in_struct(ns).cH;   
end

% sum_vis = zeros(1,N_t_max);     %���������� ������� ���������. ��� ������� ����������� �������
% vision = vision';               %���������������� �������


%�������� ���������� ���-�� ������� ��������� � �� ������� � �����������
%������ �������

sum_vis=sum(vision); %���������� ������� ���������. ��� ������� ����������� �������
K=zeros(1,N_t_max); %������ ������ ��������������� �������

%�������� ���������� ��������������� �������

for i=1:N_t_max
    num_vis=find( vision(:,i) );
    H=ones(length(num_vis),4);
    
    for j=1:length(num_vis)
        H(j,1:3)=-in_struct( num_vis(j) ).cH(:,i);
%         -cH( ( num_vis(j)-1 )*3+1:num_vis(j)*3 ,i);
    end
    
    K(i) = sqrt( trace( inv(H'*H) ) );
end;


%{
% for i = 1:maximum
%     for j = 1:sum_vis(i)
%         for k = 1:4 
%             
%             switch k
%                 case 1
%                     H(j,k) = -cH(num_vis(i,j),i).cos_a;
%                 case 2
%                     H(j,k) = -cH(num_vis(i,j),i).cos_b;
%                 case 3
%                     H(j,k) = -cH(num_vis(i,j),i).cos_y;
%                 case 4
%                     H(j,k) = 1;
%             end
%         end
%     end
%     
%     K(i) = sqrt(trace((H'*H)^-1));
%     H=[];
% end
%}

if visual
  figure; 
  subplot(2,1,1), plot((1:N_t_max).*dT/60,sum_vis);  
  xlabel('����� �������������, t [���]');    
  ylabel('���-�� ������� ���������');
  subplot(2,1,2), plot((1:N_t_max).*dT/60, (K) );
  xlabel('����� �������������, t [���]');    
  ylabel('GDOP');
end;
