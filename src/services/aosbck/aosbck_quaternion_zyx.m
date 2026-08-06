function q = aosbck_quaternion_zyx(azimut_deg, inclinacion_deg, roll_deg)
% AOSBCK_QUATERNION_ZYX Quaternion WXYZ desde yaw-pitch-roll.
  if nargin<3, roll_deg=0; endif
  y=azimut_deg*pi/180; p=inclinacion_deg*pi/180; r=roll_deg*pi/180;
  cy=cos(y/2); sy=sin(y/2); cp=cos(p/2); sp=sin(p/2); cr=cos(r/2); sr=sin(r/2);
  q=[cr*cp*cy+sr*sp*sy, sr*cp*cy-cr*sp*sy, cr*sp*cy+sr*cp*sy, cr*cp*sy-sr*sp*cy];
  q=q./max(norm(q),eps);
endfunction
