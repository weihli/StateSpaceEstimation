function [Satpos_xyz_Rec_current]=SC_current_trajectory_calc(T_Ttotal_eval,time_refresh_data,T_dT_sc,T_Tstart,T_Tend,...
    Sun,Moon,y0_sc_current)

N_15min_inter_max=ceil(T_Ttotal_eval/time_refresh_data);%������� ��� �� 15 ��� ������������ �� ��� ������� ��������������

N_max=T_Ttotal_eval/T_dT_sc+1;% ������ ����� ����� ���������� �����
Ti_current=T_Tstart;

Coord_Inert_sc_current=zeros(3,N_max);
Vel_Inert_sc_current=zeros(3,N_max);

%���� �� �������- ��������� �� 15 ���
for j=1:N_15min_inter_max
    
    K=time_refresh_data/T_dT_sc+1;%������� ����� ���������� ���������� �� ���� ��������
   
    
    if (Ti_current+time_refresh_data)<=T_Tend
        T=Ti_current:T_dT_sc:(Ti_current+time_refresh_data);%������ �������, ��� �������� ����� ������������ ������� ������� ��.
        k=K;
        start=(j-1)*K+2-j;%��������� ������� ������� �� ������� 1=T_dT_sc
        stop=(j-1)*K+1+k-j;%�������� �������� ��������� ������� �� �������
    elseif Ti_current==T_Tend
        continue;
    else
        T=Ti_current:T_dT_sc:T_Tend;%������ �������, ��� �������� ����� ������������ ������� ������� ��.
        k=size(T,2);
        start=(j-1)*K+2-j;
        stop=start+k-1;
    end
     
    [~,Y]=ode113( @(t,y) d_State_Space_dT(t,y,Sun(:,j) ,Moon(:,j) ), T,y0_sc_current );%��������������� ������ ������� �� ��� ������� ������ (� �������)
 %ode45
%�������� ������ �� ������� ��������� � ��������� � ��������� 
    Coord_Inert_sc_current( 1:3, start:stop  )=Y(1:end,1:3)';
    Vel_Inert_sc_current( 1:3, start:stop  )=Y(1:end,4:6)';    
%----------
    y0_sc_current=[Y(end,1:3)'; Y(end,4:6)'];% ����� ��������� ������� ��� ��  
%----------
    
    Ti_current=Ti_current+time_refresh_data;%����������� ����� �� 15 ���
end;


%}


%������� ���������� �������� ��
Satpos_xyz_Rec_current=struct('x',zeros(1,N_max),'y',zeros(1,N_max),'z',zeros(1,N_max),'vx',zeros(1,N_max),'vy',zeros(1,N_max),'vz',zeros(1,N_max));
Satpos_xyz_Rec_current.x=Coord_Inert_sc_current(1,:);
Satpos_xyz_Rec_current.y=Coord_Inert_sc_current(2,:);
Satpos_xyz_Rec_current.z=Coord_Inert_sc_current(3,:);

Satpos_xyz_Rec_current.vx=Vel_Inert_sc_current(1,:);
Satpos_xyz_Rec_current.vy=Vel_Inert_sc_current(2,:);
Satpos_xyz_Rec_current.vz=Vel_Inert_sc_current(3,:);