function y=S_fun(gmst,t) 
% ������ ���� �������� �������������� �� ������������ ������������ �� ��� ��������� �������� ������� 
global GL_W_rot_Earth
y=gmst + GL_W_rot_Earth.*(t - 10800);