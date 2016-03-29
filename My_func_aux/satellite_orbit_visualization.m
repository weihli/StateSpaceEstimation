function []=satellite_orbit_visualization(T1,T2,t_refresh,Satpos_xyz_Rec_mean,Satpos_xyz_gln,Visible_satellites,nsmax)

global GL_Hmin_ion GL_Ae

[x,y,z]=sphere;
h_min=GL_Hmin_ion;%�� � �-��� Radio_vision_satelate - ��� ���������� ��� �����, ������� ���������
% N_video=size(T1:t_refresh:T2,2);

j=1;
% writerObj = VideoWriter('video1.avi');%������ ������ �� ���������
% open(writerObj);%������ ������ ���������
% F( 1:N_video ) = struct('cdata',[],'colormap',[]); %���������� �����, ����� � �� ���������� ������ ��� �����
figure;

camPos(j,:)=get(gca,'CameraPosition');%��������� ������� ���������� ������
for i=T1:t_refresh:T2
    

    surf(gca,(GL_Ae+h_min)*x,(GL_Ae+h_min)*y,(GL_Ae+h_min)*z);
    set(gca,'CameraPositionMode','manual');
    set(gca,'CameraPosition',camPos(j,:));

   hold on
%    plot3(Satpos_xyz_Rec_current.x(1:i),Satpos_xyz_Rec_current.y(1:i),Satpos_xyz_Rec_current.z(1:i),'LineWidth',2,'Color','c');
%    plot3(Satpos_xyz_Rec_current.x(i),Satpos_xyz_Rec_current.y(i),Satpos_xyz_Rec_current.z(i),'LineWidth',1,'Color','r','Marker','*');
   plot3(Satpos_xyz_Rec_mean.x(1:i),Satpos_xyz_Rec_mean.y(1:i),Satpos_xyz_Rec_mean.z(1:i),'LineWidth',2,'Color','c');
   plot3(Satpos_xyz_Rec_mean.x(i),Satpos_xyz_Rec_mean.y(i),Satpos_xyz_Rec_mean.z(i),'LineWidth',1,'Color','r','Marker','*');
   
   for ns=1:nsmax
      plot3(Satpos_xyz_gln(ns).x(1:i),Satpos_xyz_gln(ns).y(1:i),Satpos_xyz_gln(ns).z(1:i),'g');
      plot3(Satpos_xyz_gln(ns).x(i),Satpos_xyz_gln(ns).y(i),Satpos_xyz_gln(ns).z(i),'LineWidth',1,'Color','r','Marker','^');
      text( Satpos_xyz_gln(ns).x(i),Satpos_xyz_gln(ns).y(i),Satpos_xyz_gln(ns).z(i),num2str(ns) );   
      
%       line([Satpos_xyz_Rec_mean.x(i) Satpos_xyz_gln(ns).x(i)],[Satpos_xyz_Rec_mean.y(i) Satpos_xyz_gln(ns).y(i)],...
%              [Satpos_xyz_Rec_mean.z(i) Satpos_xyz_gln(ns).z(i)],'LineStyle','--');  
      
      if Visible_satellites(ns,i,1)==1
%           line([Satpos_xyz_Rec_current.x(i) Satpos_xyz_gln(ns).x(i)],[Satpos_xyz_Rec_current.y(i) Satpos_xyz_gln(ns).y(i)],...
%               [Satpos_xyz_Rec_current.z(i) Satpos_xyz_gln(ns).z(i)],'LineStyle','--');
          line([Satpos_xyz_Rec_mean.x(i) Satpos_xyz_gln(ns).x(i)],[Satpos_xyz_Rec_mean.y(i) Satpos_xyz_gln(ns).y(i)],...
              [Satpos_xyz_Rec_mean.z(i) Satpos_xyz_gln(ns).z(i)],'LineStyle','--','Color','r');          
      end;
      
   end

    hold off

    j=j+1;
    
%     F(i)=getframe(gcf);
    getframe(gcf);
    camPos(j,:)=get(gca,'CameraPosition');%��������� ������� ���������� ������
      
end;

% writeVideo(writerObj,F);%���������� ���������� ������ � ���������
% close(writerObj);%��������� ���������