%����������� ���������� ��� � �������� ��������� ��
function [Satpos_xyz_Rec_mean,Satpos_xyz_gln,Sun,Moon] = SC_and_NSC_trajectory_calc(T_Ttotal_eval,...
    T_dT_sc,...
    time_refresh_data,...
    JD,...
    T_Tstart,...
    T_Tend,...
    alm_testSetilate,...
    date_start_eval_mass,...
    Nt,...
    alm_gln)

nsmax=24;
month = [31,28,31,30,31,30,31,31,30,31,30,31];%���������� ���� � ������ ������


N_max=T_Ttotal_eval/T_dT_sc+1;% ������ ����� ����� ���������� �����

Coord_Inert_sc_true=zeros(3,N_max);
Vel_Inert_sc_true=zeros(3,N_max);
[Coord_Inert_sc_true(:,1),Vel_Inert_sc_true(:,1)]= alm_calc_Rec(T_Tstart, alm_testSetilate);

%----------
y0_sc_true=[Coord_Inert_sc_true(:,1); Vel_Inert_sc_true(:,1); [1; 0; 0; 0]];% ����� ��������� ������� ��� ��  
%----------

Coord_Inert_nsc_gln = zeros(3*nsmax,N_max);
Vel_Inert_nsc_gln = zeros(3*nsmax,N_max);

N_15min_inter_max=ceil(T_Ttotal_eval/time_refresh_data);%������� ��� �� 15 ��� ������������ �� ��� ������� ��������������
Ti_current=T_Tstart;

Sun=zeros(3,N_15min_inter_max);
Moon=zeros(3,N_15min_inter_max);

date_current_time_mass=date_start_eval_mass;
flag=0;%������� ����,��� ����� ��� �� ��������



%----------------------------------------------------------------------
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
   
    T_till_current_epoch=T_current_fun(JD,Ti_current);% - ����� �� ����� 2000 �., 1 ������, 12 ����� (UTC) �� ������� ������� �������� ������� (���) Te � ��������� ��������� �� 36525 ����������� �����
%     [Sun(:,j), Moon(:,j)]=Sun_and_Moon_influence_func(T_till_current_epoch,y0_sc_true(1:3)); %������ c����������� ��������� ���� � ������
       
%     tic
        [T,Y]=ode113( @(t,y) d_State_Space_dT(t,y,Sun(:,j),Moon(:,j) ), T,y0_sc_true );%��������������� ������ ������� �� ��� �������� ������
%     toc
    tic
    [T,Y]=ode113( @(t,y) equationOfMotion(t, y, [1; 1; 1], [.5; .5; .5], T_till_current_epoch ), T, y0_sc_true ); %��������������� ������ ������� �� ��� �������� ������
    toc
 %ode45
%�������� ������ �� ������� ��������� � ��������� � ��������� 
    Coord_Inert_sc_true( 1:3, start:stop  )=Y(1:end,1:3)';
    Vel_Inert_sc_true( 1:3, start:stop  )=Y(1:end,4:6)';
    Quaternion_Inert_sc_true( 1:4, start:stop  )=Y(1:end,7:10)';
  
%----------
    y0_sc_true=[Y(end,1:3)'; Y(end,4:6)'];% ����� ��������� ������� ��� ��  
%----------
    

S=zeros(length(T),1);
for i=1:length(T)
    hour=fix(T(i)/3600);%������� �� ������� ������� T ���������� �����
    minute=fix( mod(T(i),3600)/60 );%������� �� ������� ������� T ���������� �����
    sec=T(i)-hour*3600-minute*60;%������� �� ������� ������� T ���������� ������
    
    if ( hour>=24 && flag==0 )
        flag=1;
        
        %�������� �� ��, ��� ��� ���������� 24� ����� ���� ��������� ���������
        if date_current_time_mass(2)==2 %�������� �� ��, ��� ����� - �������
            if ( ( (date_current_time_mass(3)+1)>month( 2 ) ) && ( mod(date_current_time_mass(1),4)~=0 ) )
                date_current_time_mass(2)=date_current_time_mass(2)+1;
                date_current_time_mass(3)=1;
            else
                date_current_time_mass(3)=date_current_time_mass(3)+1; %���� ��� ����������
            end;            
        else            
            if (date_current_time_mass(3)+1)>month( date_current_time_mass(2) )
                date_current_time_mass(2)=date_current_time_mass(2)+1;
                date_current_time_mass(3)=1;
            else
                date_current_time_mass(3)=date_current_time_mass(3)+1;
            end;            
        end;
        
    end;
    
    if  ( hour>=24 && flag==1 )
        hour=hour-24;         
    end;
    
    date_current_time_mass(4:6)=[hour minute sec];
    
    S(i)=Sideral_time_calc(date_current_time_mass);
end;

%������ ��������� ��� ��� ��������� ��������� �������
    for ns=1:nsmax

        %��������� ������� ������� �����
       [ Coord_Inert_nsc_gln( (ns-1)*3+1:ns*3,start:stop),Vel_Inert_nsc_gln( (ns-1)*3+1:ns*3,start:stop ) ] = gln_alm_calc1(ns, Nt, T', alm_gln);%time_s0

       [Coord_Inert_nsc_gln( (ns-1)*3+1:ns*3,start:stop ),Vel_Inert_nsc_gln( (ns-1)*3+1:ns*3,start:stop )] = CS_Transform_PZ2Inert( Coord_Inert_nsc_gln((ns-1)*3+1:ns*3,start:stop),Vel_Inert_nsc_gln((ns-1)*3+1:ns*3,start:stop),S(:) ); % ������� �� ����������� �� � ������������  %S(i-start+1)
        
    end

    Ti_current=Ti_current+time_refresh_data;%����������� ����� �� 15 ���
end;

%�������� ���������� �������� ��
Satpos_xyz_Rec_mean = struct('x',zeros(1,N_max),'y',zeros(1,N_max),'z',zeros(1,N_max),'vx',zeros(1,N_max),'vy',zeros(1,N_max),'vz',zeros(1,N_max), ...
    'q',zeros(1,N_max), 'qi',zeros(1,N_max), 'qj',zeros(1,N_max), 'qk',zeros(1,N_max));
Satpos_xyz_Rec_mean.x = Coord_Inert_sc_true(1,:);
Satpos_xyz_Rec_mean.y = Coord_Inert_sc_true(2,:);
Satpos_xyz_Rec_mean.z = Coord_Inert_sc_true(3,:);

Satpos_xyz_Rec_mean.vx = Vel_Inert_sc_true(1,:);
Satpos_xyz_Rec_mean.vy = Vel_Inert_sc_true(2,:);
Satpos_xyz_Rec_mean.vz = Vel_Inert_sc_true(3,:);

Satpos_xyz_Rec_mean.q = Quaternion_Inert_sc_true(1,:);
Satpos_xyz_Rec_mean.qi = Quaternion_Inert_sc_true(2,:);
Satpos_xyz_Rec_mean.qj = Quaternion_Inert_sc_true(3,:);
Satpos_xyz_Rec_mean.qk = Quaternion_Inert_sc_true(4,:);

Satpos_xyz_gln(1:nsmax,1)=struct('x',zeros(1,N_max),'y',zeros(1,N_max),'z',zeros(1,N_max),'vx',zeros(1,N_max),'vy',zeros(1,N_max),'vz',zeros(1,N_max));
 for ns=1:nsmax
     Satpos_xyz_gln(ns,1).x=Coord_Inert_nsc_gln( (ns-1)*3+1,:);
     Satpos_xyz_gln(ns,1).y=Coord_Inert_nsc_gln( (ns-1)*3+2,:);
     Satpos_xyz_gln(ns,1).z=Coord_Inert_nsc_gln( (ns-1)*3+3,:);
     
     Satpos_xyz_gln(ns,1).vx=Vel_Inert_nsc_gln( (ns-1)*3+1,:);
     Satpos_xyz_gln(ns,1).vy=Vel_Inert_nsc_gln( (ns-1)*3+2,:);
     Satpos_xyz_gln(ns,1).vz=Vel_Inert_nsc_gln( (ns-1)*3+3,:);
     
 end;
