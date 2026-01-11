function [Eg0,a,b,c] = fitParabola(IH,mIH,mGa)
%UNTITLED4 Summary of this function goes here
%   Detailed explanation goes here
A1=(mGa(1)-mGa(2))/(mIH(1).^2-mIH(2).^2);
 A2=1/(mIH(1)+mIH(2));
 A3=(mGa(1)-mGa(3))/(mIH(1).^2-mIH(3).^2);
 A4=1./(mIH(1)+mIH(3));

 b=(A1-A3)/(A2-A4);
 a=A1-b*A2;
 c=mGa(1)-a*mIH(1).^2-b*mIH(1);
 Eg0=a*IH.^2+b*IH+c;
end

