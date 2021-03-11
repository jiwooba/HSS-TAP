%This function calculates the 5 point derivative of any parameter.

% INPUTS
% freq    - frames/sec
% inparam - any input parameter whose derivative is required. Array with
%           columns  = n-co-ords and rows = number of frames
% OUTPUT
% deriv   - 5 point derivative of inparam. Array with columns = n co-ords
%           and rows = number of frames as in inparam.
%           unit(deriv) = unit(inparam)/sec

function deriv = fivepointderiv(inparam, freq)

len = size(inparam, 1); %get # of frame

%derivative at frames 1 & 2
deriv(1,:)=(-inparam(3,:)+4*inparam(2,:)-3*inparam(1,:))*freq/2;
deriv(2,:)=deriv(1,:);

%for all the frame in between
for i=3:(len-2)
    deriv(i,:)=(-inparam(i+2,:)+8*inparam(i+1,:)-8*inparam(i-1,:)+inparam(i-2,:))*freq/12;
end

%derivative at last 2 frames
deriv(len,:)=(inparam(len-2,:)-4*inparam(len-1,:)+3*inparam(len,:))*freq/2;
deriv(len-1,:)=deriv(len,:);
%12 comes from -(2)+8(1)-8(-1)+(-2)=12

return